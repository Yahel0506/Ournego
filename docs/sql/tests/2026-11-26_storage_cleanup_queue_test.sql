-- Tests for the business storage cleanup queue.
-- Run after 2026-11-26_storage_cleanup_queue.sql. Everything is rolled back; a
-- failing check raises an exception that starts with FAIL.

begin;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', 'owner-d@test.invalid');

insert into public.businesses (business_id, owner_id, name, images) values
  ('00000000-0000-0000-0000-00000000d0b1', '00000000-0000-0000-0000-0000000000d1', 'D shop',
   array['https://x.supabase.co/storage/v1/object/public/businesses_pictures/legacy-folder/old%20photo.jpg']),
  ('00000000-0000-0000-0000-00000000d0b2', '00000000-0000-0000-0000-0000000000d1', 'D keep', '{}');

insert into storage.objects (bucket_id, name, owner_id) values
  ('businesses_pictures', '00000000-0000-0000-0000-00000000d0b1/11111111-1111-1111-1111-111111111111.webp', '00000000-0000-0000-0000-0000000000d1'),
  ('businesses_pictures', '00000000-0000-0000-0000-00000000d0b1/legacy.jpg', '00000000-0000-0000-0000-0000000000d1'),
  ('businesses_pictures', '00000000-0000-0000-0000-00000000d0b2/keep.webp', '00000000-0000-0000-0000-0000000000d1');

-- Nothing is queued while the business exists.
do $$ begin
  if exists (select 1 from public.storage_cleanup_queue) then
    raise exception 'FAIL: queue not empty before any delete';
  end if;
end $$;

delete from public.businesses where business_id = '00000000-0000-0000-0000-00000000d0b1';

-- Folder objects and the URL-referenced legacy photo are queued; the other
-- business is untouched.
do $$ declare n integer; begin
  select count(*) into n from public.storage_cleanup_queue
  where bucket = 'businesses_pictures' and processed_at is null;
  if n <> 3 then raise exception 'FAIL: expected 3 queued paths, got %', n; end if;
  if not exists (select 1 from public.storage_cleanup_queue
                 where path = 'legacy-folder/old photo.jpg') then
    raise exception 'FAIL: URL-referenced photo not queued (or not decoded)';
  end if;
  if exists (select 1 from public.storage_cleanup_queue
             where path like '00000000-0000-0000-0000-00000000d0b2/%') then
    raise exception 'FAIL: photo of another business queued';
  end if;
end $$;

-- Not callable by clients.
set local role authenticated;
do $$ begin
  begin
    perform * from public.claim_storage_cleanup(10);
    raise exception 'FAIL: authenticated can claim cleanup rows';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.complete_storage_cleanup(array[1]::bigint[]);
    raise exception 'FAIL: authenticated can complete cleanup rows';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- The service role claims and completes them.
set local role service_role;
do $$ declare ids bigint[]; done integer; begin
  select array_agg(id) into ids from public.claim_storage_cleanup(100);
  if coalesce(array_length(ids, 1), 0) <> 3 then
    raise exception 'FAIL: claim should return 3 rows';
  end if;
  done := public.complete_storage_cleanup(ids);
  if done <> 3 then raise exception 'FAIL: expected 3 completed, got %', done; end if;
  if exists (select 1 from public.claim_storage_cleanup(100)) then
    raise exception 'FAIL: completed rows are claimed again';
  end if;
end $$;
reset role;

rollback;
select 'OK: storage cleanup queue' as result;
