-- OUR-112 - Owner review requests and review result.
--
-- Builds on 2026-11-05_business_review_status.sql (OUR-111). Adds:
--   * `rejection_reason`, `submitted_at`, `reviewed_at` on `businesses`, so the
--     owner can see the result of a review and when it was requested/decided;
--   * the owner "request review" move: `rejected`/`withdrawn` -> `pending`;
--   * the S0 rule: when the owner changes public data of an `approved` listing
--     (name, description, category, address, coordinates, images) the
--     listing goes back to `pending` and leaves the public map until it is
--     approved again. Phone and hours are published without review.
-- Only reviewers (and the service role) can set `approved`/`rejected`, the
-- reason and `reviewed_at`; the owner cannot touch those fields.
-- Idempotent. Test with docs/sql/tests/2026-11-06_business_review_requests_test.sql.

begin;

alter table public.businesses
  add column if not exists rejection_reason text,
  add column if not exists submitted_at timestamptz,
  add column if not exists reviewed_at timestamptz;
-- Existing (approved) catalog keeps null; new rows record when they were sent.
alter table public.businesses alter column submitted_at set default now();

-- The owner cannot create a listing that already carries a decision.
drop policy if exists businesses_insert_owner on public.businesses;
create policy businesses_insert_owner on public.businesses
  for insert to authenticated
  with check (
    owner_id = (select auth.uid())
    and status = 'pending'
    and rejection_reason is null
    and reviewed_at is null
  );

create or replace function public.enforce_business_status_change()
returns trigger
language plpgsql security definer set search_path = public
as $$
declare
  privileged boolean := auth.uid() is null or public.is_reviewer();
  public_data_changed boolean;
begin
  if privileged then
    -- Moderation: stamp the decision time; a decision other than `rejected`
    -- carries no reason.
    if new.status is distinct from old.status then
      if new.status in ('approved', 'rejected') then
        new.reviewed_at := now();
      elsif new.status = 'pending' then
        new.submitted_at := now();
      end if;
      if new.status <> 'rejected'
         and new.rejection_reason is not distinct from old.rejection_reason then
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
    -- Owner moves: withdraw, or (re)submit for review.
    if old.owner_id is distinct from auth.uid()
       or new.status not in ('withdrawn', 'pending') then
      raise exception 'business status change not allowed' using errcode = '42501';
    end if;
    if new.status = 'pending' then
      new.submitted_at := now();
      new.rejection_reason := null;
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

-- Same trigger as OUR-111; recreated so the function above is the one in use.
drop trigger if exists businesses_enforce_status_change on public.businesses;
create trigger businesses_enforce_status_change
  before update on public.businesses
  for each row execute function public.enforce_business_status_change();

-- A new listing from an end user always records when it was sent (the owner
-- cannot backdate it to jump a review queue).
create or replace function public.stamp_business_submission()
returns trigger
language plpgsql security definer set search_path = public
as $$
begin
  if auth.uid() is not null and not public.is_reviewer() then
    new.submitted_at := now();
  end if;
  return new;
end;
$$;
drop trigger if exists businesses_stamp_submission on public.businesses;
create trigger businesses_stamp_submission
  before insert on public.businesses
  for each row execute function public.stamp_business_submission();

-- Pending listings created between OUR-111 and this migration have no date.
update public.businesses
set submitted_at = now()
where status = 'pending' and submitted_at is null;

commit;
