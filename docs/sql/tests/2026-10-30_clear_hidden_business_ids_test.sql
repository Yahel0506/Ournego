-- OUR-139 - Tests for the trigger that clears hidden_business_ids.
-- Run after 2026-10-30_clear_hidden_business_ids_on_completion.sql.
-- Everything is rolled back; a failing check raises an exception that starts
-- with FAIL.

begin;

insert into auth.users (id, aud, role, email) values
  ('00000000-0000-0000-0000-0000000000d1', 'authenticated', 'authenticated', 'cancel@test.invalid'),
  ('00000000-0000-0000-0000-0000000000d2', 'authenticated', 'authenticated', 'done@test.invalid');
insert into public.businesses (business_id, owner_id, name, is_active) values
  ('00000000-0000-0000-0000-00000000d0b1', '00000000-0000-0000-0000-0000000000d1', 'D1 shop', false);

insert into public.account_deletion_requests
  (id, user_id, email_hash, status, execute_after, hidden_business_ids) values
  ('00000000-0000-0000-0000-0000000000e1', '00000000-0000-0000-0000-0000000000d1',
   repeat('a', 64), 'scheduled', now() + interval '1 day',
   array['00000000-0000-0000-0000-00000000d0b1']::uuid[]),
  ('00000000-0000-0000-0000-0000000000e2', '00000000-0000-0000-0000-0000000000d2',
   repeat('b', 64), 'scheduled', now() - interval '1 minute',
   array['00000000-0000-0000-0000-00000000d0b2']::uuid[]);

-- Cancelling through the RPC still restores the business, then clears the list.
set local role authenticated;
select set_config('request.jwt.claims',
  '{"sub":"00000000-0000-0000-0000-0000000000d1","role":"authenticated"}', true);
do $$ begin
  if not public.cancel_my_deletion() then
    raise exception 'FAIL: cancel_my_deletion returned false';
  end if;
end $$;
reset role;

do $$ begin
  if not (select is_active from public.businesses
          where business_id = '00000000-0000-0000-0000-00000000d0b1') then
    raise exception 'FAIL: business was not restored on cancel';
  end if;
  if (select cardinality(hidden_business_ids) from public.account_deletion_requests
      where id = '00000000-0000-0000-0000-0000000000e1') <> 0 then
    raise exception 'FAIL: hidden_business_ids kept after cancel';
  end if;
end $$;

-- Completing clears the list.
update public.account_deletion_requests
  set status = 'completed', completed_at = now()
  where id = '00000000-0000-0000-0000-0000000000e2';
do $$ begin
  if (select cardinality(hidden_business_ids) from public.account_deletion_requests
      where id = '00000000-0000-0000-0000-0000000000e2') <> 0 then
    raise exception 'FAIL: hidden_business_ids kept after completion';
  end if;
end $$;

rollback;
