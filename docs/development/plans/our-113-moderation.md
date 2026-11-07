# OUR-113 - Review requests and record decisions

Status: client, SQL and tests written. The SQL was **dry-run** (whole script +
tests inside a transaction that ends in `rollback`) against the Supabase
project: every check passed and nothing persisted. It is **not applied**: apply
`docs/sql/2026-11-07_business_review_decisions.sql` (after OUR-111 and OUR-112,
already applied) before shipping the client, then add reviewers (see
`lib/features/moderation/README.md`) and run
`docs/sql/tests/2026-11-07_business_review_decisions_test.sql` (it rolls back).

## Decisions

- **Where the queue lives:** in the app (`/moderation`), visible only to
  reviewers. The security does not depend on it (all in the database), so a web
  queue can be added later. Chosen to avoid a second client in the pilot.
- **Who is authorized:** rows in `public.reviewers` (OUR-111), managed from the
  dashboard / service role. No role UI in the app.
- **Log:** `business_review_log`, filled by an `AFTER INSERT OR UPDATE` trigger
  on `businesses`, so every route (app, REST, SQL as an end user) leaves a
  record. It also logs owner moves (request, resubmit, own withdrawal, the S0
  return to review) with `actor_role`, giving the full timeline. Append-only:
  no insert/update/delete grant for `anon` / `authenticated`.
- **Reason:** required (non-blank, trimmed) to reject **and** to withdraw; it is
  stored in `businesses.rejection_reason` so the owner sees it in OUR-112's
  panel (now also for a withdrawal). Approving or re-opening clears it; an
  owner's own withdrawal or resubmission clears it too.
- **Decision date:** `reviewed_at` is stamped for approve, reject and withdraw.
- **Self-review:** a reviewer cannot approve or reject a listing they own (the
  open gap noted in OUR-112). They can still withdraw or re-submit it as owner.
- **Transitions:** the client only offers approve/reject on `pending` and
  withdraw on `approved`, using a status filter so a stale tap (someone else
  decided first) fails with "ya cambió de estado" instead of overwriting. The
  database does not restrict reviewer transitions further (OUR-111/112 tests
  rely on it); the service role is unrestricted.
- **Reviewer name:** the log stores `actor_id`; the UI shows the role ("Revisión")
  because `users` is not readable across accounts.

## Not here

- Notifications to the owner (the result shows in the panel; no push/email).
- Validation / duplicate detection (OUR-114), reports (OUR-116).
- Storage hardening for images of unpublished listings (see OUR-112 gaps).
