-- OUR-153 - Tests for public.cancel_my_deletion(),
-- public.dispatch_due_account_deletions() and
-- public.consume_account_deletion_dispatch().
-- Run after 2026-10-27_cancel_and_schedule_account_deletion.sql. Everything is
-- rolled back (including the queued HTTP calls of pg_net, which are only sent
-- after commit); a failing check raises an exception that starts with FAIL.

begin;

-- A cancels in time, B cancels late, C has no request, D is not due yet.
insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-0000000153a1', 'authenticated', 'authenticated', 'cancel-a@test.invalid'),
  ('00000000-0000-0000-0000-0000000153b1', 'authenticated', 'authenticated', 'late-b@test.invalid'),
  ('00000000-0000-0000-0000-0000000153c1', 'authenticated', 'authenticated', 'none-c@test.invalid'),
  ('00000000-0000-0000-0000-0000000153d1', 'authenticated', 'authenticated', 'notdue-d@test.invalid');

insert into public.businesses (business_id, owner_id, name, is_active) values
  ('00000000-0000-0000-0000-00000153a0b1', '00000000-0000-0000-0000-0000000153a1', 'A visible', true),
  ('00000000-0000-0000-0000-00000153a0b2', '00000000-0000-0000-0000-0000000153a1', 'A hidden by owner', false),
  ('00000000-0000-0000-0000-00000153b0b1', '00000000-0000-0000-0000-0000000153b1', 'B visible', true);

-- The dispatcher needs the project URL; use a fake one if the project has none.
do $$ begin
  if not exists (select 1 from vault.secrets where name = 'project_url') then
    perform vault.create_secret('https://example.invalid', 'project_url');
  end if;
end $$;

-- Permissions -------------------------------------------------------------------
set local role anon;
do $$ begin
  begin
    perform public.cancel_my_deletion();
    raise exception 'FAIL: anon can call cancel_my_deletion';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

set local role authenticated;
do $$ begin
  begin
    perform public.dispatch_due_account_deletions();
    raise exception 'FAIL: authenticated can call the dispatcher';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.consume_account_deletion_dispatch(gen_random_uuid(), 'x');
    raise exception 'FAIL: authenticated can call consume_account_deletion_dispatch';
  exception when insufficient_privilege then null;
  end;
  begin
    perform 1 from public.account_deletion_dispatches;
    raise exception 'FAIL: authenticated can read the dispatches';
  exception when insufficient_privilege then null;
  end;
  begin
    perform 1 from public.account_deletion_settings;
    raise exception 'FAIL: authenticated can read the settings';
  exception when insufficient_privilege then null;
  end;
end $$;
-- Without a session the RPC refuses.
select set_config('request.jwt.claims', '{"role": "authenticated"}', true);
do $$ begin
  begin
    perform public.cancel_my_deletion();
    raise exception 'FAIL: cancel accepted a call without auth.uid()';
  exception when invalid_authorization_specification then null;
  end;
end $$;
reset role;

-- Requests of A, B and D -------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-0000000153a1", "role": "authenticated"}', true);
select * from public.request_account_deletion();
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-0000000153b1", "role": "authenticated"}', true);
select * from public.request_account_deletion();
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-0000000153d1", "role": "authenticated"}', true);
select * from public.request_account_deletion();
reset role;

-- B's grace period is over (the job has not run yet).
update public.account_deletion_requests
set execute_after = now() - interval '1 minute'
where user_id = '00000000-0000-0000-0000-0000000153b1';

-- Cancel in time -----------------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-0000000153a1", "role": "authenticated"}', true);
do $$ begin
  if public.cancel_my_deletion() is not true then
    raise exception 'FAIL: cancel in time returned false';
  end if;
  -- Nothing left to cancel: the second call reports no change.
  if public.cancel_my_deletion() is not false then
    raise exception 'FAIL: second cancel returned true';
  end if;
end $$;
reset role;

