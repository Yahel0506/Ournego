-- OUR-115 - End-to-end check of the listing lifecycle (request, review,
-- rejection and fix, approval, withdrawal) with independent roles.
-- Run after the OUR-111/112/113 scripts. It runs as ONE statement and always
-- ends by raising an exception, so the transaction is rolled back and nothing
-- is stored. A failed check raises "FAIL: ..."; success raises
-- "PASS: ..." followed by the step log.

do $$
declare
  owner_id    constant uuid := '00000000-0000-0000-0000-000000115a01';
  other_id    constant uuid := '00000000-0000-0000-0000-000000115a02';
  reviewer_id constant uuid := '00000000-0000-0000-0000-000000115a03';
  biz         constant uuid := '00000000-0000-0000-0000-0000000115b1';
  n int;
  v text;
  log text := '';

begin
  insert into auth.users (id, aud, role, email) values
    (owner_id,    'authenticated', 'authenticated', 'owner115@test.invalid'),
    (other_id,    'authenticated', 'authenticated', 'other115@test.invalid'),
    (reviewer_id, 'authenticated', 'authenticated', 'reviewer115@test.invalid');
  insert into public.reviewers (user_id) values (reviewer_id);

  -- 1. Owner requests the listing (insert as pending) ------------------------
  perform set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', owner_id), true);
  execute 'set local role authenticated';
  insert into public.businesses (business_id, owner_id, name, type, status)
    values (biz, owner_id, 'Prueba 115 alta', 1, 'pending');
  begin
    insert into public.businesses (business_id, owner_id, name, status)
      values ('00000000-0000-0000-0000-0000000115b2', owner_id, 'self-approved', 'approved');
    raise exception 'FAIL: owner inserted an approved listing';
  exception when insufficient_privilege or check_violation then null; end;
  select count(*) into n from public.businesses where business_id = biz;
  if n <> 1 then raise exception 'FAIL: owner cannot see own pending listing'; end if;
  log := log || E'\n1 owner requests; sees own pending; cannot self-approve';

  -- 2. Pending listing invisible to anon and other accounts (map, search, link)
  foreach v in array array['anon', 'other'] loop
    execute 'reset role';
    if v = 'anon' then
      perform set_config('request.jwt.claims', '{"role":"anon"}', true);
      execute 'set local role anon';
    else
      perform set_config('request.jwt.claims',
        format('{"sub":"%s","role":"authenticated"}', other_id), true);
      execute 'set local role authenticated';
    end if;
    select count(*) into n from public.businesses
      where status = 'approved' and is_active;           -- map listing
    if exists (select 1 from public.businesses where business_id = biz)
       or exists (select 1 from public.businesses where name ilike '%Prueba 115%')
       or exists (select 1 from public.businesses
                  where status = 'approved' and is_active and business_id = biz) then
      raise exception 'FAIL: % can see the pending listing', v;
    end if;
  end loop;
  log := log || E'\n2 pending invisible to anon and other account (by id, by name, in map list)';

  -- 3. Non-reviewers cannot decide ----------------------------------------------
  update public.businesses set status = 'approved' where business_id = biz;
  get diagnostics n = row_count;
  if n > 0 then raise exception 'FAIL: other account approved a listing'; end if;
  execute 'reset role';
  perform set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', owner_id), true);
  execute 'set local role authenticated';
  begin
    update public.businesses set status = 'approved' where business_id = biz;
    raise exception 'FAIL: owner approved own listing';
  exception when insufficient_privilege then null; end;
  begin
    perform 1 from public.reviewers;
    get diagnostics n = row_count;
    if n > 0 then raise exception 'FAIL: owner reads the reviewers list'; end if;
  exception when insufficient_privilege then null; end;
  log := log || E'\n3 other account and owner cannot approve; reviewers list not readable';

  -- 4. Reviewer rejects with reason; owner sees it and fixes ---------------------
  execute 'reset role';
  perform set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', reviewer_id), true);
  execute 'set local role authenticated';
  begin
    update public.businesses set status = 'rejected', rejection_reason = '  '
      where business_id = biz;
    raise exception 'FAIL: rejected without a reason';
  exception when others then
    if sqlerrm like 'FAIL:%' then raise; end if;
  end;
  update public.businesses set status = 'rejected', rejection_reason = 'Falta direccion'
    where business_id = biz;
  execute 'reset role';
  select status::text into v from public.businesses where business_id = biz;
  if v <> 'rejected' then raise exception 'FAIL: reject not applied (%)', v; end if;

  perform set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', owner_id), true);
  execute 'set local role authenticated';
  select rejection_reason into v from public.businesses where business_id = biz;
  if v is distinct from 'Falta direccion' then
    raise exception 'FAIL: owner does not see the rejection reason (%)', v;
  end if;
  update public.businesses set address = 'Calle 1 #2', status = 'pending'
    where business_id = biz;
  execute 'reset role';
  select status::text || '/' || coalesce(rejection_reason, '-') into v
    from public.businesses where business_id = biz;
  if v <> 'pending/-' then raise exception 'FAIL: resubmission state (%)', v; end if;
  log := log || E'\n4 reject needs a reason; owner sees it, fixes and resubmits (reason cleared)';

  -- 5. Reviewer approves -> visible to everyone, incl. direct link ---------------
  perform set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', reviewer_id), true);
  execute 'set local role authenticated';
  update public.businesses set status = 'approved' where business_id = biz;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  if not exists (select 1 from public.businesses
                 where business_id = biz and status = 'approved' and is_active)
     or not exists (select 1 from public.businesses where name ilike '%Prueba 115%') then
    raise exception 'FAIL: approved listing not visible to anon';
  end if;
  log := log || E'\n5 approved listing visible to anon by id and by name';

  -- 6. Owner edit of public data returns it to review ----------------------------
  execute 'reset role';
  perform set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', owner_id), true);
  execute 'set local role authenticated';
  update public.businesses set name = 'Prueba 115 renombrado' where business_id = biz;
  execute 'reset role';
  select status::text into v from public.businesses where business_id = biz;
  if v <> 'pending' then raise exception 'FAIL: edit of approved listing stayed public (%)', v; end if;
  perform set_config('request.jwt.claims',
    format('{"sub":"%s","role":"authenticated"}', reviewer_id), true);
  execute 'set local role authenticated';
  update public.businesses set status = 'approved' where business_id = biz;
  execute 'reset role';
  log := log || E'\n6 editing public data of an approved listing sends it back to review';

  -- 7. Reviewer withdraws with reason -> invisible, no public leftovers ----------
  execute 'set local role authenticated';
  update public.businesses set status = 'withdrawn', rejection_reason = 'Cierre definitivo'
    where business_id = biz;
  execute 'reset role';
  perform set_config('request.jwt.claims', '{"role":"anon"}', true);
  execute 'set local role anon';
  if exists (select 1 from public.businesses where business_id = biz)
     or exists (select 1 from public.businesses where name ilike '%Prueba 115%')
     or exists (select 1 from public.business_hours where business_id = biz)
     or exists (select 1 from public.business_products where business_id = biz)
     or exists (select 1 from public.business_exceptions where business_id = biz) then
    raise exception 'FAIL: withdrawn listing leaves public data';
  end if;
  begin
    perform 1 from public.business_review_log;
    raise exception 'FAIL: anon reads the review log';
  exception when insufficient_privilege then null; end;
  execute 'reset role';
  log := log || E'\n7 withdrawn listing: no row, no hours/products/exceptions for anon; log denied to anon';

  -- 8. Log keeps the whole timeline ----------------------------------------------
  select string_agg(coalesce(from_status::text, '-') || '>' || to_status::text, ' ' order by created_at, id)
    into v from public.business_review_log where business_id = biz;
  log := log || E'\n8 log: ' || coalesce(v, '(empty)');

  raise exception 'PASS: lifecycle verified (rolled back)%', log;
end $$;
