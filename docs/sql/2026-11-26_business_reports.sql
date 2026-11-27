-- OUR-166 business reports and automatic hiding (phase F5 of the community
-- verification plan). Apply after 2026-11-25_business_confirmations.sql.
--
-- * `business_reports`: one row per report. The only write path is
--   public.submit_business_report (security definer); clients get no
--   insert/update/delete grant and cannot read the `counted` column, so the
--   UI never reveals the validity rule.
-- * One open report per (business, user). After moderation resolves it the
--   user may report the same business again.
-- * A reporter is valid under the same rule as a confirmation voter: not the
--   owner, complete profile and an account older than trust_settings.voter_min_age.
--   Invalid accounts can report, but their report never counts.
-- * Only `no_exists` and `inappropriate` can hide a listing: when
--   trust_settings.report_threshold distinct valid reporters fall inside
--   trust_settings.report_window, an `approved` listing moves to `under_review`
--   and loses its verified mark. A counted `no_exists` community confirmation
--   counts as a `no_exists` report. Signals older than the last restoration
--   of the listing never count again.
-- * The other reasons stay `open` for moderation and for the owner's panel.
-- * Reports stay `open` while the listing is hidden; resolving them belongs
--   to the moderation phase.
begin;

-- The hide transition runs from a security definer function, so the status
-- guard must accept exactly that move (approved -> under_review, touching only
-- status and verified_at) when it comes from the function owner, never from a
-- client role. The rest of the function is unchanged from
-- 2026-11-19_business_trust_submission.sql.

create or replace function private.enforce_listing_trust()
returns trigger language plpgsql set search_path = pg_catalog, public, private, auth
as $$
declare
  uid uuid := private.request_actor();
  caller text := current_user;
  reason text;
  was_reviewer boolean;
  identity_changed boolean;
  image_changed boolean;
  payload jsonb;
  image_url text;
  origin_prefix text;