do $$ begin
  if not exists (
    select 1 from public.account_deletion_requests
    where user_id = '00000000-0000-0000-0000-0000000153a1'
      and status = 'cancelled' and cancelled_at is not null
  ) then
    raise exception 'FAIL: request of A is not cancelled';
  end if;
  if not exists (select 1 from public.businesses
                 where business_id = '00000000-0000-0000-0000-00000153a0b1' and is_active) then
    raise exception 'FAIL: business hidden by the request was not restored';
  end if;
  if exists (select 1 from public.businesses
             where business_id = '00000000-0000-0000-0000-00000153a0b2' and is_active) then
    raise exception 'FAIL: business hidden by its owner was made visible';
  end if;
end $$;

-- A can ask again after cancelling (the active-request index allows it).
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-0000000153a1", "role": "authenticated"}', true);
do $$
declare
  r record;
begin
  select * into r from public.request_account_deletion();
  if r.status <> 'scheduled' then
    raise exception 'FAIL: new request after cancelling is %', r.status;
  end if;
  if public.cancel_my_deletion() is not true then
    raise exception 'FAIL: could not cancel the new request';
  end if;
end $$;
reset role;

-- Late cancel is rejected --------------------------------------------------------
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-0000000153b1", "role": "authenticated"}', true);
do $$ begin
  if public.cancel_my_deletion() is not false then
    raise exception 'FAIL: late cancel returned true';
  end if;
end $$;
-- C has nothing to cancel.
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-0000000153c1", "role": "authenticated"}', true);
do $$ begin
  if public.cancel_my_deletion() is not false then
    raise exception 'FAIL: cancel without a request returned true';
  end if;
end $$;
reset role;

do $$ begin
  if not exists (
    select 1 from public.account_deletion_requests
    where user_id = '00000000-0000-0000-0000-0000000153b1'
      and status = 'scheduled' and cancelled_at is null
  ) then
    raise exception 'FAIL: late cancel changed the request of B';
  end if;
  if exists (select 1 from public.businesses
             where business_id = '00000000-0000-0000-0000-00000153b0b1' and is_active) then
    raise exception 'FAIL: late cancel restored the business of B';
  end if;
end $$;

-- Execution when due: the dispatcher sends B only --------------------------------
create temp table ids on commit drop as
  select user_id, id from public.account_deletion_requests
  where user_id in ('00000000-0000-0000-0000-0000000153a1',
                    '00000000-0000-0000-0000-0000000153b1',
                    '00000000-0000-0000-0000-0000000153d1');

select public.dispatch_due_account_deletions();

do $$
declare
  b constant uuid := (select id from ids where user_id = '00000000-0000-0000-0000-0000000153b1');
  d_row public.account_deletion_dispatches;
  sent jsonb;
begin
  select * into d_row from public.account_deletion_dispatches where request_id = b;
  if not found or d_row.attempts <> 1 or d_row.token_hash is null
     or d_row.net_request_id is null then
    raise exception 'FAIL: due request of B was not dispatched';
  end if;

  select convert_from(q.body, 'UTF8')::jsonb into sent
  from net.http_request_queue q where q.id = d_row.net_request_id;
  if sent->>'request_id' <> b::text
     or encode(sha256(convert_to(sent->>'dispatch_token', 'UTF8')), 'hex') <> d_row.token_hash then
    raise exception 'FAIL: queued HTTP body does not match the dispatch (%)', sent;
  end if;

  if exists (select 1 from public.account_deletion_dispatches dd
             join ids on ids.id = dd.request_id
             where ids.user_id in ('00000000-0000-0000-0000-0000000153a1',
                                   '00000000-0000-0000-0000-0000000153d1')) then
    raise exception 'FAIL: a cancelled or not-due request was dispatched';
  end if;
end $$;

-- Running again right away does not resend B.
select public.dispatch_due_account_deletions();
do $$ begin
  if (select attempts from public.account_deletion_dispatches d
      join ids on ids.id = d.request_id
      where ids.user_id = '00000000-0000-0000-0000-0000000153b1') <> 1 then
    raise exception 'FAIL: B was resent before the retry interval';
  end if;
end $$;

-- The token works once, only for its request, and not when stale ---------------
do $$
declare
  b constant uuid := (select id from ids where user_id = '00000000-0000-0000-0000-0000000153b1');
  token text;
