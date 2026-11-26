-- OUR-165 business confirmation checks. Run after 2026-11-25_business_confirmations.sql;
-- all fixture data rolls back.
begin;

insert into auth.users(id, aud, role, email, created_at) values
 ('00000000-0000-0000-0000-000000165001','authenticated','authenticated','owner@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000165002','authenticated','authenticated','valid@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000165003','authenticated','authenticated','young@test.invalid', now()),
 ('00000000-0000-0000-0000-000000165004','authenticated','authenticated','noprofile@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000165005','authenticated','authenticated','other@test.invalid','2000-01-01 00:00:00+00');
insert into public.users(id, has_profile, name) values
 ('00000000-0000-0000-0000-000000165001', true, 'Owner'),
 ('00000000-0000-0000-0000-000000165002', true, 'Valid voter'),
 ('00000000-0000-0000-0000-000000165003', true, 'Young voter'),
 ('00000000-0000-0000-0000-000000165004', false, null),
 ('00000000-0000-0000-0000-000000165005', true, 'Other voter');
insert into public.businesses(business_id, owner_id, name, type, address, latitude, longitude, images, status) values
 ('00000000-0000-0000-0000-0000000165b1','00000000-0000-0000-0000-000000165001','Approved',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved'),
 ('00000000-0000-0000-0000-0000000165b2','00000000-0000-0000-0000-000000165001','Approved 2',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved'),
 ('00000000-0000-0000-0000-0000000165b3','00000000-0000-0000-0000-000000165001','Pending',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'pending');

-- Defaults come from trust_settings, not from code.
do $$ begin
  if (select voter_min_age <> interval '3 days' or voter_daily_limit <> 15
        from private.trust_settings where singleton) then
    raise exception 'FAIL: voter defaults changed';
  end if;
end $$;

-- Clients have no direct write access and cannot read `counted`.
do $$ begin
  if has_table_privilege('authenticated','public.business_confirmations','insert')
     or has_table_privilege('authenticated','public.business_confirmations','update')
     or has_table_privilege('authenticated','public.business_confirmations','delete')
     or has_table_privilege('anon','public.business_confirmations','select')
     or has_table_privilege('anon','public.business_confirmations','insert') then
    raise exception 'FAIL: direct table privileges leaked';
  end if;
  if has_column_privilege('authenticated','public.business_confirmations','counted','select') then
    raise exception 'FAIL: counted is readable by clients';
  end if;
  if has_function_privilege('anon','public.submit_business_confirmation(uuid,text)','execute') then
    raise exception 'FAIL: anon can execute the RPC';
  end if;
end $$;

-- Anonymous callers are rejected.
set local role anon;
do $$ declare denied boolean := false; begin
  begin perform public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b1','yes');
  exception when insufficient_privilege then denied := true; end;
  if not denied then raise exception 'FAIL: anon answered'; end if;
end $$;
reset role;

-- A valid account answers yes: counted.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000165002',true);
do $$ declare r jsonb; denied boolean := false; begin
  r := public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b1','yes');
  if r->>'answer' <> 'yes' or r ? 'counted' then raise exception 'FAIL: bad result %', r; end if;
  -- Idempotent: the first answer wins.
  r := public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b1','no_exists');
  if r->>'answer' <> 'yes' then raise exception 'FAIL: answer was overwritten'; end if;
  -- Bad answers and hidden businesses are rejected.
  begin perform public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b2','maybe');
  exception when sqlstate '22023' then denied := true; end;
  if not denied then raise exception 'FAIL: invalid answer accepted'; end if;
  denied := false;
  begin perform public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b3','yes');
  exception when sqlstate 'P0002' then denied := true; end;
  if not denied then raise exception 'FAIL: pending business accepted answers'; end if;
  -- The user reads only their own row.
  if (select count(*) from public.business_confirmations) <> 1 then
    raise exception 'FAIL: own row not readable exactly once';
  end if;
  -- No direct writes.
  denied := false;
  begin insert into public.business_confirmations(business_id,user_id,answer)
    values ('00000000-0000-0000-0000-0000000165b2', auth.uid(), 'yes');
  exception when insufficient_privilege then denied := true; end;
  if not denied then raise exception 'FAIL: direct insert succeeded'; end if;
end $$;
reset role;
do $$ begin
  if not (select counted from public.business_confirmations
           where user_id='00000000-0000-0000-0000-000000165002'
             and business_id='00000000-0000-0000-0000-0000000165b1') then
    raise exception 'FAIL: valid answer was not counted';
  end if;
end $$;

-- Another user cannot see that row.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000165005',true);
do $$ begin
  if (select count(*) from public.business_confirmations) <> 0 then
    raise exception 'FAIL: confirmations visible to other users';
  end if;
end $$;
reset role;

-- Invalid accounts can answer but do not count: owner, young account, no profile.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000165001',true);
select public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b1','yes');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000165003',true);
select public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b1','yes');
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000165004',true);
select public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b1','no_exists');
reset role;
do $$ begin
  if exists (select 1 from public.business_confirmations
              where user_id in ('00000000-0000-0000-0000-000000165001',
                                '00000000-0000-0000-0000-000000165003',
                                '00000000-0000-0000-0000-000000165004') and counted) then
    raise exception 'FAIL: an invalid account counted';
  end if;
  if (select count(*) from public.business_confirmations where business_id='00000000-0000-0000-0000-0000000165b1') <> 4 then
    raise exception 'FAIL: invalid accounts could not answer';
  end if;
end $$;

-- Daily cap comes from trust_settings: the answer over the cap is stored, not counted.
update private.trust_settings set voter_daily_limit = 1 where singleton;
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000165005',true);
select public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b1','unsure');
select public.submit_business_confirmation('00000000-0000-0000-0000-0000000165b2','yes');
reset role;
do $$ begin
  if not (select counted from public.business_confirmations
           where user_id='00000000-0000-0000-0000-000000165005' and answer='unsure') then
    raise exception 'FAIL: answer under the cap not counted';
  end if;
  if (select counted from public.business_confirmations
       where user_id='00000000-0000-0000-0000-000000165005' and answer='yes') then
    raise exception 'FAIL: answer over the daily cap counted';
  end if;
end $$;
update private.trust_settings set voter_daily_limit = 15 where singleton;

-- A counted `no_exists` is queryable for the reports phase.
do $$ begin
  insert into public.business_confirmations(business_id,user_id,answer,counted)
  values ('00000000-0000-0000-0000-0000000165b2','00000000-0000-0000-0000-000000165002','no_exists',true);
  if (select count(*) from public.business_confirmations
       where business_id='00000000-0000-0000-0000-0000000165b2' and answer='no_exists' and counted) <> 1 then
    raise exception 'FAIL: no_exists signal not queryable';
  end if;
end $$;

rollback;
