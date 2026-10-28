-- OUR-153 - Cancel the deletion and schedule its execution
-- Plan: docs/development/plans/our-142-account-deletion.md (D5, D10)
--
-- Requires 2026-10-20_request_account_deletion.sql,
-- 2026-10-26_delete_user_data.sql and the Edge Function
-- `execute-account-deletion` (deployed with verify_jwt = false; it checks the
-- one-time dispatch token created here, or the service role key).
--
-- One-time setup per project, kept out of this file because it names the
-- project (the URL is not a secret, Vault is just where Supabase keeps it):
--   select vault.create_secret('https://<ref>.supabase.co', 'project_url');
--
create extension if not exists pg_cron with schema pg_catalog;
create extension if not exists pg_net with schema extensions;

-- Grace period ----------------------------------------------------------------

-- Supabase does not let `postgres` run ALTER DATABASE ... SET for custom
-- parameters, so the setting of OUR-151 could not be changed in production.
-- It lives in this one-row table instead (no API access). It applies to new
-- requests only. To test without waiting 30 days:
--   update public.account_deletion_settings set grace_period = '5 minutes';
--   update public.account_deletion_settings set grace_period = '30 days';
create table if not exists public.account_deletion_settings (
  id boolean primary key default true check (id),
  grace_period interval not null default interval '30 days'
    check (grace_period > interval '0')
);

insert into public.account_deletion_settings (id) values (true)
  on conflict (id) do nothing;

alter table public.account_deletion_settings enable row level security;
revoke all on public.account_deletion_settings from anon, authenticated;

-- A session value of app.account_deletion_grace_period still wins (used by the
-- SQL tests with set_config). Unset or invalid values fall back to the table,
-- then to 30 days.
create or replace function public.account_deletion_grace_period()
returns interval
language plpgsql
stable
set search_path = ''
as $$
declare
  configured interval;
begin
  begin
    configured := nullif(
      current_setting('app.account_deletion_grace_period', true), ''
    )::interval;
  exception when others then
    configured := null;
  end;

  if configured is null then
    select s.grace_period into configured
    from public.account_deletion_settings s
    where s.id;
  end if;

  return coalesce(configured, interval '30 days');
end;
$$;

revoke all on function public.account_deletion_grace_period()
  from public, anon, authenticated;

-- Cancel ----------------------------------------------------------------------

-- Called by the signed-in user from the web page (D10a) or right after signing
-- in to the app (D10b). Returns true only if a request was cancelled, so the
-- caller knows whether to show "we restored your account". Once execute_after
-- has passed the request can no longer be cancelled and false is returned.
create or replace function public.cancel_my_deletion()
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  request public.account_deletion_requests;
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  -- FOR UPDATE: waits for a running dispatch of this row (and vice versa).
  select r.* into request
  from public.account_deletion_requests r
  where r.user_id = uid
    and (r.status = 'pending'
         or (r.status = 'scheduled' and r.execute_after > now()))
  for update;

  if not found then
    return false;
  end if;

  update public.account_deletion_requests r
  set status = 'cancelled',
      cancelled_at = now()
  where r.id = request.id;

  -- Restore only what the request hid and the user still owns.
  update public.businesses b
  set is_active = true
  where b.owner_id = uid
    and b.business_id = any (request.hidden_business_ids);

  return true;
end;
$$;

revoke all on function public.cancel_my_deletion() from public, anon;
grant execute on function public.cancel_my_deletion() to authenticated;

-- Dispatch ----------------------------------------------------------------------

-- One row per request sent to the Edge Function. The token travels only in the
-- HTTP body; the table keeps its hash, and the Edge Function consumes it once.
create table if not exists public.account_deletion_dispatches (
  request_id uuid primary key
    references public.account_deletion_requests(id) on delete cascade,
  -- SHA-256 hex of the one-time token. NULL once consumed.
  token_hash text null check (token_hash ~ '^[0-9a-f]{64}$'),
  dispatched_at timestamptz not null,
  attempts integer not null default 1,
  -- net.http_post id, to look the answer up in net._http_response.
  net_request_id bigint null
);

