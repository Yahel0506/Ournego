-- OUR-166 business report checks. Run after 2026-11-26_business_reports.sql
-- (or with it, in the same transaction); all fixture data rolls back.
begin;

insert into auth.users(id, aud, role, email, created_at) values
 ('00000000-0000-0000-0000-000000166001','authenticated','authenticated','owner@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000166002','authenticated','authenticated','v2@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000166003','authenticated','authenticated','v3@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000166004','authenticated','authenticated','v4@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000166005','authenticated','authenticated','v5@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000166006','authenticated','authenticated','v6@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000166007','authenticated','authenticated','young@test.invalid', now()),
 ('00000000-0000-0000-0000-000000166008','authenticated','authenticated','noprofile@test.invalid','2000-01-01 00:00:00+00'),
 ('00000000-0000-0000-0000-000000166009','authenticated','authenticated','young2@test.invalid', now());
insert into public.users(id, has_profile, name) values
 ('00000000-0000-0000-0000-000000166001', true, 'Owner'),
 ('00000000-0000-0000-0000-000000166002', true, 'V2'),
 ('00000000-0000-0000-0000-000000166003', true, 'V3'),
 ('00000000-0000-0000-0000-000000166004', true, 'V4'),
 ('00000000-0000-0000-0000-000000166005', true, 'V5'),
 ('00000000-0000-0000-0000-000000166006', true, 'V6'),
 ('00000000-0000-0000-0000-000000166007', true, 'Young'),
 ('00000000-0000-0000-0000-000000166008', false, null),
 ('00000000-0000-0000-0000-000000166009', true, 'Young 2');
insert into public.businesses(business_id, owner_id, name, type, address, latitude, longitude, images, status, published_at) values
 ('00000000-0000-0000-0000-0000000166b1','00000000-0000-0000-0000-000000166001','NoExists',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now()),
 ('00000000-0000-0000-0000-0000000166b2','00000000-0000-0000-0000-000000166001','SoftReasons',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now()),
 ('00000000-0000-0000-0000-0000000166b3','00000000-0000-0000-0000-000000166001','Invalid',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now()),
 ('00000000-0000-0000-0000-0000000166b4','00000000-0000-0000-0000-000000166001','Inappropriate',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now()),
 ('00000000-0000-0000-0000-0000000166b5','00000000-0000-0000-0000-000000166001','Mixed',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now()),
 ('00000000-0000-0000-0000-0000000166b6','00000000-0000-0000-0000-000000166001','Window',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now()),
 ('00000000-0000-0000-0000-0000000166b7','00000000-0000-0000-0000-000000166001','Restored',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now()),
 ('00000000-0000-0000-0000-0000000166b8','00000000-0000-0000-0000-000000166001','Pending',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'pending',null),
 ('00000000-0000-0000-0000-0000000166b9','00000000-0000-0000-0000-000000166001','Cap',1,'Ciudad Guzmán',19.7086,-103.4641,array[''],'approved',now());
update public.businesses set verified_at = now()
 where business_id in ('00000000-0000-0000-0000-0000000166b1','00000000-0000-0000-0000-0000000166b5');

create function pg_temp.rep(u uuid, b uuid, r text, n text default null) returns text
language plpgsql as $$
declare res text := 'ok';
begin
  perform set_config('request.jwt.claim.sub', u::text, true);
  execute 'set local role authenticated';
  begin perform public.submit_business_report(b, r, n);
  exception when others then res := sqlerrm; end;
  execute 'reset role';
  return res;
end $$;
create function pg_temp.conf(u uuid, b uuid, a text) returns text
language plpgsql as $$
declare res text := 'ok';
begin
  perform set_config('request.jwt.claim.sub', u::text, true);
  execute 'set local role authenticated';
  begin perform public.submit_business_confirmation(b, a);
  exception when others then res := sqlerrm; end;
  execute 'reset role';
  return res;
end $$;
create function pg_temp.status_of(b uuid) returns text language sql as
  $$ select status::text from public.businesses where business_id = b $$;

-- Defaults come from trust_settings, not from code.
do $$ begin
  if (select report_daily_limit <> 10 or report_window <> interval '7 days' or report_threshold <> 3
        from private.trust_settings where singleton) then
    raise exception 'FAIL: report defaults changed';
  end if;
end $$;

