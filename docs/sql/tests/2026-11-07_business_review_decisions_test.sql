-- OUR-113 - Tests for moderation rules and the review log.
-- Run after 2026-11-05_business_review_status.sql,
-- 2026-11-06_business_review_requests.sql and
-- 2026-11-07_business_review_decisions.sql. Everything is rolled back; a
-- failing check raises an exception that starts with FAIL.

begin;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000113a01', 'authenticated', 'authenticated', 'owner113@test.invalid'),
  ('00000000-0000-0000-0000-000000113a02', 'authenticated', 'authenticated', 'other113@test.invalid'),
  ('00000000-0000-0000-0000-000000113a03', 'authenticated', 'authenticated', 'reviewer113@test.invalid');
insert into public.reviewers (user_id) values ('00000000-0000-0000-0000-000000113a03');

insert into public.businesses (business_id, owner_id, name, status) values
  ('00000000-0000-0000-0000-0000000113b1', '00000000-0000-0000-0000-000000113a01', 'pending',  'pending'),
  ('00000000-0000-0000-0000-0000000113b2', '00000000-0000-0000-0000-000000113a01', 'approved', 'approved'),
  ('00000000-0000-0000-0000-0000000113b3', '00000000-0000-0000-0000-000000113a01', 'pending2', 'pending'),
  -- owned by the reviewer: they cannot decide it
  ('00000000-0000-0000-0000-0000000113b4', '00000000-0000-0000-0000-000000113a03', 'mine',     'pending');

-- Non-reviewer accounts cannot resolve requests ---------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000113a02","role":"authenticated"}', true);
do $$ declare n int; begin
  -- another signed-in account: cannot approve, reject or withdraw anything
  begin
    update public.businesses set status = 'approved'
      where business_id = '00000000-0000-0000-0000-0000000113b1';
    get diagnostics n = row_count;
    if n > 0 then raise exception 'FAIL: other account updated a listing'; end if;
  exception when insufficient_privilege then null; end;
  if (select status from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000113b1') is not null then
    raise exception 'FAIL: other account can read a pending listing';
  end if;
  -- cannot read the log
  if exists (select 1 from public.business_review_log) then
    raise exception 'FAIL: other account reads the review log';
  end if;
  -- cannot write the log
  begin
    insert into public.business_review_log (business_id, actor_role, to_status)
      values ('00000000-0000-0000-0000-0000000113b1', 'reviewer', 'approved');
    raise exception 'FAIL: other account wrote the review log';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

set local role anon;
do $$ begin
  begin
    perform 1 from public.business_review_log;
    raise exception 'FAIL: anon reads the review log';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- Owner cannot decide nor read others' log ---------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000113a01","role":"authenticated"}', true);
do $$ begin
  begin
    update public.businesses set status = 'approved'
      where business_id = '00000000-0000-0000-0000-0000000113b1';
    raise exception 'FAIL: owner approved own listing';
  exception when insufficient_privilege then null; end;
  begin
    delete from public.business_review_log;
    raise exception 'FAIL: owner deleted log rows';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- Reviewer ---------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000113a03","role":"authenticated"}', true);
do $$ declare r record; l record; begin
  -- sees the queue
  if (select count(*) from public.businesses where status = 'pending') < 3 then
    raise exception 'FAIL: reviewer does not see pending listings';
  end if;

  -- approve
  update public.businesses set status = 'approved'
    where business_id = '00000000-0000-0000-0000-0000000113b1';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000113b1';
  if r.status <> 'approved' or r.reviewed_at is null or r.rejection_reason is not null then
    raise exception 'FAIL: approval not recorded';
  end if;
  select * into l from public.business_review_log
    where business_id = '00000000-0000-0000-0000-0000000113b1'
    order by id desc limit 1;
  if l.to_status <> 'approved' or l.from_status <> 'pending'
     or l.actor_id <> '00000000-0000-0000-0000-000000113a03'
     or l.actor_role <> 'reviewer' or l.created_at is null then
    raise exception 'FAIL: approval not logged with reviewer and date';
  end if;

  -- reject needs a reason (null, blank)
  begin
    update public.businesses set status = 'rejected'
      where business_id = '00000000-0000-0000-0000-0000000113b3';
    raise exception 'FAIL: rejected without a reason';
  exception when check_violation then null; end;
  begin
    update public.businesses set status = 'rejected', rejection_reason = '   '
      where business_id = '00000000-0000-0000-0000-0000000113b3';
    raise exception 'FAIL: rejected with a blank reason';
  exception when check_violation then null; end;
  -- reject with reason (trimmed)
  update public.businesses set status = 'rejected', rejection_reason = '  Falta la direccion  '
    where business_id = '00000000-0000-0000-0000-0000000113b3';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000113b3';
  if r.status <> 'rejected' or r.rejection_reason <> 'Falta la direccion' then
    raise exception 'FAIL: rejection reason not stored trimmed';
  end if;
  select * into l from public.business_review_log
    where business_id = '00000000-0000-0000-0000-0000000113b3'
    order by id desc limit 1;
  if l.to_status <> 'rejected' or l.reason <> 'Falta la direccion' then
    raise exception 'FAIL: rejection not logged with its reason';
  end if;

  -- withdraw needs a reason, and the reason reaches the row
  begin
    update public.businesses set status = 'withdrawn'
      where business_id = '00000000-0000-0000-0000-0000000113b2';
    raise exception 'FAIL: withdrawn without a reason';
  exception when check_violation then null; end;
  update public.businesses set status = 'withdrawn', rejection_reason = 'Ya no existe'
    where business_id = '00000000-0000-0000-0000-0000000113b2';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000113b2';
  if r.status <> 'withdrawn' or r.rejection_reason <> 'Ya no existe' then
    raise exception 'FAIL: withdrawal reason not stored';
  end if;

  -- cannot decide own listing
  begin
    update public.businesses set status = 'approved'
      where business_id = '00000000-0000-0000-0000-0000000113b4';
    raise exception 'FAIL: reviewer approved own listing';
  exception when insufficient_privilege then null; end;
  begin
    update public.businesses set status = 'rejected', rejection_reason = 'x'
      where business_id = '00000000-0000-0000-0000-0000000113b4';
    raise exception 'FAIL: reviewer rejected own listing';
  exception when insufficient_privilege then null; end;

  -- reads the whole log
  if (select count(*) from public.business_review_log) < 3 then
    raise exception 'FAIL: reviewer does not read the log';
  end if;
  -- the log is append-only for reviewers too
  begin
    update public.business_review_log set reason = 'edited';
    raise exception 'FAIL: reviewer edited the log';
  exception when insufficient_privilege then null; end;
