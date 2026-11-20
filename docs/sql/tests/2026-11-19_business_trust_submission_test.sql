-- OUR-164 / OUR-170 trust submission regression checks. Run after the two
-- 2026-11-19 migrations; all fixture data rolls back.
begin;
do $$ begin if has_schema_privilege('ournego_listing_submitter','auth','USAGE') then raise exception 'FAIL: submitter role was granted auth schema access'; end if; end $$;
insert into auth.users(id,aud,role,email) values
 ('00000000-0000-0000-0000-000000164001','authenticated','authenticated','owner@test.invalid'),
 ('00000000-0000-0000-0000-000000164002','authenticated','authenticated','other@test.invalid'),
 ('00000000-0000-0000-0000-000000164003','authenticated','authenticated','reviewer@test.invalid'),
 ('00000000-0000-0000-0000-000000164004','authenticated','authenticated','second-reviewer@test.invalid');
insert into public.users(id,has_profile,name) values
 ('00000000-0000-0000-0000-000000164001',true,'Test Owner'),
 ('00000000-0000-0000-0000-000000164002',true,'Other Owner'),
 ('00000000-0000-0000-0000-000000164003',true,'Reviewer Owner'),
 ('00000000-0000-0000-0000-000000164004',true,'Second Reviewer');
insert into public.reviewers(user_id) values ('00000000-0000-0000-0000-000000164003'),('00000000-0000-0000-0000-000000164004');
insert into storage.objects(bucket_id,name,owner,owner_id) values
 ('businesses_pictures','00000000-0000-0000-0000-000000164101/hero photo.jpg','00000000-0000-0000-0000-000000164001','00000000-0000-0000-0000-000000164001');
update private.trust_settings set storage_public_origin='https://test-project.supabase.co' where singleton;
update auth.users set created_at='2000-01-01 00:00:00+00' where id='00000000-0000-0000-0000-000000164001';
do $$ begin if (select business_daily_creation_limit<>3 or business_active_listing_limit<>10 from private.trust_settings where singleton) then raise exception 'FAIL: quota defaults changed'; end if; end $$;
grant insert (owner_id,name,status) on public.businesses to authenticated;

set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164001',true);
do $$ declare result jsonb; bid uuid := '00000000-0000-0000-0000-000000164101'; begin
  result:=public.submit_business_listing(jsonb_build_object(
    'business_id',bid,'name','Tienda de prueba','description','Servicio local','type',1,
    'address','Centro, Ciudad Guzmán','latitude',19.7086,'longitude',-103.4641,
    'phone_number','3411234567','image_object',bid::text||'/hero photo.jpg',
    'image_url','https://test-project.supabase.co/storage/v1/object/public/businesses_pictures/'||bid::text||'/hero%20photo.jpg'),
    '[{"day_of_week":1,"opening_time":"09:00","closing_time":"18:00"},{"day_of_week":7,"opening_time":"09:00","closing_time":"24:00"}]'::jsonb);
  if result->>'status' <> 'approved' or result->'review_pending_reason' <> 'null'::jsonb then raise exception 'FAIL: clean Ciudad Guzman listing did not publish: %',result; end if;
  result:=public.submit_business_listing(jsonb_build_object('business_id',bid), '[]'::jsonb);
  if result->>'status' <> 'approved' then raise exception 'FAIL: owner retry is not idempotent'; end if;
  begin
    perform public.submit_business_listing(jsonb_build_object('business_id',bid), '[]'::jsonb);
  exception when others then null; end;
end $$;
reset role;
do $$ begin
  if (select count(*) from public.business_hours where business_id='00000000-0000-0000-0000-000000164101') <> 2 then raise exception 'FAIL: hours were not committed with the listing'; end if;
  if (select published_at is null from public.businesses where business_id='00000000-0000-0000-0000-000000164101') then raise exception 'FAIL: publication timestamp missing'; end if;
  if not exists(select 1 from public.business_review_log where business_id='00000000-0000-0000-0000-000000164101' and actor_role='system' and actor_id is null and to_status='approved') then raise exception 'FAIL: automatic approval history is not attributed to system'; end if;
end $$;


