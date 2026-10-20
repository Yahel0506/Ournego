-- OUR-151 - RPC request_account_deletion()
-- Plan: docs/development/plans/our-142-account-deletion.md (D4, D5, D7)
--
-- Called by the signed-in user after the email-link verification (the link
-- opens a temporary session). Schedules the deletion, revokes the sessions and
-- hides the user's businesses. Requires 2026-10-20_account_deletion_requests.sql.

-- Businesses hidden by the request, so cancelling (OUR-153) restores only
-- those that were visible before and not every business of the owner.
alter table public.account_deletion_requests
  add column if not exists hidden_business_ids uuid[] not null default '{}';

-- Grace period (D5). Configurable without a deploy so the end-to-end test can
-- use minutes instead of 30 days:
--   alter database postgres set app.account_deletion_grace_period = '5 minutes';
-- Unset or invalid values fall back to 30 days. Not callable from the API: the
-- RPC takes no period argument, otherwise a client could pick its own.
create or replace function public.account_deletion_grace_period()
returns interval
language plpgsql
stable
set search_path = ''
as $$
begin
  return coalesce(
    nullif(current_setting('app.account_deletion_grace_period', true), '')::interval,
    interval '30 days'
  );
exception when others then
  return interval '30 days';
end;
$$;

revoke all on function public.account_deletion_grace_period()
  from public, anon, authenticated;

create or replace function public.request_account_deletion()
returns table (request_id uuid, status text, execute_after timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
#variable_conflict use_column
declare
  uid uuid := auth.uid();
  user_email text;
  request public.account_deletion_requests;
  hidden uuid[];
begin
  if uid is null then
    raise exception 'not authenticated' using errcode = '28000';
  end if;

  select lower(btrim(u.email)) into user_email
  from auth.users u
  where u.id = uid;

  if user_email is null or user_email = '' then
    raise exception 'account has no email' using errcode = '22023';
  end if;

  -- Idempotent: an active request is returned as is, the date is not extended.
  select r.* into request
  from public.account_deletion_requests r
  where r.user_id = uid and r.status in ('pending', 'scheduled')
  for update;

  if not found then
    insert into public.account_deletion_requests
      (user_id, email_hash, status, execute_after)
    values (
      uid,
      encode(sha256(convert_to(user_email, 'UTF8')), 'hex'),
      'scheduled',
      now() + public.account_deletion_grace_period()
    )
    on conflict (user_id) where status in ('pending', 'scheduled') do nothing
    returning * into request;

    if not found then
      -- Lost a race against a concurrent call: return the winner's row.
      select r.* into request
      from public.account_deletion_requests r
      where r.user_id = uid and r.status in ('pending', 'scheduled');
    end if;
  elsif request.status = 'pending' then
    update public.account_deletion_requests r
    set status = 'scheduled',
        execute_after = now() + public.account_deletion_grace_period()
    where r.id = request.id
    returning * into request;
  end if;

  -- Hide only what is visible now and remember it for the restore.
  with hidden_now as (
    update public.businesses b
    set is_active = false
    where b.owner_id = uid and b.is_active
    returning b.business_id
  )
  select coalesce(array_agg(h.business_id), '{}') into hidden from hidden_now h;

  if cardinality(hidden) > 0 then
    update public.account_deletion_requests r
    set hidden_business_ids = r.hidden_business_ids || hidden
    where r.id = request.id
    returning * into request;
  end if;

  -- Revoke every session (refresh tokens cascade). The access token in hand
  -- keeps working until it expires (up to the JWT lifetime); the caller must
  -- sign out right after this call.
  delete from auth.sessions s where s.user_id = uid;

  return query select request.id, request.status, request.execute_after;
end;
$$;

revoke all on function public.request_account_deletion() from public, anon;
grant execute on function public.request_account_deletion() to authenticated;