end $$;
reset role;

-- Public: approved is visible, withdrawn/rejected are not ------------------------
set local role anon;
do $$ begin
  if not exists (select 1 from public.businesses
                 where business_id = '00000000-0000-0000-0000-0000000113b1') then
    raise exception 'FAIL: approved listing is not public';
  end if;
  if exists (select 1 from public.businesses
             where business_id in ('00000000-0000-0000-0000-0000000113b2',
                                   '00000000-0000-0000-0000-0000000113b3')) then
    raise exception 'FAIL: withdrawn or rejected listing is public';
  end if;
end $$;
reset role;

-- Owner sees result, reason and history ------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000113a01","role":"authenticated"}', true);
do $$ declare r record; begin
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000113b2';
  if r.status <> 'withdrawn' or r.rejection_reason <> 'Ya no existe' or r.reviewed_at is null then
    raise exception 'FAIL: owner cannot see the withdrawal and its reason';
  end if;
  if (select count(*) from public.business_review_log
      where business_id in ('00000000-0000-0000-0000-0000000113b1',
                            '00000000-0000-0000-0000-0000000113b2',
                            '00000000-0000-0000-0000-0000000113b3')) < 3 then
    raise exception 'FAIL: owner does not see the history of own listings';
  end if;
  if exists (select 1 from public.business_review_log
             where business_id = '00000000-0000-0000-0000-0000000113b4') then
    raise exception 'FAIL: owner sees the log of another listing';
  end if;

  -- resubmitting after a rejection clears the reason and is logged as owner
  update public.businesses set status = 'pending'
    where business_id = '00000000-0000-0000-0000-0000000113b3';
  select * into r from public.businesses where business_id = '00000000-0000-0000-0000-0000000113b3';
  if r.status <> 'pending' or r.rejection_reason is not null then
    raise exception 'FAIL: resubmit kept the reason';
  end if;
  if (select actor_role from public.business_review_log
      where business_id = '00000000-0000-0000-0000-0000000113b3'
      order by id desc limit 1) <> 'owner' then
    raise exception 'FAIL: resubmission not logged as owner';
  end if;

  -- owner's own withdrawal does not carry a reviewer's reason
  update public.businesses set status = 'pending'
    where business_id = '00000000-0000-0000-0000-0000000113b2';
  update public.businesses set status = 'withdrawn'
    where business_id = '00000000-0000-0000-0000-0000000113b2';
  if (select rejection_reason from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000113b2') is not null then
    raise exception 'FAIL: owner withdrawal kept a stale reason';
  end if;

end $$;
reset role;

-- S0 bounce is logged (approved listing edited by its owner) ---------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000113a01","role":"authenticated"}', true);
do $$ declare l record; begin
  update public.businesses set name = 'approved edited'
    where business_id = '00000000-0000-0000-0000-0000000113b1';
  select * into l from public.business_review_log
    where business_id = '00000000-0000-0000-0000-0000000113b1'
    order by id desc limit 1;
  if l.from_status <> 'approved' or l.to_status <> 'pending' or l.actor_role <> 'owner' then
    raise exception 'FAIL: return to review (S0) not logged';
  end if;
end $$;
reset role;

-- A new listing leaves its first log entry ---------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000113a02","role":"authenticated"}', true);
do $$ begin
  insert into public.businesses (business_id, owner_id, name)
    values ('00000000-0000-0000-0000-0000000113b5', '00000000-0000-0000-0000-000000113a02', 'new');
  if (select to_status from public.business_review_log
      where business_id = '00000000-0000-0000-0000-0000000113b5') <> 'pending' then
    raise exception 'FAIL: new listing not logged as pending';
  end if;
end $$;
reset role;

rollback;