select set_config('request.jwt.claim.sub','',true);
-- Grandfathered approved records with a historical blank image remain editable
-- when their image column is untouched.
insert into public.businesses(business_id,owner_id,name,type,address,latitude,longitude,images,status,verified_at,published_at)
values('00000000-0000-0000-0000-000000164103','00000000-0000-0000-0000-000000164002','Old approved listing',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now(),now());
grant update on public.businesses to authenticated;
grant select (business_id) on public.businesses to authenticated;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
update public.businesses set description='Updated details',phone_number='3410000001',verified_at=null,verification_paused=true where business_id='00000000-0000-0000-0000-000000164103';
reset role;
do $$ begin
  if (select status from public.businesses where business_id='00000000-0000-0000-0000-000000164103') <> 'approved' then raise exception 'FAIL: unchanged historical blank image blocked a valid edit'; end if;
  if (select verified_at is null or verification_paused from public.businesses where business_id='00000000-0000-0000-0000-000000164103') then raise exception 'FAIL: clean contact edit changed protected verification'; end if;
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
update public.businesses set name='Renamed Old Listing',verified_at=now() where business_id='00000000-0000-0000-0000-000000164103';
reset role;
do $$ begin if (select verified_at is not null from public.businesses where business_id='00000000-0000-0000-0000-000000164103') then raise exception 'FAIL: identity edit did not clear verification'; end if; end $$;

-- Profile completeness is required; the old account above proves there is no age threshold.
update public.users set has_profile=false where id='00000000-0000-0000-0000-000000164002';
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
do $$ declare denied boolean:=false; begin
  begin perform public.submit_business_listing('{}'::jsonb,'[]'::jsonb);
  exception when insufficient_privilege then denied:=sqlerrm='profile_required'; end;
  if not denied then raise exception 'FAIL: incomplete profile was accepted'; end if;
end $$;
reset role;
update public.users set has_profile=true where id='00000000-0000-0000-0000-000000164002';

update private.trust_settings set business_daily_creation_limit=2 where singleton;
-- A normal authenticated caller cannot insert an approved row directly.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
do $$ declare failed boolean:=false; begin
  begin
    insert into public.businesses(owner_id,name,status) values(auth.uid(),'forged','approved');
  exception when insufficient_privilege then failed:=true; end;
  if not failed then raise exception 'FAIL: direct approved insert succeeded'; end if;
  insert into public.businesses(owner_id,name,type,address,latitude,longitude,status) values(auth.uid(),'legacy incomplete',1,'Ciudad Guzmán',19.7086,-103.4641,'pending');
  insert into public.businesses(owner_id,name,type,address,latitude,longitude,status) values(auth.uid(),'legacy incomplete two',1,'Ciudad Guzmán',19.7086,-103.4641,'pending');
end $$;
reset role;
do $$ declare denied boolean:=false; begin
  if (select status from public.businesses where owner_id='00000000-0000-0000-0000-000000164002' and name='legacy incomplete') <> 'pending' then raise exception 'FAIL: legacy row not pending'; end if;
  delete from public.businesses where owner_id='00000000-0000-0000-0000-000000164002' and name='legacy incomplete';
end $$;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
do $$ declare denied boolean:=false; begin
  begin insert into public.businesses(owner_id,name,type,address,latitude,longitude,status) values(auth.uid(),'after delete',1,'Ciudad Guzmán',19.7086,-103.4641,'pending');
  exception when sqlstate 'P0001' then denied:=sqlerrm='business_daily_limit'; end;
  if not denied then raise exception 'FAIL: deleting a listing reset daily quota'; end if;
end $$;
reset role;

update private.trust_settings set business_daily_creation_limit=3 where singleton;
-- UUID replay owned by another user fails closed instead of exposing its state.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
do $$ declare denied boolean:=false; begin
  begin perform public.submit_business_listing(jsonb_build_object('business_id','00000000-0000-0000-0000-000000164101'),'[]'::jsonb);
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'FAIL: replay accepted another owner UUID'; end if;
end $$;
reset role;

-- Exact storage host check rejects a different Supabase project even when the
-- caller owns the matching bucket object and object path.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
do $$ begin
  begin
    perform public.submit_business_listing(jsonb_build_object(
      'business_id','00000000-0000-0000-0000-000000164102','name','Otra tienda','type',1,
      'address','Centro, Ciudad Guzmán','latitude',19.7086,'longitude',-103.4641,
      'image_object','00000000-0000-0000-0000-000000164102/hero.jpg',
      'image_url','https://other-project.supabase.co/storage/v1/object/public/businesses_pictures/00000000-0000-0000-0000-000000164102/hero.jpg'), '[]'::jsonb);
    raise exception 'FAIL: noncanonical storage host was accepted';
  exception when check_violation then null; end;