-- Clients have no direct write access and cannot read `counted`.
do $$ begin
  if has_table_privilege('authenticated','public.business_reports','insert')
     or has_table_privilege('authenticated','public.business_reports','update')
     or has_table_privilege('authenticated','public.business_reports','delete')
     or has_table_privilege('anon','public.business_reports','select')
     or has_table_privilege('anon','public.business_reports','insert') then
    raise exception 'FAIL: direct table privileges leaked';
  end if;
  if has_column_privilege('authenticated','public.business_reports','counted','select') then
    raise exception 'FAIL: counted is readable by clients';
  end if;
  if has_function_privilege('anon','public.submit_business_report(uuid,text,text)','execute')
     or has_function_privilege('anon','public.get_business_open_report_count(uuid)','execute')
     or has_function_privilege('authenticated','private.evaluate_report_hiding(uuid)','execute') then
    raise exception 'FAIL: report functions are over-exposed';
  end if;
end $$;

-- Anonymous callers are rejected.
set local role anon;
do $$ declare denied boolean := false; begin
  begin perform public.submit_business_report('00000000-0000-0000-0000-0000000166b1','no_exists',null);
  exception when insufficient_privilege then denied := true; end;
  if not denied then raise exception 'FAIL: anon reported'; end if;
end $$;
reset role;

-- Validation: unknown reason, "other" without note, owner, hidden/unknown listing.
do $$ begin
  if pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b1','spam') <> 'invalid_report' then
    raise exception 'FAIL: unknown reason accepted'; end if;
  if pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b1','other','   ') <> 'invalid_report' then
    raise exception 'FAIL: other without note accepted'; end if;
  if pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b1','other',repeat('x',501)) <> 'invalid_report' then
    raise exception 'FAIL: oversized note accepted'; end if;
  if pg_temp.rep('00000000-0000-0000-0000-000000166001','00000000-0000-0000-0000-0000000166b1','no_exists') <> 'owner_cannot_report' then
    raise exception 'FAIL: owner reported own listing'; end if;
  if pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b8','no_exists') <> 'business_not_found' then
    raise exception 'FAIL: pending listing accepted a report'; end if;
  if pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-00000000dead','no_exists') <> 'business_not_found' then
    raise exception 'FAIL: unknown listing accepted a report'; end if;
  if exists (select 1 from public.business_reports) then raise exception 'FAIL: invalid reports were stored'; end if;
end $$;

-- An isolated valid report is stored and counted, and hides nothing.
do $$ begin
  if pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b1','no_exists') <> 'ok' then
    raise exception 'FAIL: valid report rejected'; end if;
  if not (select counted from public.business_reports where reporter_id='00000000-0000-0000-0000-000000166002') then
    raise exception 'FAIL: valid report not counted'; end if;
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b1') <> 'approved' then
    raise exception 'FAIL: an isolated report hid the listing'; end if;
  -- A repeated call keeps the one open report, even with another reason.
  perform pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b1','closed');
  if (select count(*) from public.business_reports where reporter_id='00000000-0000-0000-0000-000000166002') <> 1
     or (select reason from public.business_reports where reporter_id='00000000-0000-0000-0000-000000166002') <> 'no_exists' then
    raise exception 'FAIL: duplicate open report by the same user';
  end if;
end $$;

-- Users read only their own reports, and never the counted column.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000166003',true);
do $$ begin
  if (select count(*) from public.business_reports) <> 0 then
    raise exception 'FAIL: reports visible to other users'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000166002',true);
do $$ begin
  if (select count(*) from public.business_reports) <> 1 then
    raise exception 'FAIL: reporter cannot read own report'; end if;
end $$;
reset role;

-- Reasons that never hide: three valid reporters, still approved, all open.
do $$ begin
  perform pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b2','closed');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166003','00000000-0000-0000-0000-0000000166b2','incorrect_info');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166004','00000000-0000-0000-0000-0000000166b2','duplicate');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166005','00000000-0000-0000-0000-0000000166b2','other','Texto de prueba');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b2') <> 'approved' then
    raise exception 'FAIL: a non-hiding reason hid the listing'; end if;
  if (select count(*) from public.business_reports
       where business_id='00000000-0000-0000-0000-0000000166b2' and status='open') <> 4 then
    raise exception 'FAIL: soft reports are not open for moderation'; end if;
end $$;