alter table public.account_deletion_dispatches enable row level security;
revoke all on public.account_deletion_dispatches from anon, authenticated;

-- Sends every overdue `scheduled` request, and retries `failed` ones, to the
-- Edge Function. A request already sent is sent again only after an hour
-- (covers a function that never answered) and at most 5 times in total; after
-- that it stays `failed` for a manual look. Run by pg_cron.
create or replace function public.dispatch_due_account_deletions()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  retry_after constant interval := interval '1 hour';
  max_attempts constant integer := 5;
  batch_size constant integer := 20;
  function_url text;
  due_id uuid;
  token text;
  net_id bigint;
  dispatched integer := 0;
begin
  select ds.decrypted_secret || '/functions/v1/execute-account-deletion'
  into function_url
  from vault.decrypted_secrets ds
  where ds.name = 'project_url';

  if function_url is null then
    raise warning 'account deletion: vault secret project_url is missing';
    return 0;
  end if;

  for due_id in
    select r.id
    from public.account_deletion_requests r
    left join public.account_deletion_dispatches d on d.request_id = r.id
    where ((r.status = 'scheduled' and r.execute_after <= now())
           or r.status = 'failed')
      and (d.request_id is null
           or (d.dispatched_at < now() - retry_after
               and d.attempts < max_attempts))
    order by r.execute_after
    limit batch_size
    -- A request being cancelled right now is skipped; the next run sees it.
    for update of r skip locked
  loop
    token := encode(extensions.gen_random_bytes(32), 'hex');

    net_id := net.http_post(
      url := function_url,
      body := jsonb_build_object(
        'request_id', due_id,
        'dispatch_token', token
      ),
      headers := jsonb_build_object('Content-Type', 'application/json'),
      timeout_milliseconds := 60000
    );

    insert into public.account_deletion_dispatches as d
      (request_id, token_hash, dispatched_at, attempts, net_request_id)
    values (
      due_id,
      encode(sha256(convert_to(token, 'UTF8')), 'hex'),
      now(),
      1,
      net_id
    )
    on conflict on constraint account_deletion_dispatches_pkey do update
      set token_hash = excluded.token_hash,
          dispatched_at = excluded.dispatched_at,
          attempts = d.attempts + 1,
          net_request_id = excluded.net_request_id;

    dispatched := dispatched + 1;
  end loop;

  return dispatched;
end;
$$;

revoke all on function public.dispatch_due_account_deletions()
  from public, anon, authenticated;

-- Used by the Edge Function to authenticate a call from the dispatcher. True
-- once per token, and only within 15 minutes of the dispatch.
create or replace function public.consume_account_deletion_dispatch(
  p_request_id uuid,
  p_token text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
begin
  if p_request_id is null or coalesce(p_token, '') = '' then
    return false;
  end if;

  update public.account_deletion_dispatches d
  set token_hash = null
  where d.request_id = p_request_id
    and d.token_hash = encode(sha256(convert_to(p_token, 'UTF8')), 'hex')
    and d.dispatched_at > now() - interval '15 minutes';

  return found;
end;
$$;

revoke all on function public.consume_account_deletion_dispatch(uuid, text)
  from public, anon, authenticated;
grant execute on function public.consume_account_deletion_dispatch(uuid, text)
  to service_role;

-- Jobs (cron.schedule replaces a job with the same name) ------------------------

select cron.schedule(
  'execute-due-account-deletions',
  '*/15 * * * *',
  'select public.dispatch_due_account_deletions()'
);

-- Retention rule of OUR-138 (12 months after completed/cancelled).
select cron.schedule(
  'purge-expired-account-deletion-requests',
  '17 3 * * *',
  'select public.purge_expired_account_deletion_requests()'
);