begin
  select convert_from(q.body, 'UTF8')::jsonb->>'dispatch_token' into token
  from public.account_deletion_dispatches d
  join net.http_request_queue q on q.id = d.net_request_id
  where d.request_id = b;

  if public.consume_account_deletion_dispatch(b, repeat('0', 64)) then
    raise exception 'FAIL: a wrong token was accepted';
  end if;
  if public.consume_account_deletion_dispatch(gen_random_uuid(), token) then
    raise exception 'FAIL: the token was accepted for another request';
  end if;
  if not public.consume_account_deletion_dispatch(b, token) then
    raise exception 'FAIL: the right token was rejected';
  end if;
  if public.consume_account_deletion_dispatch(b, token) then
    raise exception 'FAIL: the token was accepted twice';
  end if;
end $$;

-- Retry of failed requests --------------------------------------------------------
update public.account_deletion_requests r set status = 'failed'
from ids where ids.id = r.id and ids.user_id = '00000000-0000-0000-0000-0000000153b1';
update public.account_deletion_dispatches d set dispatched_at = now() - interval '2 hours'
from ids where ids.id = d.request_id and ids.user_id = '00000000-0000-0000-0000-0000000153b1';

select public.dispatch_due_account_deletions();

do $$
declare
  b constant uuid := (select id from ids where user_id = '00000000-0000-0000-0000-0000000153b1');
  d_row public.account_deletion_dispatches;
  token text;
begin
  select * into d_row from public.account_deletion_dispatches where request_id = b;
  if d_row.attempts <> 2 or d_row.token_hash is null then
    raise exception 'FAIL: failed request was not retried (attempts %)', d_row.attempts;
  end if;

  -- A token older than 15 minutes is refused.
  select convert_from(q.body, 'UTF8')::jsonb->>'dispatch_token' into token
  from net.http_request_queue q where q.id = d_row.net_request_id;
  update public.account_deletion_dispatches set dispatched_at = now() - interval '16 minutes'
  where request_id = b;
  if public.consume_account_deletion_dispatch(b, token) then
    raise exception 'FAIL: a stale token was accepted';
  end if;
end $$;

-- After 5 attempts it is left alone.
update public.account_deletion_dispatches d
set attempts = 5, dispatched_at = now() - interval '2 hours'
from ids where ids.id = d.request_id and ids.user_id = '00000000-0000-0000-0000-0000000153b1';
select public.dispatch_due_account_deletions();
do $$ begin
  if (select attempts from public.account_deletion_dispatches d
      join ids on ids.id = d.request_id
      where ids.user_id = '00000000-0000-0000-0000-0000000153b1') <> 5 then
    raise exception 'FAIL: request was retried past the attempt limit';
  end if;
end $$;

-- Configurable grace period (table; a session value still overrides it) ------------
update public.account_deletion_settings set grace_period = interval '5 minutes';
do $$ begin
  if public.account_deletion_grace_period() <> interval '5 minutes' then
    raise exception 'FAIL: grace period table ignored (%)', public.account_deletion_grace_period();
  end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub": "00000000-0000-0000-0000-0000000153c1", "role": "authenticated"}', true);
do $$
declare
  r record;
begin
  select * into r from public.request_account_deletion();
  if r.execute_after > now() + interval '6 minutes' then
    raise exception 'FAIL: request ignored the configured grace period (%)', r.execute_after;
  end if;
end $$;
reset role;
select set_config('app.account_deletion_grace_period', '2 days', true);
do $$ begin
  if public.account_deletion_grace_period() <> interval '2 days' then
    raise exception 'FAIL: session value does not override the table';
  end if;
end $$;
select set_config('app.account_deletion_grace_period', 'not an interval', true);
do $$ begin
  if public.account_deletion_grace_period() <> interval '5 minutes' then
    raise exception 'FAIL: invalid session value does not fall back to the table';
  end if;
end $$;
select set_config('app.account_deletion_grace_period', '', true);

-- Jobs are scheduled ----------------------------------------------------------------
do $$ begin
  if not exists (select 1 from cron.job
                 where jobname = 'execute-due-account-deletions' and active)
     or not exists (select 1 from cron.job
                    where jobname = 'purge-expired-account-deletion-requests' and active) then
    raise exception 'FAIL: pg_cron jobs are missing';
  end if;
end $$;

rollback;
