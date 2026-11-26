-- OUR-165 community confirmation ("¿Conoces este negocio?").
-- Apply after the two 2026-11-19 trust migrations (needs private.trust_settings,
-- private.request_actor and private.has_complete_profile).
--
-- * One row per (business, user). The only write path is
--   public.submit_business_confirmation (security definer); clients get no
--   insert/update/delete grant.
-- * Users can read only their own row, and not the `counted` column, so the UI
--   cannot reveal the validity rule.
-- * `counted` is computed on the server from private.trust_settings
--   (voter_min_age, voter_daily_limit).
-- * A counted `no_exists` answer is what the reports phase reads as a report
--   with reason "no existe" (see the partial index below).
begin;

create table if not exists public.business_confirmations (
  business_id uuid not null references public.businesses(business_id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  answer text not null check (answer in ('yes', 'no_exists', 'unsure')),
  counted boolean not null default false,
  created_at timestamptz not null default now(),
  constraint business_confirmations_unique unique (business_id, user_id)
);

-- Daily cap lookups and the reports phase ("no existe" signal).
create index if not exists business_confirmations_user_day_idx
  on public.business_confirmations (user_id, created_at desc);
create index if not exists business_confirmations_no_exists_idx
  on public.business_confirmations (business_id)
  where answer = 'no_exists' and counted;

alter table public.business_confirmations enable row level security;
revoke all on public.business_confirmations from public, anon, authenticated;
-- `counted` is deliberately not readable by clients.
grant select (business_id, answer, created_at)
  on public.business_confirmations to authenticated;

drop policy if exists business_confirmations_select_own on public.business_confirmations;
create policy business_confirmations_select_own
  on public.business_confirmations for select to authenticated
  using (user_id = auth.uid());

create or replace function public.submit_business_confirmation(
  p_business_id uuid,
  p_answer text
) returns jsonb language plpgsql volatile security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor uuid := private.request_actor();
  cfg private.trust_settings%rowtype;
  biz public.businesses%rowtype;
  existing text;
  account_created timestamptz;
  day_start timestamptz :=
    date_trunc('day', now() at time zone 'America/Mexico_City') at time zone 'America/Mexico_City';
  answered_today integer;
  is_counted boolean;
begin
  if actor is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  if p_business_id is null or p_answer is null
     or p_answer not in ('yes', 'no_exists', 'unsure') then
    raise exception 'invalid_answer' using errcode = '22023';
  end if;

  select * into biz from public.businesses
   where business_id = p_business_id and status = 'approved' and is_active is not false;
  if not found then raise exception 'business_not_found' using errcode = 'P0002'; end if;

  -- Serialise one user's answers so the daily cap cannot be raced.
  perform pg_advisory_xact_lock(hashtextextended('confirmation-user:' || actor::text, 165));

  -- Idempotent: the first answer wins and is never changed.
  select answer into existing from public.business_confirmations
   where business_id = p_business_id and user_id = actor;
  if found then
    return jsonb_build_object('business_id', p_business_id, 'answer', existing);
  end if;

  select * into strict cfg from private.trust_settings where singleton;
  select created_at into account_created from auth.users where id = actor;
  select count(*) into answered_today from public.business_confirmations
   where user_id = actor and created_at >= day_start;

  -- Invalid accounts may answer, but their answer never counts.
  is_counted := biz.owner_id is distinct from actor
    and private.has_complete_profile(actor)
    and account_created is not null
    and now() - account_created >= cfg.voter_min_age
    and answered_today < cfg.voter_daily_limit;

  insert into public.business_confirmations(business_id, user_id, answer, counted)
  values (p_business_id, actor, p_answer, is_counted);

  -- `counted` is never returned: the client must not learn the rule.
  return jsonb_build_object('business_id', p_business_id, 'answer', p_answer);
end $$;
revoke all on function public.submit_business_confirmation(uuid, text) from public, anon;
grant execute on function public.submit_business_confirmation(uuid, text) to authenticated;

commit;