end $$;
reset role;


-- Seed moderation/status fixtures with server authority while no end-user claim is active.
select set_config('request.jwt.claim.sub','',true);
insert into storage.objects(bucket_id,name,owner,owner_id) values
 ('businesses_pictures','00000000-0000-0000-0000-000000164113/hero.jpg','00000000-0000-0000-0000-000000164002','00000000-0000-0000-0000-000000164002');
insert into public.businesses(business_id,owner_id,name,type,address,latitude,longitude,images,status,verified_at,published_at) values
 ('00000000-0000-0000-0000-000000164110','00000000-0000-0000-0000-000000164003','Reviewer own under review',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'under_review',now(),null),
 ('00000000-0000-0000-0000-000000164111','00000000-0000-0000-0000-000000164002','Pending needs photo',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'pending',null,null),
 ('00000000-0000-0000-0000-000000164112','00000000-0000-0000-0000-000000164002','Under review no photo',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'under_review',null,null),
 ('00000000-0000-0000-0000-000000164113','00000000-0000-0000-0000-000000164002','Pending with photo',1,'Ciudad Guzmán',19.7086,-103.4641,array['https://test-project.supabase.co/storage/v1/object/public/businesses_pictures/00000000-0000-0000-0000-000000164113/hero.jpg'],'pending',null,null),
 ('00000000-0000-0000-0000-000000164114','00000000-0000-0000-0000-000000164002','Pending for rejection',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'pending',null,null),
 ('00000000-0000-0000-0000-000000164115','00000000-0000-0000-0000-000000164002','Pending private row',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'pending',null,null),
 ('00000000-0000-0000-0000-000000164116','00000000-0000-0000-0000-000000164002','Clean Old Cafe',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now(),now()),
 ('00000000-0000-0000-0000-000000164117','00000000-0000-0000-0000-000000164002','Harbor Cafe',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',null,now());
insert into public.business_hours(business_id,day_of_week,opening_time,closing_time) values
 ('00000000-0000-0000-0000-000000164115',1,'09:00','18:00');

-- Owner edits in any status still enforce core field shape.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
do $$ declare denied boolean:=false; begin
  begin update public.businesses set latitude=0,longitude=0 where business_id='00000000-0000-0000-0000-000000164111';
  exception when check_violation then denied:=sqlerrm='invalid_listing'; end;
  if not denied then raise exception 'FAIL: owner edit accepted zero coordinates'; end if;
end $$;
reset role;

-- An owner who is also a reviewer cannot resolve their own under_review listing,
-- but may continue editing valid business data while it remains under review.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164003',true);
do $$ declare denied boolean:=false; begin
  begin update public.businesses set status='withdrawn',rejection_reason='owner withdrawal' where business_id='00000000-0000-0000-0000-000000164110';
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'FAIL: owner-reviewer withdrew own under_review listing'; end if;
end $$;
update public.businesses set description='Owner edit retained in review' where business_id='00000000-0000-0000-0000-000000164110';
reset role;
do $$ begin if (select status from public.businesses where business_id='00000000-0000-0000-0000-000000164110')<>'under_review' then raise exception 'FAIL: owner edit resolved under_review'; end if; end $$;

-- An ordinary non-reviewer cannot change or withdraw another owner's row.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164001',true);
update public.businesses set status='withdrawn',rejection_reason='unauthorized' where business_id='00000000-0000-0000-0000-000000164115';
reset role;
do $$ begin if (select status from public.businesses where business_id='00000000-0000-0000-0000-000000164115')<>'pending' then raise exception 'FAIL: non-reviewer changed another listing'; end if; end $$;

-- Reviewer updates may change only status/reason; pending approval requires a valid owned image.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164004',true);
do $$ declare denied boolean:=false; begin
  begin update public.businesses set status='approved',description='Tampered with decision' where business_id='00000000-0000-0000-0000-000000164113';
  exception when insufficient_privilege then denied:=sqlerrm='reviewer_status_only'; end;
  if not denied then raise exception 'FAIL: reviewer changed business data during approval'; end if;
  denied:=false;
  begin update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-000000164111';
  exception when check_violation then denied:=sqlerrm='invalid_listing'; end;
  if not denied then raise exception 'FAIL: reviewer approved legacy listing without a photo'; end if;
  update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-000000164113';
  -- Historical missing photo is allowed when restoring an under_review listing.
  update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-000000164112';