-- Invalid accounts report but never count: young, no profile.
do $$ begin
  perform pg_temp.rep('00000000-0000-0000-0000-000000166007','00000000-0000-0000-0000-0000000166b3','no_exists');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166008','00000000-0000-0000-0000-0000000166b3','no_exists');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166009','00000000-0000-0000-0000-0000000166b3','no_exists');
  if (select count(*) from public.business_reports where business_id='00000000-0000-0000-0000-0000000166b3') <> 3 then
    raise exception 'FAIL: invalid accounts could not report'; end if;
  if exists (select 1 from public.business_reports where business_id='00000000-0000-0000-0000-0000000166b3' and counted) then
    raise exception 'FAIL: an invalid account counted'; end if;
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b3') <> 'approved' then
    raise exception 'FAIL: invalid accounts hid a listing'; end if;
end $$;

-- Three distinct valid `no_exists` reporters hide the listing, retire the
-- verified mark and leave a system log row. The third report triggers it.
do $$ begin
  perform pg_temp.rep('00000000-0000-0000-0000-000000166003','00000000-0000-0000-0000-0000000166b1','no_exists');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b1') <> 'approved' then
    raise exception 'FAIL: two reporters hid the listing'; end if;
  perform pg_temp.rep('00000000-0000-0000-0000-000000166004','00000000-0000-0000-0000-0000000166b1','no_exists');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b1') <> 'under_review' then
    raise exception 'FAIL: three valid reporters did not hide the listing'; end if;
  if (select verified_at from public.businesses where business_id='00000000-0000-0000-0000-0000000166b1') is not null then
    raise exception 'FAIL: verified mark kept after hiding'; end if;
  if not exists (select 1 from public.business_review_log
                  where business_id='00000000-0000-0000-0000-0000000166b1'
                    and from_status='approved' and to_status='under_review'
                    and actor_role='system' and actor_id is null and reason='reports') then
    raise exception 'FAIL: hiding left no system log row'; end if;
  if (select count(*) from public.business_reports
       where business_id='00000000-0000-0000-0000-0000000166b1' and status='open') <> 3 then
    raise exception 'FAIL: reports changed state when the listing was hidden'; end if;
end $$;

-- Hidden listings leave the public read path (RLS of OUR-111) and accept no new reports.
set local role anon;
do $$ begin
  if exists (select 1 from public.businesses where business_id='00000000-0000-0000-0000-0000000166b1') then
    raise exception 'FAIL: hidden listing still public'; end if;
end $$;
reset role;
do $$ begin
  if pg_temp.rep('00000000-0000-0000-0000-000000166005','00000000-0000-0000-0000-0000000166b1','no_exists') <> 'business_not_found' then
    raise exception 'FAIL: hidden listing accepted a report'; end if;
end $$;

-- `inappropriate` hides too, but one reason's reporters never add to the other's.
do $$ begin
  perform pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b4','inappropriate');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166003','00000000-0000-0000-0000-0000000166b4','no_exists');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166004','00000000-0000-0000-0000-0000000166b4','inappropriate');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b4') <> 'approved' then
    raise exception 'FAIL: mixed reasons hid the listing'; end if;
  perform pg_temp.rep('00000000-0000-0000-0000-000000166005','00000000-0000-0000-0000-0000000166b4','inappropriate');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b4') <> 'under_review' then
    raise exception 'FAIL: three inappropriate reports did not hide'; end if;
end $$;

-- A counted `no_exists` community answer counts as a report of that reason, and
-- one person with both a report and an answer counts once.
do $$ begin
  perform pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b5','no_exists');
  perform pg_temp.conf('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b5','no_exists');
  perform pg_temp.conf('00000000-0000-0000-0000-000000166003','00000000-0000-0000-0000-0000000166b5','no_exists');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b5') <> 'approved' then
    raise exception 'FAIL: one person counted twice (report and answer)'; end if;
  perform pg_temp.conf('00000000-0000-0000-0000-000000166004','00000000-0000-0000-0000-0000000166b5','no_exists');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b5') <> 'under_review' then
    raise exception 'FAIL: community no_exists answers did not hide'; end if;
  if (select verified_at from public.businesses where business_id='00000000-0000-0000-0000-0000000166b5') is not null then
    raise exception 'FAIL: verified mark kept after hiding by answers'; end if;
  if not exists (select 1 from public.business_review_log
                  where business_id='00000000-0000-0000-0000-0000000166b5'
                    and to_status='under_review' and actor_role='system') then
    raise exception 'FAIL: answer-driven hiding left no system log row'; end if;
