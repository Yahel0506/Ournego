-- OUR-138 - Account deletion requests (table, RLS and retention rule)
-- Plan: docs/development/plans/our-142-account-deletion.md (D4, D5, D7)
--
-- A row is created only after the email is verified (RPC in OUR-151), so
-- `pending` is currently unused; it stays in the allowed states on purpose.
-- Writes happen only from SECURITY DEFINER functions (OUR-151, 152, 153).

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  -- SET NULL: executing the deletion removes the auth user, but the
  -- compliance record (email hash + dates) must survive for 12 months.
  user_id uuid null references auth.users(id) on delete set null,
  -- SHA-256 hex of lower(trim(email)). The plain email is never stored.
  email_hash text not null check (email_hash ~ '^[0-9a-f]{64}$'),
  status text not null default 'pending' check (
    status in ('pending', 'scheduled', 'cancelled', 'completed', 'failed')
  ),
  created_at timestamptz not null default now(),
  execute_after timestamptz null,
  cancelled_at timestamptz null,
  completed_at timestamptz null,
  constraint account_deletion_requests_scheduled_needs_date
    check (status <> 'scheduled' or execute_after is not null),
  constraint account_deletion_requests_cancelled_needs_date
    check (status <> 'cancelled' or cancelled_at is not null),
  constraint account_deletion_requests_completed_needs_date
    check (status <> 'completed' or completed_at is not null)
);

-- One active request per user keeps request_account_deletion() idempotent.
create unique index if not exists uq_account_deletion_requests_active_user
  on public.account_deletion_requests (user_id)
  where status in ('pending', 'scheduled');

-- Used by the job that executes overdue deletions (OUR-153).
create index if not exists idx_account_deletion_requests_due
  on public.account_deletion_requests (execute_after)
  where status = 'scheduled';

alter table public.account_deletion_requests enable row level security;

-- Supabase grants new tables to anon/authenticated by default; remove it and
-- leave only read access to the owner. No insert/update/delete policies exist.
revoke all on public.account_deletion_requests from anon, authenticated;
grant select on public.account_deletion_requests to authenticated;

drop policy if exists "account_deletion_requests_select_own"
  on public.account_deletion_requests;
create policy "account_deletion_requests_select_own"
on public.account_deletion_requests
for select
to authenticated
using (user_id = (select auth.uid()));

-- Retention rule (D7): keep the record 12 months after it is completed or
-- cancelled. `pending`, `scheduled` and `failed` rows are never purged.
-- Scheduling with pg_cron is done in OUR-153.
create or replace function public.purge_expired_account_deletion_requests()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  deleted_count integer;
begin
  delete from public.account_deletion_requests
  where (status = 'completed' and completed_at < now() - interval '12 months')
     or (status = 'cancelled' and cancelled_at < now() - interval '12 months');
  get diagnostics deleted_count = row_count;
  return deleted_count;
end;
$$;

revoke all on function public.purge_expired_account_deletion_requests()
  from public, anon, authenticated;
