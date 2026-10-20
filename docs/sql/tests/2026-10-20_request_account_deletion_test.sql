-- OUR-151 - Tests for public.request_account_deletion()
-- Run after 2026-10-20_request_account_deletion.sql. Everything is rolled back;
-- a failing check raises an exception that starts with FAIL.

begin;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-00000000000a', 'authenticated', 'authenticated', '  Owner.A@Test.invalid '),
  ('00000000-0000-0000-0000-00000000000b', 'authenticated', 'authenticated', 'b@test.invalid');

insert into auth.sessions (id, user_id) values
  (gen_random_uuid(), '00000000-0000-0000-0000-00000000000a'),
  (gen_random_uuid(), '00000000-0000-0000-0000-00000000000a'),
  (gen_random_uuid(), '00000000-0000-0000-0000-00000000000b');

-- Setup of businesses: copy a real row's shape is brittle, so reuse any
-- existing business and temporarily reassign it.
do $$
declare
  ids uuid[];
begin
  select array_agg(id) into ids from (select id from public.businesses limit 2) s;
  if cardinality(ids) < 2 then
    raise notice 'SKIP business checks: need at least 2 businesses in the database';
  else
    update public.businesses set owner_id = '00000000-0000-0000-0000-00000000000a', is_active = true where id = ids[1];
    update public.businesses set owner_id = '00000000-0000-0000-0000-00000000000a', is_active = false where id = ids[2];
  end if;
end $$;

-- Anonymous cannot call it ---------------------------------------------------
set local role anon;
do $$ begin
  begin
    perform * from public.request_account_deletion();
    raise exception 'FAIL: anon can call the RPC';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- The grace period helper is not exposed -------------------------------------
set local role authenticated;
do $$ begin
  begin
    perform public.account_deletion_grace_period();
    raise exception 'FAIL: authenticated can call the grace period helper';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- Authenticated user A -------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}', true);

create temp table first_call on commit drop as
  select * from public.request_account_deletion();
grant all on first_call to authenticated;

do $$
declare
  r record;
  second record;
begin
  select * into r from first_call;
  if r.status <> 'scheduled' then
    raise exception 'FAIL: status is %, expected scheduled', r.status;
  end if;
  if r.execute_after < now() + interval '29 days 23 hours'
     or r.execute_after > now() + interval '30 days 1 hour' then
    raise exception 'FAIL: execute_after % is not ~30 days away', r.execute_after;
  end if;

  -- Idempotent: same row, same date.
  select * into second from public.request_account_deletion();
  if second.request_id <> r.request_id or second.execute_after <> r.execute_after then
    raise exception 'FAIL: second call created or moved the request';
  end if;
end $$;

reset role;

do $$
declare
  rows_count integer;
  expected_hash text := encode(sha256(convert_to('owner.a@test.invalid', 'UTF8')), 'hex');
  stored text;
  hidden uuid[];
  active_left integer;
begin
  select count(*), max(email_hash), max(hidden_business_ids) into rows_count, stored, hidden
  from public.account_deletion_requests
  where user_id = '00000000-0000-0000-0000-00000000000a';
  if rows_count <> 1 then
    raise exception 'FAIL: % requests for user A, expected 1', rows_count;
  end if;
  if stored <> expected_hash then
    raise exception 'FAIL: email hash is not sha256 of the normalized email';
  end if;

  if exists (select 1 from auth.sessions where user_id = '00000000-0000-0000-0000-00000000000a') then
    raise exception 'FAIL: sessions of user A were not revoked';
  end if;
  if not exists (select 1 from auth.sessions where user_id = '00000000-0000-0000-0000-00000000000b') then
    raise exception 'FAIL: sessions of user B were revoked';
  end if;

  select count(*) into active_left from public.businesses
  where owner_id = '00000000-0000-0000-0000-00000000000a' and is_active;
  if active_left <> 0 then
    raise exception 'FAIL: % businesses still active', active_left;
  end if;
  -- Only the business that was active is remembered for the restore.
  if exists (select 1 from public.businesses where owner_id = '00000000-0000-0000-0000-00000000000a')
     and cardinality(hidden) <> 1 then
    raise exception 'FAIL: hidden_business_ids has % entries, expected 1', cardinality(hidden);
  end if;
end $$;

-- A user can only act on their own account: B gets their own request ----------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}', true);
do $$
declare
  r record;
begin
  select * into r from public.request_account_deletion();
  if (select user_id from public.account_deletion_requests where id = r.request_id)
     <> '00000000-0000-0000-0000-00000000000b' then
    raise exception 'FAIL: request of B is not linked to B';
  end if;
end $$;
reset role;

-- Configurable grace period ----------------------------------------------------
delete from public.account_deletion_requests
  where user_id = '00000000-0000-0000-0000-00000000000b';
select set_config('app.account_deletion_grace_period', '5 minutes', true);
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-00000000000b", "role": "authenticated"}', true);
do $$
declare
  r record;
begin
  select * into r from public.request_account_deletion();
  if r.execute_after > now() + interval '6 minutes' then
    raise exception 'FAIL: configured grace period ignored (%)', r.execute_after;
  end if;
end $$;
reset role;

-- Without a session the RPC refuses ------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"role": "authenticated"}', true);
do $$ begin
  begin
    perform * from public.request_account_deletion();
    raise exception 'FAIL: RPC accepted a call without auth.uid()';
  exception when invalid_authorization_specification then null;
  end;
end $$;
reset role;

rollback;
