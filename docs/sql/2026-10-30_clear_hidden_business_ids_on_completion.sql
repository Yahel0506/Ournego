-- OUR-139 - Keep only what the privacy policy declares in the retained request
-- record.
-- Plan: docs/development/plans/our-142-account-deletion.md (D7)
--
-- End-to-end test finding: a `completed` request still carried
-- `hidden_business_ids` (ids of businesses that no longer exist). The policy
-- declares only the email hash, dates and status, so the list is cleared when
-- the request reaches `completed` or `cancelled` (a cancelled request of a
-- user deleted later keeps the same record). cancel_my_deletion() reads the
-- list into a variable before the status update, so it still restores them.
create or replace function public.account_deletion_clear_hidden_on_completion()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status in ('completed', 'cancelled') then
    new.hidden_business_ids := '{}';
  end if;
  return new;
end;
$$;

revoke all on function public.account_deletion_clear_hidden_on_completion()
  from public, anon, authenticated;

drop trigger if exists account_deletion_clear_hidden
  on public.account_deletion_requests;
create trigger account_deletion_clear_hidden
  before update on public.account_deletion_requests
  for each row
  when (new.status in ('completed', 'cancelled')
        and old.status is distinct from new.status)
  execute function public.account_deletion_clear_hidden_on_completion();

-- Requests completed before this migration.
update public.account_deletion_requests
  set hidden_business_ids = '{}'
  where status in ('completed', 'cancelled') and hidden_business_ids <> '{}';