begin
  if tg_op='INSERT' then
    if caller='ournego_listing_submitter' then
      if new.owner_id is distinct from uid or new.status not in ('approved','pending') then
        raise exception 'invalid_listing' using errcode='42501';
      end if;
      perform private.validate_listing_basics(jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number));
      if new.status='approved' and not private.has_valid_listing_image(new.images,new.owner_id,true) then
        raise exception 'invalid_listing' using errcode='23514';
      end if;
      new.published_at:=case when new.status='approved' then coalesce(new.published_at,now()) end;
      new.pending_issue_code:=case when new.status='pending' then new.pending_issue_code end;
    elsif uid is not null then
      if not private.has_complete_profile(uid) then raise exception 'profile_required' using errcode='42501'; end if;
      if new.owner_id is distinct from uid or new.status<>'pending'
         or new.published_at is not null or new.verified_at is not null
         or new.verification_paused or new.pending_issue_code is not null then
        raise exception 'invalid_listing' using errcode='42501';
      end if;
      payload:=jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number);
      perform private.validate_listing_basics(payload);
      new.status:='pending';
      new.created_at:=now();
      new.pending_issue_code:='legacy';
    end if;
    return new;
  end if;

  if uid is null then return new; end if;
  -- OUR-166: automatic hiding by reports, issued by public.submit_business_report
  -- and private.evaluate_report_hiding (security definer, owned by postgres).
  if caller='postgres' and old.status='approved' and new.status='under_review'
     and (to_jsonb(new)-'status'-'verified_at') is not distinct from (to_jsonb(old)-'status'-'verified_at') then
    return new;
  end if;
  was_reviewer:=old.owner_id is distinct from uid and public.is_reviewer();
  if old.owner_id is distinct from uid and not was_reviewer then
    raise exception 'business status change not allowed' using errcode='42501';
  end if;

  if was_reviewer and new.status is distinct from old.status then
    if (old.status,new.status) not in (('pending','approved'),('pending','rejected'),('approved','withdrawn'),('under_review','approved'),('under_review','withdrawn')) then
      raise exception 'invalid_business_transition' using errcode='42501';
    end if;
    if new.status in ('rejected','withdrawn') and nullif(btrim(new.rejection_reason),'') is null then
      raise exception 'invalid_listing' using errcode='23514';
    end if;
    if (to_jsonb(new)-'status'-'rejection_reason') is distinct from (to_jsonb(old)-'status'-'rejection_reason') then
      raise exception 'reviewer_status_only' using errcode='42501';
    end if;
    if new.status='approved' then
      payload:=jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number);
      perform private.validate_listing_basics(payload);
      if old.status='pending' and not private.has_valid_listing_image(new.images,old.owner_id,true) then
        raise exception 'invalid_listing' using errcode='23514';
      end if;
      new.rejection_reason:=null;
      new.pending_issue_code:=null;
      new.published_at:=coalesce(old.published_at,now());
    elsif new.status in ('rejected','withdrawn') then
      new.pending_issue_code:=null;
    end if;
    new.reviewed_at:=now();
    return new;
  end if;

  if old.owner_id is distinct from uid then raise exception 'business status change not allowed' using errcode='42501'; end if;

  -- Owner-controlled writes cannot alter identity, lifecycle, activity, or trust metadata.
  new.business_id:=old.business_id;
  new.owner_id:=old.owner_id;
  new.created_at:=old.created_at;
  new.is_active:=old.is_active;
  new.reviewed_at:=old.reviewed_at;
  new.submitted_at:=old.submitted_at;
  new.published_at:=old.published_at;
  new.verified_at:=old.verified_at;
  new.verification_paused:=old.verification_paused;
  new.pending_issue_code:=old.pending_issue_code;

  identity_changed:=new.name is distinct from old.name or new.type is distinct from old.type or new.address is distinct from old.address or new.latitude is distinct from old.latitude or new.longitude is distinct from old.longitude;
  image_changed:=new.images is distinct from old.images;
  if identity_changed then new.verified_at:=null; end if;

  if new.status is distinct from old.status then
    if new.status='withdrawn' and old.status<>'under_review' then new.rejection_reason:=null; return new; end if;
    if new.status='pending' and old.status in ('rejected','withdrawn') then
      payload:=jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number);
      perform private.validate_listing_basics(payload);
      if not private.has_valid_listing_image(new.images,uid,true) then raise exception 'invalid_listing' using errcode='23514'; end if;
      perform private.ensure_owner_active_capacity(uid,old.business_id);
      new.rejection_reason:=null;
      new.pending_issue_code:='legacy';
      new.submitted_at:=now();
      return new;
    end if;
    raise exception 'business status change not allowed' using errcode='42501';
  end if;

  payload:=jsonb_build_object('name',new.name,'type',new.type,'address',new.address,'latitude',new.latitude,'longitude',new.longitude,'phone_number',new.phone_number);
  if new.name is distinct from old.name or new.description is distinct from old.description or new.type is distinct from old.type or new.address is distinct from old.address or new.latitude is distinct from old.latitude or new.longitude is distinct from old.longitude or new.phone_number is distinct from old.phone_number or image_changed then
    perform private.validate_listing_basics(payload);
  end if;
  if image_changed and not private.has_valid_listing_image(new.images,uid,true) then
    raise exception 'invalid_listing' using errcode='23514';
  end if;

  -- Public edits to an approved listing can send it back to review, never republish a hidden row.
  if old.status='approved' and (new.name is distinct from old.name or new.description is distinct from old.description or new.type is distinct from old.type or new.address is distinct from old.address or new.latitude is distinct from old.latitude or new.longitude is distinct from old.longitude or new.phone_number is distinct from old.phone_number or image_changed) then
    reason:=private.listing_review_reason(new.name,concat_ws(' ',new.description,new.address),new.phone_number,new.latitude,new.longitude,new.business_id,new.owner_id);
    if reason is not null then new.status:='pending'; new.submitted_at:=now(); new.pending_issue_code:=reason; new.rejection_reason:=null; end if;
  end if;
  return new;
end $$;

