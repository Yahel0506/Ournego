-- OUR-112 - Tests for review requests, the review result and the S0 rule.
-- Run after 2026-11-05_business_review_status.sql and
-- 2026-11-06_business_review_requests.sql. Everything is rolled back; a failing
-- check raises an exception that starts with FAIL.

begin;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000112a01', 'authenticated', 'authenticated', 'owner112@test.invalid'),
  ('00000000-0000-0000-0000-000000112a03', 'authenticated', 'authenticated', 'reviewer112@test.invalid');
insert into public.reviewers (user_id) values ('00000000-0000-0000-0000-000000112a03');

insert into public.businesses (business_id, owner_id, name, phone_number, status, rejection_reason) values
  ('00000000-0000-0000-0000-0000000112b1', '00000000-0000-0000-0000-000000112a01', 'approved',  '111', 'approved',  null),
  ('00000000-0000-0000-0000-0000000112b2', '00000000-0000-0000-0000-000000112a01', 'pending',   '111', 'pending',   null),
  ('00000000-0000-0000-0000-0000000112b3', '00000000-0000-0000-0000-000000112a01', 'rejected',  '111', 'rejected',  'Falta la direccion'),
  ('00000000-0000-0000-0000-0000000112b4', '00000000-0000-0000-0000-000000112a01', 'withdrawn', '111', 'withdrawn', null);

-- Owner ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000112a01","role":"authenticated"}', true);
do $$ declare r record; begin
  -- new listing records when it was sent and has no decision
  insert into public.businesses (business_id, owner_id, name)
    values ('00000000-0000-0000-0000-0000000112b5', '00000000-0000-0000-0000-000000112a01', 'new');
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000112b5';
  if r.status <> 'pending' or r.submitted_at is null or r.reviewed_at is not null then
    raise exception 'FAIL: new listing is not a clean pending request';
  end if;
  -- the owner cannot backdate the submission
  insert into public.businesses (business_id, owner_id, name, submitted_at)
    values ('00000000-0000-0000-0000-0000000112b6', '00000000-0000-0000-0000-000000112a01',
            'backdated', now() - interval '30 days');
  if (select submitted_at from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000112b6') < now() - interval '1 minute' then
    raise exception 'FAIL: owner backdated submitted_at';
  end if;
  -- cannot create a listing that already carries a decision
  begin
    insert into public.businesses (owner_id, name, rejection_reason)
      values ('00000000-0000-0000-0000-000000112a01', 'x', 'forged');
    raise exception 'FAIL: owner inserted a rejection reason';
  exception when insufficient_privilege then null; end;

  -- rejected: sees the reason, edits keep it rejected, can resubmit
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000112b3';
  if r.rejection_reason is distinct from 'Falta la direccion' then
    raise exception 'FAIL: owner cannot read the rejection reason';
  end if;
  update public.businesses set address = 'Calle 1'
    where business_id = '00000000-0000-0000-0000-0000000112b3';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000112b3';
  if r.status <> 'rejected' or r.rejection_reason is null then
    raise exception 'FAIL: editing a rejected listing changed its status or reason';
  end if;
  update public.businesses set status = 'pending', rejection_reason = 'forged'
    where business_id = '00000000-0000-0000-0000-0000000112b3';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000112b3';
  if r.status <> 'pending' or r.rejection_reason is not null or r.submitted_at is null then
    raise exception 'FAIL: resubmit did not produce a clean pending request';
  end if;

  -- withdrawn can be requested again
  update public.businesses set status = 'pending'
    where business_id = '00000000-0000-0000-0000-0000000112b4';
  if (select status from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000112b4') <> 'pending' then
    raise exception 'FAIL: owner could not re-request a withdrawn listing';
  end if;

  -- cannot decide own listing or write decision fields
  begin
    update public.businesses set status = 'approved'
      where business_id = '00000000-0000-0000-0000-0000000112b2';
    raise exception 'FAIL: owner approved own listing';
  exception when insufficient_privilege then null; end;
  begin
    update public.businesses set status = 'rejected'
      where business_id = '00000000-0000-0000-0000-0000000112b2';
    raise exception 'FAIL: owner rejected own listing';
  exception when insufficient_privilege then null; end;
  update public.businesses set reviewed_at = now(), rejection_reason = 'forged'
    where business_id = '00000000-0000-0000-0000-0000000112b2';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000112b2';
  if r.reviewed_at is not null or r.rejection_reason is not null then
    raise exception 'FAIL: owner wrote decision fields';
  end if;

  -- S0: public data of an approved listing goes back to review
  update public.businesses set name = 'approved edited'
    where business_id = '00000000-0000-0000-0000-0000000112b1';
  if (select status from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000112b1') <> 'pending' then
    raise exception 'FAIL: editing public data did not return the listing to review';
  end if;
end $$;
reset role;

set local role anon;
do $$ begin
  if exists (select 1 from public.businesses
             where business_id = '00000000-0000-0000-0000-0000000112b1') then
    raise exception 'FAIL: edited listing is still public while in review';
  end if;
end $$;
reset role;

-- Reviewer decides; approved listings stay approved on non-public edits -----------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000112a03","role":"authenticated"}', true);
do $$ declare r record; begin
  update public.businesses set status = 'rejected', rejection_reason = 'Foto borrosa'
    where business_id = '00000000-0000-0000-0000-0000000112b1';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000112b1';
  if r.status <> 'rejected' or r.rejection_reason <> 'Foto borrosa' or r.reviewed_at is null then
    raise exception 'FAIL: reviewer rejection not recorded';
  end if;
  update public.businesses set status = 'approved'
    where business_id = '00000000-0000-0000-0000-0000000112b1';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000112b1';
  if r.status <> 'approved' or r.rejection_reason is not null then
    raise exception 'FAIL: approval kept the old rejection reason';
  end if;
  -- reviewer edits do not bounce the listing back to review
  update public.businesses set name = 'moderated'
    where business_id = '00000000-0000-0000-0000-0000000112b1';
  if (select status from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000112b1') <> 'approved' then
    raise exception 'FAIL: reviewer edit returned the listing to review';
  end if;
end $$;
reset role;

-- Owner: operational (non-public) edits keep an approved listing approved
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000112a01","role":"authenticated"}', true);
do $$ begin
  update public.businesses set is_active = true
    where business_id = '00000000-0000-0000-0000-0000000112b1';
  if (select status from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000112b1') <> 'approved' then
    raise exception 'FAIL: a non-public edit returned the listing to review';
  end if;
  -- phone is published without review
  update public.businesses set phone_number = '999'
    where business_id = '00000000-0000-0000-0000-0000000112b1';
  if (select status from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000112b1') <> 'approved' then
    raise exception 'FAIL: a phone edit returned the listing to review';
  end if;
end $$;
reset role;

rollback;