end $$;

-- Only recent signals count: reports older than the window never hide.
do $$ begin
  insert into public.business_reports(business_id,reporter_id,reason,counted,created_at)
  select '00000000-0000-0000-0000-0000000166b6', u, 'no_exists', true, now() - interval '8 days'
    from unnest(array['00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-000000166003']::uuid[]) u;
  perform pg_temp.rep('00000000-0000-0000-0000-000000166004','00000000-0000-0000-0000-0000000166b6','no_exists');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b6') <> 'approved' then
    raise exception 'FAIL: stale reports counted'; end if;
end $$;

-- After moderation restores a listing, earlier signals are not counted again.
do $$ begin
  perform pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b7','no_exists');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166003','00000000-0000-0000-0000-0000000166b7','no_exists');
  perform pg_temp.rep('00000000-0000-0000-0000-000000166004','00000000-0000-0000-0000-0000000166b7','no_exists');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b7') <> 'under_review' then
    raise exception 'FAIL: setup did not hide the restored listing'; end if;
  -- Moderation dismisses the reports and restores it (service role: no end-user session).
  perform set_config('request.jwt.claim.sub', '', true);
  update public.business_reports set status='dismissed', resolved_at=now()
   where business_id='00000000-0000-0000-0000-0000000166b7';
  update public.businesses set status='approved' where business_id='00000000-0000-0000-0000-0000000166b7';
  -- One new report from a fourth person must not re-hide on old signals.
  perform pg_temp.rep('00000000-0000-0000-0000-000000166005','00000000-0000-0000-0000-0000000166b7','no_exists');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b7') <> 'approved' then
    raise exception 'FAIL: old signals hid a restored listing'; end if;
  -- A reporter whose report was dismissed may report again.
  if pg_temp.rep('00000000-0000-0000-0000-000000166002','00000000-0000-0000-0000-0000000166b7','closed') <> 'ok' then
    raise exception 'FAIL: user could not report again after resolution'; end if;
  if (select count(*) from public.business_reports
       where business_id='00000000-0000-0000-0000-0000000166b7' and reporter_id='00000000-0000-0000-0000-000000166002') <> 2 then
    raise exception 'FAIL: second report after resolution missing'; end if;
end $$;

-- Daily cap comes from trust_settings.
update private.trust_settings set report_daily_limit = 1 where singleton;
do $$ begin
  if pg_temp.rep('00000000-0000-0000-0000-000000166006','00000000-0000-0000-0000-0000000166b9','closed') <> 'ok' then
    raise exception 'FAIL: report under the cap rejected'; end if;
  if pg_temp.rep('00000000-0000-0000-0000-000000166006','00000000-0000-0000-0000-0000000166b6','closed') <> 'report_limit_reached' then
    raise exception 'FAIL: report over the daily cap accepted'; end if;
end $$;
update private.trust_settings set report_daily_limit = 10 where singleton;

-- The threshold is a parameter too.
update private.trust_settings set report_threshold = 1 where singleton;
do $$ begin
  perform pg_temp.rep('00000000-0000-0000-0000-000000166003','00000000-0000-0000-0000-0000000166b9','inappropriate');
  if pg_temp.status_of('00000000-0000-0000-0000-0000000166b9') <> 'under_review' then
    raise exception 'FAIL: threshold parameter ignored'; end if;
end $$;
update private.trust_settings set report_threshold = 3 where singleton;

-- Owner's panel: aggregate count only, for the owner only.
set local role authenticated;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000166001',true);
do $$ begin
  if public.get_business_open_report_count('00000000-0000-0000-0000-0000000166b2') <> 4 then
    raise exception 'FAIL: owner open-report count wrong'; end if;
end $$;
select set_config('request.jwt.claim.sub','00000000-0000-0000-0000-000000166002',true);
do $$ declare denied boolean := false; begin
  begin perform public.get_business_open_report_count('00000000-0000-0000-0000-0000000166b2');
  exception when insufficient_privilege then denied := true; end;
  if not denied then raise exception 'FAIL: non-owner read the report count'; end if;
end $$;
reset role;

rollback;
