-- OUR-152 - Execution of the account deletion (SQL side)
-- Plan: docs/development/plans/our-142-account-deletion.md (D1, D2, D3, D6, D8)
--
-- Both functions are only callable with the service role (the Edge Function
-- `execute-account-deletion`). Requires 2026-10-20_account_deletion_requests.sql.

-- Storage objects that belong to a user. The Edge Function deletes them through
-- the Storage API BEFORE calling delete_user_data(), because deleting rows from
-- storage.objects does not remove the underlying files.
--   profile_pictures      <uid><ext>                       (name derived from the uid)
--   businesses_pictures   <business_id>/<file>, and any URL kept in businesses.images
--   feedback_attachments  public URL stored in feedback.attachment
create or replace function public.account_deletion_storage_paths(uid uuid)
returns table (bucket text, path text)
language sql
stable
security definer
set search_path = ''
as $$
  select o.bucket_id, o.name
  from storage.objects o
  where o.bucket_id = 'profile_pictures'
    and o.name ~ ('^' || uid::text || '\.[^/]+$')

  union

  select o.bucket_id, o.name
  from storage.objects o
  join public.businesses b on b.owner_id = uid
  where o.bucket_id = 'businesses_pictures'
    and o.name like (b.business_id::text || '/%')

  union

  -- Images referenced by URL, in case the folder is not the business id.
  select 'businesses_pictures', substring(img from '/businesses_pictures/(.+)$')
  from public.businesses b, unnest(b.images) as img
  where b.owner_id = uid
    and img ~ '/businesses_pictures/.+'

  union

  select 'feedback_attachments',
         substring(f.attachment from '/feedback_attachments/(.+)$')
  from public.feedback f
  where f.user_id = uid
    and f.attachment ~ '/feedback_attachments/.+'
$$;

revoke all on function public.account_deletion_storage_paths(uuid)
  from public, anon, authenticated;
grant execute on function public.account_deletion_storage_paths(uuid)
  to service_role;

-- Deletes the user's rows in one transaction (a function body is atomic).
-- Idempotent: running it again on an already-clean user does nothing.
-- It does not delete the auth user or the Storage files; the Edge Function does.
create or replace function public.delete_user_data(uid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  user_email text;
  affected uuid[];
begin
  if uid is null then
    raise exception 'uid is required' using errcode = '22023';
  end if;

  select lower(btrim(u.email)) into user_email
  from auth.users u
  where u.id = uid;

  -- Reviews on businesses of other owners: remember them to recompute.
  select coalesce(array_agg(distinct r.business_id), '{}') into affected
  from public.reviews r
  where r.user_id = uid
    and r.business_id not in (
      select b.business_id from public.businesses b where b.owner_id = uid
    );

  delete from public.reviews where user_id = uid;

  -- No trigger maintains these columns, so recompute them here.
  update public.businesses b
  set average_rating = coalesce(
        (select round(avg(r.rating)::numeric, 2)
         from public.reviews r where r.business_id = b.business_id), 0),
      total_reviews = (
        select count(*) from public.reviews r where r.business_id = b.business_id)
  where b.business_id = any (affected);

  delete from public.feedback where user_id = uid;
  delete from public.user_interactions where user_id = uid;

  -- businesses_views.business_id is NO ACTION: clear views of the user's
  -- businesses (from anyone) before deleting them.
  delete from public.businesses_views
  where business_id in (
    select b.business_id from public.businesses b where b.owner_id = uid
  );
  delete from public.businesses_views where user_id = uid;

  -- Schedules, products, exceptions, favorites, interactions and the reviews
  -- of third parties cascade from businesses.
  delete from public.businesses where owner_id = uid;

  delete from public.user_favorites where user_id = uid;

  if user_email is not null and user_email <> '' then
    delete from public.beta where lower(btrim(email)) = user_email;
  end if;

  -- public.users goes away with auth.users (CASCADE); the Edge Function
  -- deletes the auth user as its last step.
end;
$$;

revoke all on function public.delete_user_data(uuid)
  from public, anon, authenticated;
grant execute on function public.delete_user_data(uuid) to service_role;
