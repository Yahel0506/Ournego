-- OUR-113 - Moderation: review decisions are validated and logged by the server.
--
-- Builds on 2026-11-05_business_review_status.sql (OUR-111) and
-- 2026-11-06_business_review_requests.sql (OUR-112). Adds:
--   * `business_review_log`: append-only history of every status change of a
--     listing (who, when, from/to, reason). Written only by a trigger, so a
--     decision cannot be taken without leaving a record, whatever the client
--     does (REST, SQL editor as end user...). Reviewers read all of it; an
--     owner reads the history of their own listings; nobody can write it.
--   * decision rules for reviewers (trigger `enforce_business_status_change`):
--       - rejecting or withdrawing a listing requires a non-blank reason, kept
--         in `rejection_reason` so the owner sees it (OUR-112 panel);
--       - a reviewer cannot approve or reject a listing they own;
--       - approving or re-opening clears any previous reason.
--   * an owner's own withdrawal clears the reason (no stale reviewer text).
-- Service role / database owner (no end-user session) stays unrestricted.
-- Idempotent. Test with docs/sql/tests/2026-11-07_business_review_decisions_test.sql.

begin;

create table if not exists public.business_review_log (
  id bigint generated always as identity primary key,
  business_id uuid not null references public.businesses(business_id) on delete cascade,
  -- Who made the change; null when it came from the service role or when the
  -- account was deleted afterwards.
  actor_id uuid references auth.users(id) on delete set null,
  actor_role text not null check (actor_role in ('reviewer', 'owner', 'system')),
  from_status public.business_status,
  to_status public.business_status not null,
  reason text,
  created_at timestamptz not null default now()
);
create index if not exists business_review_log_business_idx
  on public.business_review_log (business_id, created_at desc);

alter table public.business_review_log enable row level security;
revoke all on public.business_review_log from anon, authenticated;
grant select on public.business_review_log to authenticated;

drop policy if exists business_review_log_select_reviewer on public.business_review_log;
create policy business_review_log_select_reviewer on public.business_review_log
  for select to authenticated using (public.is_reviewer());
drop policy if exists business_review_log_select_owner on public.business_review_log;
create policy business_review_log_select_owner on public.business_review_log
  for select to authenticated using (exists (
    select 1 from public.businesses b
    where b.business_id = business_review_log.business_id
      and b.owner_id = (select auth.uid())));

-- Validation (BEFORE UPDATE). Same as OUR-112 plus the reviewer rules.
create or replace function public.enforce_business_status_change()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  privileged boolean := auth.uid() is null or public.is_reviewer();
  public_data_changed boolean;
begin
  if privileged then
    if new.status is distinct from old.status then
      -- An end-user reviewer (not the service role) follows the moderation rules.
      if auth.uid() is not null then
        if new.status in ('approved', 'rejected')
           and old.owner_id is not distinct from auth.uid() then
          raise exception 'reviewers cannot decide their own listing'
            using errcode = '42501';
        end if;
        if new.status in ('rejected', 'withdrawn') then
          new.rejection_reason := nullif(btrim(new.rejection_reason), '');
          if new.rejection_reason is null then
            raise exception 'a reason is required to reject or withdraw a listing'
              using errcode = '23514';
          end if;
        end if;
      end if;

      -- Every moderation decision (including a withdrawal) is dated.
      if new.status in ('approved', 'rejected', 'withdrawn') then
        new.reviewed_at := now();
      elsif new.status = 'pending' then
        new.submitted_at := now();
      end if;
      -- Only a rejection or a withdrawal carries a reason.
      if new.status in ('approved', 'pending')
         or (new.status = 'withdrawn' and auth.uid() is null
             and new.rejection_reason is not distinct from old.rejection_reason) then
        new.rejection_reason := null;
      end if;
    end if;
    return new;
  end if;

  -- Owner (or any other end user allowed by RLS): decision fields are read-only.
  new.rejection_reason := old.rejection_reason;
  new.reviewed_at := old.reviewed_at;
  new.submitted_at := old.submitted_at;

  if new.status is distinct from old.status then
    if old.owner_id is distinct from auth.uid()
       or new.status not in ('withdrawn', 'pending') then
      raise exception 'business status change not allowed' using errcode = '42501';
    end if;
    -- Owner moves: withdraw, or (re)submit for review. Neither keeps a reason.
    new.rejection_reason := null;
    if new.status = 'pending' then
      new.submitted_at := now();
    end if;
    return new;
  end if;

  -- S0: public data edited on an approved listing -> back to review.
  if old.status = 'approved' then
    public_data_changed :=
      new.name is distinct from old.name
      or new.description is distinct from old.description
      or new.type is distinct from old.type
      or new.address is distinct from old.address
      or new.latitude is distinct from old.latitude
      or new.longitude is distinct from old.longitude
      or new.images is distinct from old.images;
    if public_data_changed then
      new.status := 'pending';
      new.submitted_at := now();
      new.rejection_reason := null;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists businesses_enforce_status_change on public.businesses;
create trigger businesses_enforce_status_change
  before update on public.businesses
  for each row execute function public.enforce_business_status_change();

-- Log (AFTER INSERT / UPDATE; ignores updates that keep the status). Runs after validation, so it records
-- the final status, including the S0 return to review.
create or replace function public.log_business_status_change()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  role_name text;
begin
  if tg_op = 'UPDATE' and new.status is not distinct from old.status then
    return new;
  end if;
  role_name := case
    when auth.uid() is null then 'system'
    when public.is_reviewer() then 'reviewer'
    else 'owner'
  end;
  insert into public.business_review_log
    (business_id, actor_id, actor_role, from_status, to_status, reason)
  values (
    new.business_id,
    auth.uid(),
    role_name,
    case when tg_op = 'UPDATE' then old.status end,
    new.status,
    case when new.status in ('rejected', 'withdrawn') then new.rejection_reason end
  );
  return new;
end;
$$;

drop trigger if exists businesses_log_status_change on public.businesses;
create trigger businesses_log_status_change
  after insert or update on public.businesses
  for each row execute function public.log_business_status_change();

commit;