end $$;
reset role;
select set_config('request.jwt.claim.sub','',true);
insert into storage.objects(bucket_id,name,owner,owner_id) values ('businesses_pictures','00000000-0000-0000-0000-000000164111/hero with space.jpg','00000000-0000-0000-0000-000000164002','00000000-0000-0000-0000-000000164002');
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
update public.businesses set images=array['https://test-project.supabase.co/storage/v1/object/public/businesses_pictures/00000000-0000-0000-0000-000000164111/hero%20with%20space.jpg'] where business_id='00000000-0000-0000-0000-000000164111';
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164004',true);
update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-000000164111';
reset role;
do $$ begin
  if (select status from public.businesses where business_id='00000000-0000-0000-0000-000000164111')<>'approved' then raise exception 'FAIL: owned legacy image update failed'; end if;
  if (select status from public.businesses where business_id='00000000-0000-0000-0000-000000164113')<>'approved' then raise exception 'FAIL: valid reviewer approval failed'; end if;
  if (select status from public.businesses where business_id='00000000-0000-0000-0000-000000164112')<>'approved' then raise exception 'FAIL: under_review restore required a historical photo'; end if;
  if not exists(select 1 from public.business_review_log where business_id='00000000-0000-0000-0000-000000164113' and actor_role='reviewer' and to_status='approved') then raise exception 'FAIL: reviewer decision history missing'; end if;
end $$;

-- Rejection and withdrawal require a reason; successful reviewer actions log that reason.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164004',true);
do $$ declare denied boolean:=false; begin
  begin update public.businesses set status='withdrawn',rejection_reason='  ' where business_id='00000000-0000-0000-0000-000000164112';
  exception when check_violation then denied:=sqlerrm='invalid_listing'; end;
  if not denied then raise exception 'FAIL: reviewer withdrew without reason'; end if;
  update public.businesses set status='withdrawn',rejection_reason='Business closed' where business_id='00000000-0000-0000-0000-000000164112';
  denied:=false;
  begin update public.businesses set status='rejected',rejection_reason='  ' where business_id='00000000-0000-0000-0000-000000164114';
  exception when check_violation then denied:=sqlerrm='invalid_listing'; end;
  if not denied then raise exception 'FAIL: reviewer rejected without reason'; end if;
  update public.businesses set status='rejected',rejection_reason='Missing business proof' where business_id='00000000-0000-0000-0000-000000164114';
end $$;
reset role;
do $$ begin
  if not exists(select 1 from public.business_review_log where business_id='00000000-0000-0000-0000-000000164112' and actor_role='reviewer' and reason='Business closed') then raise exception 'FAIL: withdrawal reason was not logged'; end if;
  if not exists(select 1 from public.business_review_log where business_id='00000000-0000-0000-0000-000000164114' and actor_role='reviewer' and reason='Missing business proof') then raise exception 'FAIL: rejection reason was not logged'; end if;
end $$;

-- PostgREST anon sees only approved active listings and their child hours.
set local role anon;
do $$ begin
  if exists(select 1 from public.businesses where business_id in ('00000000-0000-0000-0000-000000164114','00000000-0000-0000-0000-000000164115')) then raise exception 'FAIL: anon can see a non-approved business'; end if;
  if exists(select 1 from public.business_hours where business_id='00000000-0000-0000-0000-000000164115') then raise exception 'FAIL: anon can see hours for a non-approved business'; end if;
  if not exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-000000164111') or not exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-000000164113') then raise exception 'FAIL: anon cannot see approved business'; end if;
end $$;
reset role;

-- Common postgres SECURITY DEFINER code cannot impersonate the dedicated submitter.
create or replace function public.test_common_definer_cannot_approve(p_id uuid)
returns void language plpgsql security definer set search_path=pg_catalog,public,auth
as $$ begin
  insert into public.businesses(business_id,owner_id,name,type,address,latitude,longitude,status)
  values(p_id,auth.uid(),'Forged common definer',1,'Ciudad Guzmán',19.7086,-103.4641,'approved');
end $$;
grant execute on function public.test_common_definer_cannot_approve(uuid) to authenticated;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
do $$ declare denied boolean:=false; begin
  begin perform public.test_common_definer_cannot_approve('00000000-0000-0000-0000-000000164118');
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'FAIL: common definer created approved listing'; end if;
end $$;
reset role;