create or replace function private.log_trust_status_change()
returns trigger language plpgsql security definer set search_path = pg_catalog, public, auth
as $$
declare actor text;
begin
  if tg_op='UPDATE' and new.status is not distinct from old.status then return new; end if;
  actor:=case when auth.uid() is null then 'system' when tg_op='INSERT' and new.status='approved' and new.published_at is not null then 'system' when tg_op='UPDATE' and old.status='approved' and new.status='pending' and new.pending_issue_code is not null then 'system' when tg_op='UPDATE' and old.status='approved' and new.status='under_review' then 'system' when public.is_reviewer() and old.owner_id is distinct from auth.uid() then 'reviewer' else 'owner' end;
  insert into public.business_review_log(business_id,actor_id,actor_role,from_status,to_status,reason)
  values(new.business_id,case when actor='system' then null else auth.uid() end,actor,case when tg_op='UPDATE' then old.status end,new.status,
    case when new.status in ('rejected','withdrawn') then new.rejection_reason when new.status='pending' then new.pending_issue_code when new.status='under_review' then 'reports' end);
  return new;
end $$;

create table if not exists public.business_reports (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(business_id) on delete cascade,
  reporter_id uuid not null references auth.users(id) on delete cascade,
  reason text not null check (reason in ('no_exists','closed','incorrect_info','inappropriate','duplicate','other')),
  note text check (note is null or char_length(note) <= 500),
  status text not null default 'open' check (status in ('open','dismissed','upheld')),
  counted boolean not null default false,
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by uuid references auth.users(id) on delete set null,
  constraint business_reports_other_needs_note
    check (reason <> 'other' or nullif(btrim(note),'') is not null)
);

-- One open report per user and listing.
create unique index if not exists business_reports_one_open_idx
  on public.business_reports (business_id, reporter_id) where status = 'open';
create index if not exists business_reports_signal_idx
  on public.business_reports (business_id, reason, created_at desc)
  where status = 'open' and counted;
create index if not exists business_reports_user_day_idx
  on public.business_reports (reporter_id, created_at desc);

alter table public.business_reports enable row level security;
revoke all on public.business_reports from public, anon, authenticated;
-- `counted` is deliberately not readable by clients.
grant select (id, business_id, reporter_id, reason, note, status, created_at, resolved_at)
  on public.business_reports to authenticated;

drop policy if exists business_reports_select_own on public.business_reports;
create policy business_reports_select_own
  on public.business_reports for select to authenticated
  using (reporter_id = (select auth.uid()));
drop policy if exists business_reports_select_reviewer on public.business_reports;
create policy business_reports_select_reviewer
  on public.business_reports for select to authenticated
  using (public.is_reviewer());

-- Hides an approved listing when enough distinct valid reporters point at a
-- hiding reason. Callers must hold the per-business advisory lock.
create or replace function private.evaluate_report_hiding(p_business_id uuid)
returns boolean language plpgsql volatile security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  cfg private.trust_settings%rowtype;
  since timestamptz;
  hide_reason text;
  reporters integer;
begin
  select * into strict cfg from private.trust_settings where singleton;
  if not exists (select 1 from public.businesses
                  where business_id = p_business_id and status = 'approved' and is_active is not false) then
    return false;
  end if;

  -- Signals from before the last restoration were already judged by moderation.
  since := greatest(
    now() - cfg.report_window,
    coalesce((select max(created_at) from public.business_review_log
               where business_id = p_business_id
                 and from_status = 'under_review' and to_status = 'approved'), '-infinity'::timestamptz));

  foreach hide_reason in array array['no_exists','inappropriate'] loop
    select count(*) into reporters from (
      select reporter_id as uid from public.business_reports
       where business_id = p_business_id and reason = hide_reason
         and status = 'open' and counted and created_at >= since
      union
      select user_id from public.business_confirmations
       where hide_reason = 'no_exists' and business_id = p_business_id
         and answer = 'no_exists' and counted and created_at >= since
    ) s;
    if reporters >= cfg.report_threshold then
      update public.businesses set status = 'under_review', verified_at = null
       where business_id = p_business_id and status = 'approved';
      return true;
    end if;
  end loop;
  return false;
end $$;
revoke all on function private.evaluate_report_hiding(uuid) from public, anon, authenticated;

create or replace function public.submit_business_report(
  p_business_id uuid,
  p_reason text,
  p_note text default null
) returns jsonb language plpgsql volatile security definer
set search_path = pg_catalog, public, private, auth
as $$
declare
  actor uuid := private.request_actor();
  cfg private.trust_settings%rowtype;
  biz public.businesses%rowtype;
  note text := nullif(btrim(p_note), '');
  existing text;
  account_created timestamptz;
  day_start timestamptz :=
    date_trunc('day', now() at time zone 'America/Mexico_City') at time zone 'America/Mexico_City';
  reported_today integer;
  is_counted boolean;
