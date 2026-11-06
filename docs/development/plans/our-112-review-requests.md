# OUR-112 - Request a listing review and follow the result

Status: client and SQL written; SQL **not applied** and not run against a
database (no local Postgres here). Apply
`docs/sql/2026-11-06_business_review_requests.sql` after the OUR-111 migration,
then run `docs/sql/tests/2026-11-06_business_review_requests_test.sql`.

Based on OUR-111 (`businesses.status`, RLS, `enforce_business_status_change`).

## Assumptions

- Registering already creates the request: rows are inserted as `pending`
  (OUR-111 insert policy), so no separate "submit" step exists for new listings.
- S0 rule (approved in OUR-161, comment on OUR-112): editing name, category,
  address/coordinates, description or images of an `approved` listing sends it
  back to `pending`, and it disappears from the public map until approved again
  (no draft/live split). Phone and hours are published without review.
- A rejected listing keeps its reason while the owner edits; resubmitting
  clears it.

## Schema additions

`rejection_reason text`, `submitted_at timestamptz` (default `now()`),
`reviewed_at timestamptz`. The trigger now also:

- lets the owner move to `pending` (resubmit) or `withdrawn`; never to
  `approved`/`rejected`;
- makes the three columns read-only for non-reviewers;
- stamps `reviewed_at` on a reviewer decision and `submitted_at` on a
  (re)submission; clears the reason on resubmit/approve;
- applies the S0 rule for non-reviewers. Reviewer edits never bounce a listing.

The OUR-111 SQL test was adjusted: re-opening a rejected listing is now
allowed, self-approving it is still blocked.

## Client

- `OwnedBusinessProfile` carries `reviewStatus`, `rejectionReason`,
  `submittedAt`, `reviewedAt`.
- `SubmitBusinessForReviewUsecase` -> datasource update to `pending`, filtered
  to `rejected`/`withdrawn` rows (a stale tap fails instead of no-op).
- Panel: `BusinessPanelReviewStatusCard` (status, reason, date, button) and a
  confirmation dialog before sending; saving an edit on a published listing
  says that it went back to review. The registration form confirms the request.

## Not here

Reviewer screen and decision log (OUR-113); notifications; hours review.

## Known gaps (follow-ups)

- S0 covers `businesses` columns only. Photos are also objects in the public
  bucket `businesses_pictures`; the app uploads with `upsert: true`, so an owner
  calling Storage directly could replace the bytes behind an approved image URL
  without touching `images`. Closing it needs a `storage.objects` policy (no
  overwrite under an approved listing's folder) and unique file names in the
  client. Not done here; needs its own issue.
- Products and exceptions (publicly readable) do not send a listing back to
  review.
- A reviewer who owns a listing can approve it (OUR-113 should decide).
