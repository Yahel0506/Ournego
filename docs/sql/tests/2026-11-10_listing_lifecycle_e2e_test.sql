-- OUR-115 / OUR-171: independent owners, public observer and reviewer.
-- Run after all migrations through 2026-11-19_business_trust_submission.sql
-- on a disposable Supabase-compatible database, with ON_ERROR_STOP enabled.
-- All fixtures and trust-setting changes roll back on success or failure.
begin;
insert into auth.users(id,aud,role,email) values
 ('00000000-0000-0000-0000-000000115a01','authenticated','authenticated','clean115@test.invalid'),
 ('00000000-0000-0000-0000-000000115a02','authenticated','authenticated','doubtful115@test.invalid'),
 ('00000000-0000-0000-0000-000000115a03','authenticated','authenticated','reviewer115@test.invalid'),
 ('00000000-0000-0000-0000-000000115a04','authenticated','authenticated','observer115@test.invalid'),
 ('00000000-0000-0000-0000-000000115a05','authenticated','authenticated','correction115@test.invalid');
insert into public.users(id,has_profile,name) values
 ('00000000-0000-0000-0000-000000115a01',true,'Clean owner'),
 ('00000000-0000-0000-0000-000000115a02',true,'Doubtful owner'),
 ('00000000-0000-0000-0000-000000115a05',true,'Correction owner');
insert into public.reviewers(user_id) values ('00000000-0000-0000-0000-000000115a03');
update private.trust_settings set storage_public_origin='https://test-project.supabase.co',prohibited_terms=array['bannedword'] where singleton;
insert into storage.objects(bucket_id,name,owner,owner_id) values
 ('businesses_pictures','00000000-0000-0000-0000-0000000115b1/hero.jpg','00000000-0000-0000-0000-000000115a01','00000000-0000-0000-0000-000000115a01'),
 ('businesses_pictures','00000000-0000-0000-0000-0000000115b2/hero.jpg','00000000-0000-0000-0000-000000115a02','00000000-0000-0000-0000-000000115a02'),
 ('businesses_pictures','00000000-0000-0000-0000-0000000115b3/hero.jpg','00000000-0000-0000-0000-000000115a05','00000000-0000-0000-0000-000000115a05');

-- Three real submissions: one clean and two deliberately flagged.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a01',true);
do $$ declare r jsonb; begin
 r:=public.submit_business_listing(jsonb_build_object('business_id','00000000-0000-0000-0000-0000000115b1','name','OUR115 Clean Bakery','type',1,'address','Ciudad Guzmán','latitude',19.7086,'longitude',-103.4641,'image_object','00000000-0000-0000-0000-0000000115b1/hero.jpg','image_url','https://test-project.supabase.co/storage/v1/object/public/businesses_pictures/00000000-0000-0000-0000-0000000115b1/hero.jpg'), '[{"day_of_week":1,"opening_time":"09:00","closing_time":"18:00"}]'::jsonb);
 if r->>'status'<>'approved' or r->'review_pending_reason'<>'null'::jsonb then raise exception 'FAIL: clean submission %',r; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a02',true);
do $$ declare r jsonb; begin
 r:=public.submit_business_listing(jsonb_build_object('business_id','00000000-0000-0000-0000-0000000115b2','name','OUR115 Bannedword Market','type',1,'address','Ciudad Guzmán','latitude',19.7086,'longitude',-103.4641,'image_object','00000000-0000-0000-0000-0000000115b2/hero.jpg','image_url','https://test-project.supabase.co/storage/v1/object/public/businesses_pictures/00000000-0000-0000-0000-0000000115b2/hero.jpg'), '[{"day_of_week":1,"opening_time":"09:00","closing_time":"18:00"}]'::jsonb);
 if r->>'status'<>'pending' or r->>'review_pending_reason'<>'prohibited_language' then raise exception 'FAIL: flagged submission %',r; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a05',true);
do $$ declare r jsonb; begin
 r:=public.submit_business_listing(jsonb_build_object('business_id','00000000-0000-0000-0000-0000000115b3','name','OUR115 Bannedword Repair','type',1,'address','Ciudad Guzmán','latitude',19.7086,'longitude',-103.4641,'image_object','00000000-0000-0000-0000-0000000115b3/hero.jpg','image_url','https://test-project.supabase.co/storage/v1/object/public/businesses_pictures/00000000-0000-0000-0000-0000000115b3/hero.jpg'), '[]'::jsonb);
 if r->>'status'<>'pending' then raise exception 'FAIL: correction submission %',r; end if;