begin
  if actor is null then raise exception 'not_authenticated' using errcode = '42501'; end if;
  if p_business_id is null or p_reason is null
     or p_reason not in ('no_exists','closed','incorrect_info','inappropriate','duplicate','other')
     or (p_reason = 'other' and note is null)
     or char_length(coalesce(note, '')) > 500 then
    raise exception 'invalid_report' using errcode = '22023';
  end if;

  select * into biz from public.businesses
   where business_id = p_business_id and status = 'approved' and is_active is not false;
  if not found then raise exception 'business_not_found' using errcode = 'P0002'; end if;
  if biz.owner_id is not distinct from actor then
    raise exception 'owner_cannot_report' using errcode = '42501';
  end if;

  -- Serialise one user's reports (daily cap) and then one business's signals.
  perform pg_advisory_xact_lock(hashtextextended('report-user:' || actor::text, 166));
  perform pg_advisory_xact_lock(hashtextextended('report-business:' || p_business_id::text, 166));

  -- Idempotent: an open report is kept as it is.
  select reason into existing from public.business_reports
   where business_id = p_business_id and reporter_id = actor and status = 'open';
  if found then
    return jsonb_build_object('business_id', p_business_id, 'reason', existing);
  end if;

  select * into strict cfg from private.trust_settings where singleton;
  select count(*) into reported_today from public.business_reports
   where reporter_id = actor and created_at >= day_start;
  if reported_today >= cfg.report_daily_limit then
    raise exception 'report_limit_reached' using errcode = 'P0001';
  end if;

  select created_at into account_created from auth.users where id = actor;
  is_counted := private.has_complete_profile(actor)
    and account_created is not null
    and now() - account_created >= cfg.voter_min_age;

  insert into public.business_reports(business_id, reporter_id, reason, note, counted)
  values (p_business_id, actor, p_reason, note, is_counted);

  if is_counted and p_reason in ('no_exists','inappropriate') then
    perform private.evaluate_report_hiding(p_business_id);
  end if;

  -- Neither `counted` nor the hiding outcome is returned: the client must not
  -- learn the rule or the state of the internal process.
  return jsonb_build_object('business_id', p_business_id, 'reason', p_reason);
end $$;
revoke all on function public.submit_business_report(uuid, text, text) from public, anon;
grant execute on function public.submit_business_report(uuid, text, text) to authenticated;

-- Owner's panel notice: how many reports of any reason are still open. Only an
-- aggregate; reporters and notes are never exposed to the owner.
create or replace function public.get_business_open_report_count(p_business_id uuid)
returns integer language plpgsql stable security definer
set search_path = pg_catalog, public, private
as $$
declare actor uuid := private.request_actor();
begin
  if actor is null or not exists (
       select 1 from public.businesses b where b.business_id = p_business_id and b.owner_id = actor) then
    raise exception 'not_owner' using errcode = '42501';
  end if;
  return (select count(*)::integer from public.business_reports
           where business_id = p_business_id and status = 'open');
end $$;
revoke all on function public.get_business_open_report_count(uuid) from public, anon;
grant execute on function public.get_business_open_report_count(uuid) to authenticated;

-- A counted `no_exists` community answer is a `no_exists` report: evaluate the
-- hiding rule right after it. Same function as 2026-11-25_business_confirmations.sql
-- plus the business lock and the final evaluation.
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

  if is_counted and p_answer = 'no_exists' then
    perform pg_advisory_xact_lock(hashtextextended('report-business:' || p_business_id::text, 166));
    perform private.evaluate_report_hiding(p_business_id);
  end if;

  -- `counted` is never returned: the client must not learn the rule.
  return jsonb_build_object('business_id', p_business_id, 'answer', p_answer);
end $$;
revoke all on function public.submit_business_confirmation(uuid, text) from public, anon;
grant execute on function public.submit_business_confirmation(uuid, text) to authenticated;

commit;
