-- OUR-111 - Tests for the approved-only access rules on businesses.
-- Run after 2026-11-05_business_review_status.sql. Everything is rolled back;
-- a failing check raises an exception that starts with FAIL.

begin;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-000000111a01', 'authenticated', 'authenticated', 'owner@test.invalid'),
  ('00000000-0000-0000-0000-000000111a02', 'authenticated', 'authenticated', 'other@test.invalid'),
  ('00000000-0000-0000-0000-000000111a03', 'authenticated', 'authenticated', 'reviewer@test.invalid');
insert into public.reviewers (user_id) values ('00000000-0000-0000-0000-000000111a03');

insert into public.businesses (business_id, owner_id, name, status, is_active) values
  ('00000000-0000-0000-0000-0000000111b1', '00000000-0000-0000-0000-000000111a01', 'approved',  'approved',  true),
  ('00000000-0000-0000-0000-0000000111b2', '00000000-0000-0000-0000-000000111a01', 'pending',   'pending',   true),
  ('00000000-0000-0000-0000-0000000111b3', '00000000-0000-0000-0000-000000111a01', 'rejected',  'rejected',  true),
  ('00000000-0000-0000-0000-0000000111b4', '00000000-0000-0000-0000-000000111a01', 'withdrawn', 'withdrawn', true),
  ('00000000-0000-0000-0000-0000000111b5', '00000000-0000-0000-0000-000000111a01', 'hidden',    'approved',  false);
insert into public.business_hours (business_id, day_of_week, opening_time, closing_time) values
  ('00000000-0000-0000-0000-0000000111b1', 1, '08:00', '17:00'),
  ('00000000-0000-0000-0000-0000000111b2', 1, '08:00', '17:00');

-- New rows default to pending; the migrated catalog is not part of this check.
do $$ begin
  if (select column_default from information_schema.columns
      where table_schema = 'public' and table_name = 'businesses' and column_name = 'status')
     not like '%pending%' then
    raise exception 'FAIL: status default is not pending';
  end if;
end $$;

-- Public (anon) -----------------------------------------------------------------
set local role anon;
do $$ declare names text[]; begin
  select array_agg(name order by name) into names from public.businesses
    where business_id::text like '00000000-0000-0000-0000-0000000111b%';
  if names is distinct from array['approved'] then
    raise exception 'FAIL: anon sees % (expected only approved)', names;
  end if;
  if (select count(*) from public.business_hours
      where business_id::text like '00000000-0000-0000-0000-0000000111b%') <> 1 then
    raise exception 'FAIL: anon sees hours of non-approved listings';
  end if;
end $$;
do $$ begin
  begin
    insert into public.businesses (owner_id, name, status) values (null, 'x', 'approved');
    raise exception 'FAIL: anon could insert';
  exception when insufficient_privilege or others then
    if sqlerrm like 'FAIL%' then raise; end if;
  end;
end $$;
reset role;

-- Another authenticated user sees the same as the public ----------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000111a02","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.businesses
      where business_id::text like '00000000-0000-0000-0000-0000000111b%') <> 1 then
    raise exception 'FAIL: non-owner sees non-approved listings';
  end if;
  update public.businesses set name = 'hijack'
    where business_id = '00000000-0000-0000-0000-0000000111b1';
  if found then raise exception 'FAIL: non-owner updated a listing'; end if;
end $$;
reset role;

-- Owner ---------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000111a01","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.businesses
      where business_id::text like '00000000-0000-0000-0000-0000000111b%') <> 5 then
    raise exception 'FAIL: owner does not see all own listings';
  end if;
  if (select count(*) from public.business_hours
      where business_id::text like '00000000-0000-0000-0000-0000000111b%') <> 2 then
    raise exception 'FAIL: owner does not see hours of own pending listing';
  end if;
  -- cannot create approved
  begin
    insert into public.businesses (owner_id, name, status)
      values ('00000000-0000-0000-0000-000000111a01', 'self-approved', 'approved');
    raise exception 'FAIL: owner created an approved listing';
  exception when insufficient_privilege then null; end;
  -- can create pending
  insert into public.businesses (business_id, owner_id, name)
    values ('00000000-0000-0000-0000-0000000111b6', '00000000-0000-0000-0000-000000111a01', 'new');
  if (select status from public.businesses
      where business_id = '00000000-0000-0000-0000-0000000111b6') <> 'pending' then
    raise exception 'FAIL: new listing is not pending';
  end if;
  -- cannot self-approve or re-open
  begin
    update public.businesses set status = 'approved'
      where business_id = '00000000-0000-0000-0000-0000000111b2';
    raise exception 'FAIL: owner approved own listing';
  exception when insufficient_privilege then null; end;
  begin
    update public.businesses set status = 'pending'
      where business_id = '00000000-0000-0000-0000-0000000111b3';
    raise exception 'FAIL: owner re-opened a rejected listing';
  exception when insufficient_privilege then null; end;
  -- can edit other fields and withdraw
  update public.businesses set name = 'approved edited'
    where business_id = '00000000-0000-0000-0000-0000000111b1';
  if not found then raise exception 'FAIL: owner could not edit own listing'; end if;
  update public.businesses set status = 'withdrawn'
    where business_id = '00000000-0000-0000-0000-0000000111b1';
  if not found then raise exception 'FAIL: owner could not withdraw'; end if;
end $$;
reset role;

-- Withdrawn listings leave the public view.
set local role anon;
do $$ begin
  if exists (select 1 from public.businesses
             where business_id = '00000000-0000-0000-0000-0000000111b1') then
    raise exception 'FAIL: withdrawn listing is still public';
  end if;
end $$;
reset role;

-- Reviewer ------------------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-000000111a03","role":"authenticated"}', true);
do $$ begin
  if (select count(*) from public.businesses
      where business_id::text like '00000000-0000-0000-0000-0000000111b%') <> 6 then
    raise exception 'FAIL: reviewer does not see every listing';
  end if;
  update public.businesses set status = 'approved'
    where business_id = '00000000-0000-0000-0000-0000000111b2';
  if not found then raise exception 'FAIL: reviewer could not approve'; end if;
end $$;
reset role;

set local role anon;
do $$ begin
  if not exists (select 1 from public.businesses
                 where business_id = '00000000-0000-0000-0000-0000000111b2') then
    raise exception 'FAIL: approved listing is not public';
  end if;
end $$;
reset role;

rollback;
