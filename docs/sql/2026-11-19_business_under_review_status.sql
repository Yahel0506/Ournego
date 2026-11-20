-- OUR-164 / OUR-170: add the moderation state referenced by trust automation.
-- Kept in its own committed transaction because PostgreSQL cannot use a newly
-- added enum label until the transaction that added it has committed.
begin;
alter type public.business_status add value if not exists 'under_review';
commit;
