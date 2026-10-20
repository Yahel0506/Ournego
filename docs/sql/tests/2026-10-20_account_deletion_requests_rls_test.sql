-- OUR-138 - RLS and constraint tests for public.account_deletion_requests
-- Run after 2026-10-20_account_deletion_requests.sql, e.g.:
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f <this file>
-- Everything runs inside a transaction that is rolled back; a failing check
-- raises an exception that starts with FAIL.

begin;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-00000000000a', 'authenticated', 'authenticated', 'a@test.invalid'),
  ('00000000-0000-0000-0000-00000000000b', 'authenticated', 'authenticated', 'b@test.invalid');

insert into public.account_deletion_requests
  (user_id, email_hash, status, execute_after)
values
  ('00000000-0000-0000-0000-00000000000a', repeat('a', 64), 'scheduled', now() + interval '30 days'),
  ('00000000-0000-0000-0000-00000000000b', repeat('b', 64), 'scheduled', now() + interval '30 days');

-- Constraints ----------------------------------------------------------------

do $$ begin
  begin
    insert into public.account_deletion_requests (user_id, email_hash, status, execute_after)
    values ('00000000-0000-0000-0000-00000000000a', repeat('c', 64), 'scheduled', now());
    raise exception 'FAIL: second active request for the same user was accepted';
  exception when unique_violation then null;
  end;
  begin
    insert into public.account_deletion_requests (email_hash) values ('not-a-hash');
    raise exception 'FAIL: invalid email_hash was accepted';
  exception when check_violation then null;
  end;
  begin
    insert into public.account_deletion_requests (email_hash, status)
    values (repeat('d', 64), 'scheduled');
    raise exception 'FAIL: scheduled without execute_after was accepted';
  exception when check_violation then null;
  end;
  begin
    insert into public.account_deletion_requests (email_hash, status)
    values (repeat('d', 64), 'deleted');
    raise exception 'FAIL: unknown status was accepted';
  exception when check_violation then null;
  end;
end $$;

-- RLS: authenticated user A -------------------------------------------------

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-00000000000a", "role": "authenticated"}',
  true
);

do $$
declare
  seen integer;
  foreign_rows integer;
begin
  select count(*) into seen from public.account_deletion_requests;
  if seen <> 1 then
    raise exception 'FAIL: user A sees % rows, expected 1', seen;
  end if;

  select count(*) into foreign_rows from public.account_deletion_requests
  where user_id = '00000000-0000-0000-0000-00000000000b';
  if foreign_rows <> 0 then
    raise exception 'FAIL: user A can read the request of user B';
  end if;

  begin
    insert into public.account_deletion_requests (user_id, email_hash, status, execute_after)
    values ('00000000-0000-0000-0000-00000000000a', repeat('e', 64), 'scheduled', now());
    raise exception 'FAIL: authenticated insert was allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    update public.account_deletion_requests set status = 'cancelled';
    raise exception 'FAIL: authenticated update was allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    delete from public.account_deletion_requests;
    raise exception 'FAIL: authenticated delete was allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.purge_expired_account_deletion_requests();
    raise exception 'FAIL: authenticated can run the purge function';
  exception when insufficient_privilege then null;
  end;
end $$;

-- RLS: anonymous -------------------------------------------------------------

reset role;
set local role anon;

do $$ begin
  begin
    perform 1 from public.account_deletion_requests;
    raise exception 'FAIL: anon can read the table';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.account_deletion_requests (email_hash) values (repeat('f', 64));
    raise exception 'FAIL: anon insert was allowed';
  exception when insufficient_privilege then null;
  end;
end $$;

reset role;

-- Retention rule -------------------------------------------------------------

insert into public.account_deletion_requests
  (email_hash, status, created_at, cancelled_at, completed_at, execute_after)
values
  (repeat('1', 64), 'completed', now() - interval '14 months', null, now() - interval '13 months', now() - interval '13 months'),
  (repeat('2', 64), 'cancelled', now() - interval '14 months', now() - interval '13 months', null, null),
  (repeat('3', 64), 'completed', now() - interval '2 months', null, now() - interval '1 month', now() - interval '1 month'),
  (repeat('4', 64), 'cancelled', now() - interval '2 months', now() - interval '1 month', null, null),
  (repeat('5', 64), 'failed', now() - interval '14 months', null, null, now() - interval '13 months');

do $$
declare
  purged integer;
  kept integer;
begin
  purged := public.purge_expired_account_deletion_requests();
  if purged <> 2 then
    raise exception 'FAIL: purge removed % rows, expected 2', purged;
  end if;

  select count(*) into kept from public.account_deletion_requests
  where email_hash in (repeat('3', 64), repeat('4', 64), repeat('5', 64));
  if kept <> 3 then
    raise exception 'FAIL: purge removed recent or failed rows (kept %)', kept;
  end if;
end $$;

-- The compliance record survives the deletion of the auth user ---------------

delete from auth.users where id = '00000000-0000-0000-0000-00000000000b';

do $$
declare
  survivors integer;
begin
  select count(*) into survivors from public.account_deletion_requests
  where email_hash = repeat('b', 64) and user_id is null;
  if survivors <> 1 then
    raise exception 'FAIL: record of deleted user did not survive with user_id null';
  end if;
end $$;

rollback;
