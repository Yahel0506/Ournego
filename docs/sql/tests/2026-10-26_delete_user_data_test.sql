-- OUR-152 - Tests for public.delete_user_data() and
-- public.account_deletion_storage_paths().
-- Run after 2026-10-26_delete_user_data.sql. Everything is rolled back; a
-- failing check raises an exception that starts with FAIL.

begin;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-0000000000a1', 'authenticated', 'authenticated', '  Gone@Test.invalid '),
  ('00000000-0000-0000-0000-0000000000b1', 'authenticated', 'authenticated', 'owner-b@test.invalid'),
  ('00000000-0000-0000-0000-0000000000c1', 'authenticated', 'authenticated', 'viewer-c@test.invalid');

-- Business of A (with a third-party review and view) and of B.
insert into public.businesses (business_id, owner_id, name, images) values
  ('00000000-0000-0000-0000-00000000a0b1', '00000000-0000-0000-0000-0000000000a1', 'A shop',
   array['https://x.supabase.co/storage/v1/object/public/businesses_pictures/some-folder/a.jpg']),
  ('00000000-0000-0000-0000-00000000b0b1', '00000000-0000-0000-0000-0000000000b1', 'B shop', '{}');

-- B's business has reviews from A (to delete) and C (to keep).
insert into public.reviews (business_id, user_id, rating) values
  ('00000000-0000-0000-0000-00000000b0b1', '00000000-0000-0000-0000-0000000000a1', 1),
  ('00000000-0000-0000-0000-00000000b0b1', '00000000-0000-0000-0000-0000000000c1', 5),
  ('00000000-0000-0000-0000-00000000a0b1', '00000000-0000-0000-0000-0000000000c1', 4);
update public.businesses set average_rating = 3, total_reviews = 2
  where business_id = '00000000-0000-0000-0000-00000000b0b1';

-- C viewed A's business (blocks its deletion unless cleared first).
insert into public.businesses_views (business_id, user_id) values
  ('00000000-0000-0000-0000-00000000a0b1', '00000000-0000-0000-0000-0000000000c1'),
  ('00000000-0000-0000-0000-00000000b0b1', '00000000-0000-0000-0000-0000000000a1');

insert into public.user_favorites (user_id, business_id) values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-00000000b0b1'),
  ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-00000000b0b1');

insert into public.user_interactions (user_id, business_id, interaction_type, source) values
  ('00000000-0000-0000-0000-0000000000a1', '00000000-0000-0000-0000-00000000b0b1', 'open_contact', 'unknown'),
  ('00000000-0000-0000-0000-0000000000c1', '00000000-0000-0000-0000-00000000b0b1', 'open_contact', 'unknown');

insert into public.feedback (user_id, message, attachment) values
  ('00000000-0000-0000-0000-0000000000a1', 'bye',
   'https://x.supabase.co/storage/v1/object/public/feedback_attachments/feedback_1_abc.png'),
  ('00000000-0000-0000-0000-0000000000c1', 'keep', null);

insert into public.beta (email, message) values
  ('gone@test.invalid', 'beta of A'),
  ('other@test.invalid', 'beta of someone else');

-- Not callable by clients ----------------------------------------------------
set local role authenticated;
do $$ begin
  begin
    perform public.delete_user_data('00000000-0000-0000-0000-0000000000a1');
    raise exception 'FAIL: authenticated can call delete_user_data';
  exception when insufficient_privilege then null;
  end;
  begin
    perform * from public.account_deletion_storage_paths('00000000-0000-0000-0000-0000000000a1');
    raise exception 'FAIL: authenticated can call account_deletion_storage_paths';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- Storage paths (before the delete, as the Edge Function does) ----------------
do $$
declare
  paths text[];
begin
  select array_agg(bucket || ':' || path order by bucket, path) into paths
  from public.account_deletion_storage_paths('00000000-0000-0000-0000-0000000000a1');
  if paths is distinct from array[
       'businesses_pictures:some-folder/a.jpg',
       'feedback_attachments:feedback_1_abc.png'
     ] then
    raise exception 'FAIL: unexpected storage paths: %', paths;
  end if;
end $$;

-- Delete, twice (idempotent) ---------------------------------------------------
select public.delete_user_data('00000000-0000-0000-0000-0000000000a1');
select public.delete_user_data('00000000-0000-0000-0000-0000000000a1');

do $$
declare
  a constant uuid := '00000000-0000-0000-0000-0000000000a1';
begin
  if exists (select 1 from public.reviews where user_id = a)
     or exists (select 1 from public.feedback where user_id = a)
     or exists (select 1 from public.user_interactions where user_id = a)
     or exists (select 1 from public.businesses_views where user_id = a)
     or exists (select 1 from public.user_favorites where user_id = a)
     or exists (select 1 from public.businesses where owner_id = a)
     or exists (select 1 from public.beta where email = 'gone@test.invalid')
  then
    raise exception 'FAIL: data of the user remains';
  end if;

  if exists (select 1 from public.businesses_views
             where business_id = '00000000-0000-0000-0000-00000000a0b1') then
    raise exception 'FAIL: views of the deleted business remain';
  end if;

  -- Other people's data is untouched.
  if not exists (select 1 from public.feedback where message = 'keep')
     or not exists (select 1 from public.beta where email = 'other@test.invalid')
     or not exists (select 1 from public.user_favorites
                    where user_id = '00000000-0000-0000-0000-0000000000c1')
     or not exists (select 1 from public.user_interactions
                    where user_id = '00000000-0000-0000-0000-0000000000c1') then
    raise exception 'FAIL: data of other users was deleted';
  end if;

  -- B's rating is recomputed from the remaining review (5).
  if not exists (
    select 1 from public.businesses
    where business_id = '00000000-0000-0000-0000-00000000b0b1'
      and average_rating = 5 and total_reviews = 1
  ) then
    raise exception 'FAIL: rating of the other business not recomputed';
  end if;
end $$;

-- A business left without reviews goes back to 0 / 0.
select public.delete_user_data('00000000-0000-0000-0000-0000000000c1');
do $$ begin
  if not exists (
    select 1 from public.businesses
    where business_id = '00000000-0000-0000-0000-00000000b0b1'
      and average_rating = 0 and total_reviews = 0
  ) then
    raise exception 'FAIL: rating not reset when no reviews remain';
  end if;
end $$;

rollback;
