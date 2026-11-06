-- OUR-111 - Only approved listings are public, enforced by the server.
--
-- Adds `businesses.status` (pending | approved | rejected | withdrawn), a
-- `reviewers` allow-list and the access rules that depend on them:
--   * public/anon: only `status = 'approved' and is_active` rows (and the
--     hours/products/exceptions of those rows);
--   * owner: reads and edits their own listings in any status, can only create
--     them as `pending` and can only move them to `withdrawn`;
--   * reviewer (row in `public.reviewers`): reads every listing and sets any
--     status. OUR-113 builds the moderation flow on top of this.
-- `is_active = false` (account deletion) still hides a listing from the public
-- even when it is approved. Existing rows are migrated as `approved`.
-- Idempotent. Test with docs/sql/tests/2026-11-05_business_review_status_test.sql.

begin;

do $$ begin
  create type public.business_status as enum
    ('pending', 'approved', 'rejected', 'withdrawn');
exception when duplicate_object then null; end $$;

-- Existing catalog is approved; new rows default to pending afterwards.
alter table public.businesses
  add column if not exists status public.business_status not null default 'approved';
alter table public.businesses alter column status set default 'pending';

create index if not exists businesses_status_idx on public.businesses (status);

-- Reviewers: managed from the dashboard / service role only.
create table if not exists public.reviewers (
  user_id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
alter table public.reviewers enable row level security;
drop policy if exists reviewers_select_self on public.reviewers;
create policy reviewers_select_self on public.reviewers
  for select to authenticated using (user_id = (select auth.uid()));

create or replace function public.is_reviewer()
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (select 1 from public.reviewers where user_id = auth.uid());
$$;

create or replace function public.is_business_public(p_business_id uuid)
returns boolean
language sql stable security definer set search_path = public
as $$
  select exists (
    select 1 from public.businesses b
    where b.business_id = p_business_id
      and b.status = 'approved' and b.is_active is not false
  );
$$;

revoke all on function public.is_reviewer() from public;
revoke all on function public.is_business_public(uuid) from public;
grant execute on function public.is_reviewer() to anon, authenticated;
grant execute on function public.is_business_public(uuid) to anon, authenticated;

-- businesses --------------------------------------------------------------
drop policy if exists "Enable read access for all users" on public.businesses;
drop policy if exists businesses_select_public on public.businesses;
drop policy if exists businesses_select_owner on public.businesses;
drop policy if exists businesses_select_reviewer on public.businesses;
create policy businesses_select_public on public.businesses
  for select to anon, authenticated
  using (status = 'approved' and is_active is not false);
create policy businesses_select_owner on public.businesses
  for select to authenticated using (owner_id = (select auth.uid()));
create policy businesses_select_reviewer on public.businesses
  for select to authenticated using (public.is_reviewer());

drop policy if exists "Enable insert access for users based on owner_id" on public.businesses;
drop policy if exists businesses_insert_owner on public.businesses;
create policy businesses_insert_owner on public.businesses
  for insert to authenticated
  with check (owner_id = (select auth.uid()) and status = 'pending');

drop policy if exists businesses_update_reviewer on public.businesses;
create policy businesses_update_reviewer on public.businesses
  for update to authenticated
  using (public.is_reviewer()) with check (public.is_reviewer());

-- The owner update policy stays; the trigger limits which status moves it
-- may make (a policy cannot compare old and new values).
create or replace function public.enforce_business_status_change()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if new.status is not distinct from old.status then
    return new;
  end if;
  -- Service role / database owner (no end-user session) and reviewers.
  if auth.uid() is null or public.is_reviewer() then
    return new;
  end if;
  if new.status = 'withdrawn' and old.owner_id = auth.uid() then
    return new;
  end if;
  raise exception 'business status change not allowed' using errcode = '42501';
end;
$$;
drop trigger if exists businesses_enforce_status_change on public.businesses;
create trigger businesses_enforce_status_change
  before update on public.businesses
  for each row execute function public.enforce_business_status_change();

-- Child tables: public reads only for public listings -----------------------
drop policy if exists "Lectura pública de horarios" on public.business_hours;
drop policy if exists business_hours_select_public on public.business_hours;
drop policy if exists business_hours_select_reviewer on public.business_hours;
create policy business_hours_select_public on public.business_hours
  for select to anon, authenticated using (public.is_business_public(business_id));
create policy business_hours_select_reviewer on public.business_hours
  for select to authenticated using (public.is_reviewer());

drop policy if exists "Lectura pública de productos de negocios" on public.business_products;
drop policy if exists business_products_select_public on public.business_products;
drop policy if exists business_products_select_owner on public.business_products;
drop policy if exists business_products_select_reviewer on public.business_products;
create policy business_products_select_public on public.business_products
  for select to anon, authenticated using (public.is_business_public(business_id));
create policy business_products_select_owner on public.business_products
  for select to authenticated using (exists (
    select 1 from public.businesses b
    where b.business_id = business_products.business_id
      and b.owner_id = (select auth.uid())));
create policy business_products_select_reviewer on public.business_products
  for select to authenticated using (public.is_reviewer());

drop policy if exists "Lectura pública de excepciones" on public.business_exceptions;
drop policy if exists business_exceptions_select_public on public.business_exceptions;
drop policy if exists business_exceptions_select_owner on public.business_exceptions;
drop policy if exists business_exceptions_select_reviewer on public.business_exceptions;
create policy business_exceptions_select_public on public.business_exceptions
  for select to anon, authenticated using (public.is_business_public(business_id));
create policy business_exceptions_select_owner on public.business_exceptions
  for select to authenticated using (exists (
    select 1 from public.businesses b
    where b.business_id = business_exceptions.business_id
      and b.owner_id = (select auth.uid())));
create policy business_exceptions_select_reviewer on public.business_exceptions
  for select to authenticated using (public.is_reviewer());

commit;
