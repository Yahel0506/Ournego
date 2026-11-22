-- OUR-112: owner edits, correction and resubmission under OUR-164/170.
-- Run after all migrations through 2026-11-19_business_trust_submission.sql.
-- Fixture changes and settings are rolled back.
begin;
insert into auth.users(id,aud,role,email) values
 ('00000000-0000-0000-0000-000000112a01','authenticated','authenticated','owner112@test.invalid'),
 ('00000000-0000-0000-0000-000000112a03','authenticated','authenticated','reviewer112@test.invalid');
insert into public.users(id,has_profile,name) values ('00000000-0000-0000-0000-000000112a01',true,'Owner');
insert into public.reviewers(user_id) values ('00000000-0000-0000-0000-000000112a03');
update private.trust_settings set storage_public_origin='https://test-project.supabase.co',prohibited_terms=array['bannedword'] where singleton;
insert into storage.objects(bucket_id,name,owner,owner_id)
select 'businesses_pictures', id::text||'/hero.jpg','00000000-0000-0000-0000-000000112a01','00000000-0000-0000-0000-000000112a01'
from unnest(array['00000000-0000-0000-0000-0000000112b1'::uuid,'00000000-0000-0000-0000-0000000112b2'::uuid]) id;
insert into public.businesses(business_id,owner_id,name,type,address,latitude,longitude,images,status,rejection_reason,verified_at,published_at)
select id,'00000000-0000-0000-0000-000000112a01',name,1,'Ciudad Guzmán',19.7086,-103.4641,
 array['https://test-project.supabase.co/storage/v1/object/public/businesses_pictures/'||id::text||'/hero.jpg'],status::public.business_status,reason,now(),now()
from (values ('00000000-0000-0000-0000-0000000112b1'::uuid,'Clean shop','approved',null::text),
 ('00000000-0000-0000-0000-0000000112b2'::uuid,'Rejected shop','rejected','Falta la dirección')) v(id,name,status,reason);
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000112a01',true);
do $$ declare r record; begin
  update public.businesses set description='Servicio local' where business_id='00000000-0000-0000-0000-0000000112b1';
  select * into r from public.businesses where business_id='00000000-0000-0000-0000-0000000112b1';
  if r.status <> 'approved' or r.verified_at is null then raise exception 'FAIL: clean edit changed status or verification'; end if;
  update public.businesses set name='Bannedword shop' where business_id='00000000-0000-0000-0000-0000000112b1';
  select * into r from public.businesses where business_id='00000000-0000-0000-0000-0000000112b1';
  if r.status <> 'pending' or r.pending_issue_code <> 'prohibited_language' or r.verified_at is not null then raise exception 'FAIL: risky identity edit not queued'; end if;
  begin
    update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-0000000112b1';
    raise exception 'FAIL: owner approved own listing';
  exception when insufficient_privilege then null; end;
  begin
    update public.businesses set status='rejected' where business_id='00000000-0000-0000-0000-0000000112b1';
    raise exception 'FAIL: owner rejected own listing';
  exception when insufficient_privilege then null; end;
  update public.businesses set reviewed_at=now(),rejection_reason='forged' where business_id='00000000-0000-0000-0000-0000000112b1';
  select * into r from public.businesses where business_id='00000000-0000-0000-0000-0000000112b1';
  if r.reviewed_at is not null or r.rejection_reason is not null then raise exception 'FAIL: owner forged decision'; end if;
  update public.businesses set address='Calle 1' where business_id='00000000-0000-0000-0000-0000000112b2';
  if (select status from public.businesses where business_id='00000000-0000-0000-0000-0000000112b2') <> 'rejected' then raise exception 'FAIL: edit resolved rejection'; end if;
  update public.businesses set status='pending' where business_id='00000000-0000-0000-0000-0000000112b2';
  select * into r from public.businesses where business_id='00000000-0000-0000-0000-0000000112b2';
  if r.status <> 'pending' or r.rejection_reason is not null or r.submitted_at is null then raise exception 'FAIL: resubmission'; end if;
end $$;
reset role;
set local role anon;
do $$ begin
 if exists(select 1 from public.businesses where business_id in ('00000000-0000-0000-0000-0000000112b1','00000000-0000-0000-0000-0000000112b2')) then raise exception 'FAIL: pending listing is public'; end if;
end $$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000112a03',true);
update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-0000000112b2';
do $$ begin
 if not exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000112b2' and status='approved' and published_at is not null and rejection_reason is null) then raise exception 'FAIL: approval'; end if;
end $$;
reset role;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000112a01',true);
do $$ begin
  update public.businesses set status='withdrawn' where business_id='00000000-0000-0000-0000-0000000112b2';
  if not exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000112b2' and status='withdrawn' and rejection_reason is null) then raise exception 'FAIL: owner withdrawal'; end if;
  update public.businesses set status='pending' where business_id='00000000-0000-0000-0000-0000000112b2';
  if not exists(select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000112b2' and status='pending' and rejection_reason is null) then raise exception 'FAIL: withdrawn resubmission'; end if;
end $$;
reset role;
rollback;