end $$;
reset role;
set local role anon;
do $$ begin
 if not exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000115b1' and status='approved' and published_at is not null and verified_at is null) then raise exception 'FAIL: clean listing not immediately public and unverified'; end if;
 if not exists(select 1 from public.business_hours where business_id='00000000-0000-0000-0000-0000000115b1') then raise exception 'FAIL: clean hours invisible'; end if;
 if exists(select 1 from public.businesses where business_id in ('00000000-0000-0000-0000-0000000115b2','00000000-0000-0000-0000-0000000115b3')) or exists(select 1 from public.business_hours where business_id='00000000-0000-0000-0000-0000000115b2') then raise exception 'FAIL: flagged listing public'; end if;
 begin perform 1 from public.business_review_log; raise exception 'FAIL: anon reads log'; exception when insufficient_privilege then null; end;
end $$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a04',true);
do $$ declare n int; begin
 if exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000115b2') then raise exception 'FAIL: observer reads pending'; end if;
 begin
  update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-0000000115b2';
  get diagnostics n=row_count; if n<>0 then raise exception 'FAIL: observer decided'; end if;
 exception when insufficient_privilege then null; end;
 if exists(select 1 from public.business_review_log) then raise exception 'FAIL: observer reads log'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a02',true);
do $$ begin
 begin update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-0000000115b2'; raise exception 'FAIL: owner self-approved'; exception when insufficient_privilege then null; end;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a03',true);
do $$ begin
 if (select count(*) from public.businesses where business_id in ('00000000-0000-0000-0000-0000000115b2','00000000-0000-0000-0000-0000000115b3') and status='pending')<>2 then raise exception 'FAIL: queue missing submissions'; end if;
 update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-0000000115b2';
 begin update public.businesses set status='rejected',rejection_reason=' ' where business_id='00000000-0000-0000-0000-0000000115b3'; raise exception 'FAIL: blank rejection accepted'; exception when check_violation then null; end;
 update public.businesses set status='rejected',rejection_reason='Corrige el nombre' where business_id='00000000-0000-0000-0000-0000000115b3';
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a05',true);
do $$ begin
 if not exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000115b3' and status='rejected' and rejection_reason='Corrige el nombre') then raise exception 'FAIL: rejection not visible to owner'; end if;
 update public.businesses set name='OUR115 Repair Workshop' where business_id='00000000-0000-0000-0000-0000000115b3';
 update public.businesses set status='pending' where business_id='00000000-0000-0000-0000-0000000115b3';
 if not exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000115b3' and status='pending' and rejection_reason is null) then raise exception 'FAIL: correction not resubmitted'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a03',true);
update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-0000000115b3';
reset role;
set local role anon;
do $$ begin
 if (select count(*) from public.businesses where business_id in ('00000000-0000-0000-0000-0000000115b2','00000000-0000-0000-0000-0000000115b3') and status='approved')<>2 then raise exception 'FAIL: approved listings not public'; end if;
end $$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000115a03',true);
update public.businesses set status='withdrawn',rejection_reason='Cierre definitivo' where business_id='00000000-0000-0000-0000-0000000115b2';
reset role;
set local role anon;
do $$ begin
 if exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000115b2' or name='OUR115 Bannedword Market') or exists(select 1 from public.business_hours where business_id='00000000-0000-0000-0000-0000000115b2') or exists(select 1 from public.business_products where business_id='00000000-0000-0000-0000-0000000115b2') or exists(select 1 from public.business_exceptions where business_id='00000000-0000-0000-0000-0000000115b2') then raise exception 'FAIL: withdrawn listing leaves public rows'; end if;
end $$;
reset role;
do $$ begin
 if not exists(select 1 from public.business_review_log where business_id='00000000-0000-0000-0000-0000000115b1' and actor_role='system' and actor_id is null and to_status='approved') or not exists(select 1 from public.business_review_log where business_id='00000000-0000-0000-0000-0000000115b2' and actor_role='reviewer' and to_status='withdrawn' and reason='Cierre definitivo') then raise exception 'FAIL: lifecycle audit missing'; end if;
end $$;
rollback;
