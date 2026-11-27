-- Storage cleanup for deleted businesses (image upload optimisation).
--
-- Deleting a row from storage.objects with SQL does NOT remove the file, so a
-- trigger cannot delete files by itself. Instead, deleting a business enqueues
-- the paths of its photos here, and the Edge Function `purge-storage-queue`
-- (service role) removes them through the Storage API and marks them done.
-- Account deletion keeps its own, synchronous flow (execute-account-deletion);
-- the queue only catches business rows deleted by any other route (admin
-- console, SQL, future "delete business" feature).
--
-- Photo names: businesses_pictures/<business_id>/<uuid>.webp. Photos uploaded
-- before WebP live under the same folder with other names; both are covered by
-- the folder match and by the URLs kept in businesses.images.

create table if not exists public.storage_cleanup_queue (
  id           bigserial primary key,
  bucket       text not null,
  path         text not null,
  created_at   timestamptz not null default now(),
  processed_at timestamptz,
  unique (bucket, path)
);
alter table public.storage_cleanup_queue enable row level security;
revoke all on public.storage_cleanup_queue from public, anon, authenticated;
grant select, insert, update, delete on public.storage_cleanup_queue to service_role;
grant usage, select on sequence public.storage_cleanup_queue_id_seq to service_role;

create index if not exists storage_cleanup_queue_pending_idx
  on public.storage_cleanup_queue (id) where processed_at is null;

create schema if not exists private;

-- AFTER DELETE on businesses: queue every photo of the business.
create or replace function private.enqueue_business_storage_cleanup()
returns trigger
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
begin
  insert into public.storage_cleanup_queue (bucket, path)
  select 'businesses_pictures', o.name
  from storage.objects o
  where o.bucket_id = 'businesses_pictures'
    and o.name like (old.business_id::text || '/%')
  union
  -- Photos referenced by URL, in case the folder is not the business id.
  select 'businesses_pictures',
         replace(substring(img from '/businesses_pictures/(.+)$'), '%20', ' ')
  from unnest(coalesce(old.images, '{}')) as img
  where img ~ '/businesses_pictures/.+'
  on conflict (bucket, path) do update set processed_at = null;
  return old;
end;
$$;
revoke all on function private.enqueue_business_storage_cleanup()
  from public, anon, authenticated;

drop trigger if exists businesses_enqueue_storage_cleanup on public.businesses;
create trigger businesses_enqueue_storage_cleanup
  after delete on public.businesses
  for each row execute function private.enqueue_business_storage_cleanup();

-- Hands the Edge Function a batch of pending files.
create or replace function public.claim_storage_cleanup(batch_size integer default 100)
returns table (id bigint, bucket text, path text)
language sql
security definer
set search_path = pg_catalog, public
as $$
  select q.id, q.bucket, q.path
  from public.storage_cleanup_queue q
  where q.processed_at is null
  order by q.id
  limit greatest(least(batch_size, 500), 1)
$$;

-- Marks files as removed (call after the Storage API confirmed it).
create or replace function public.complete_storage_cleanup(ids bigint[])
returns integer
language plpgsql
security definer
set search_path = pg_catalog, public
as $$
declare done integer;
begin
  update public.storage_cleanup_queue
  set processed_at = now()
  where id = any (ids) and processed_at is null;
  get diagnostics done = row_count;
  return done;
end;
$$;

revoke all on function public.claim_storage_cleanup(integer)
  from public, anon, authenticated;
revoke all on function public.complete_storage_cleanup(bigint[])
  from public, anon, authenticated;
grant execute on function public.claim_storage_cleanup(integer) to service_role;
grant execute on function public.complete_storage_cleanup(bigint[]) to service_role;