-- Each configured soft-review gate returns a stable reason code.
select set_config('request.jwt.claim.sub','',true);
update private.trust_settings set prohibited_terms=array['bannedword'],business_active_listing_limit=10 where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164001',true);
do $$ begin
  if private.listing_review_reason('Outside','',null,18.5,-103.4,'00000000-0000-0000-0000-000000164201','00000000-0000-0000-0000-000000164001')<>'outside_pilot' then raise exception 'FAIL: outside_pilot reason'; end if;
  if private.listing_review_reason('Harbor Cafe','',null,19.7086,-103.4641,'00000000-0000-0000-0000-000000164202','00000000-0000-0000-0000-000000164001')<>'possible_duplicate' then raise exception 'FAIL: possible_duplicate reason'; end if;
  if private.listing_review_reason('Bannedword Store','',null,19.7086,-103.4641,'00000000-0000-0000-0000-000000164203','00000000-0000-0000-0000-000000164001')<>'prohibited_language' then raise exception 'FAIL: prohibited_language reason'; end if;
  if private.listing_review_reason('Useful Shop','https://bit.ly/example',null,19.7086,-103.4641,'00000000-0000-0000-0000-000000164204','00000000-0000-0000-0000-000000164001')<>'suspicious_contact' then raise exception 'FAIL: suspicious_contact reason'; end if;
end $$;
reset role;

-- Owner-triggered trust decisions are logged as system; verified_at can only
-- be cleared by changing identity fields, never by clean contact edits.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
update public.businesses set name='Bannedword Old Cafe',verified_at=now() where business_id='00000000-0000-0000-0000-000000164116';
reset role;
do $$ begin
  if (select status from public.businesses where business_id='00000000-0000-0000-0000-000000164116')<>'pending' then raise exception 'FAIL: owner soft issue did not return listing to review'; end if;
  if not exists(select 1 from public.business_review_log where business_id='00000000-0000-0000-0000-000000164116' and actor_role='system' and actor_id is null and reason='prohibited_language') then raise exception 'FAIL: owner-triggered review log is not system-owned'; end if;
end $$;

-- Re-submission consults the configured active cap.
select set_config('request.jwt.claim.sub','',true);
insert into storage.objects(bucket_id,name,owner,owner_id) values ('businesses_pictures','00000000-0000-0000-0000-000000164119/hero.jpg','00000000-0000-0000-0000-000000164002','00000000-0000-0000-0000-000000164002');
insert into public.businesses(business_id,owner_id,name,type,address,latitude,longitude,images,status)
values('00000000-0000-0000-0000-000000164119','00000000-0000-0000-0000-000000164002','Rejected for resubmit',1,'Ciudad Guzmán',19.7086,-103.4641,array['https://test-project.supabase.co/storage/v1/object/public/businesses_pictures/00000000-0000-0000-0000-000000164119/hero.jpg'],'rejected');
update private.trust_settings set business_active_listing_limit=1 where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164002',true);
do $$ declare denied boolean:=false; begin
  begin update public.businesses set status='pending' where business_id='00000000-0000-0000-0000-000000164119';
  exception when sqlstate 'P0001' then denied:=sqlerrm='business_active_limit'; end;
  if not denied then raise exception 'FAIL: resubmission ignored configured active cap'; end if;
end $$;
reset role;
update private.trust_settings set business_active_listing_limit=10 where singleton;

-- Active listing cap is checked even when the daily cap has room.
select set_config('request.jwt.claim.sub','',true);
insert into public.businesses(business_id,owner_id,name,status)
select ('00000000-0000-0000-0000-000000165'||lpad(n::text,3,'0'))::uuid,
       '00000000-0000-0000-0000-000000164001','Active seed '||n,'approved'
from generate_series(1,10) as n;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000164001',true);
do $$ declare denied boolean:=false; begin
  begin insert into public.businesses(owner_id,name,type,address,latitude,longitude,status) values(auth.uid(),'over active cap',1,'Ciudad Guzmán',19.7086,-103.4641,'pending');
  exception when sqlstate 'P0001' then denied:=sqlerrm='business_active_limit'; end;
  if not denied then raise exception 'FAIL: active listing cap not enforced'; end if;
end $$;
reset role;

rollback;
