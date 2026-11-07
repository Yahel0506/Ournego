# Moderation feature

## Responsibility

Lets authorized staff ("revisoras") resolve listing requests: see the queue of
pending listings, approve, reject (with reason) and withdraw published ones,
and read the history of decisions (OUR-113).

## Dependencies

- Supabase: `businesses`, `reviewers`, `business_review_log` (RLS + triggers).
- `auth` (`currentUserIdProvider`), `business` (`BusinessReviewStatus`,
  panel labels).

## Key pieces

- Entities: `ReviewListing`, `ReviewLogEntry`, `ReviewDecision`.
- Repository: `ModerationRepository` / `ModerationRepositoryImpl`.
- Usecases: `CheckIsReviewerUsecase`, `GetReviewListingsUsecase`,
  `GetReviewLogUsecase`, `DecideBusinessReviewUsecase`.
- Providers (`presentation/providers/moderation_providers.dart`):
  `isReviewerProvider`, `reviewListingsProvider(status)`, `reviewLogProvider(id)`.
- UI: `ModerationScreen` (tabs "Pendientes" / "Publicadas"), `ReviewListingCard`,
  reason dialog and confirmation (`review_decision_flow.dart`), history
  (`ReviewLogDialog`). Entry: "Moderación" in the profile menu, only for
  reviewers.

## Routes

`ModerationRoutes.queue` (`/moderation`), outside the shell. Logged-out users are
sent to sign in; a signed-in account that is not a reviewer sees "no access".

## Security model

The client never grants anything. The server enforces it
(`docs/sql/2026-11-05_business_review_status.sql`,
`2026-11-07_business_review_decisions.sql`):

- Only rows in `public.reviewers` can read the whole queue and set
  `approved` / `rejected` / `withdrawn`; any other account gets an error (or no
  rows) even calling the REST API directly.
- Rejecting or withdrawing needs a non-blank reason (stored in
  `businesses.rejection_reason`, which the owner reads in the business panel).
- A reviewer cannot approve or reject their own listing.
- Every status change is written by trigger to `business_review_log` (actor,
  role, from/to, reason, date). The table is append-only for everyone.
- Approving makes the listing public; withdrawing hides it from map, search and
  detail (public RLS from OUR-111).

## Adding a reviewer

Reviewers are managed only from the dashboard or with the service role:

```sql
insert into public.reviewers (user_id) values ('<auth.users id>');
```

## Notes / extension points

- OUR-114 (validation and duplicates before approving) plugs into the card /
  confirmation step. OUR-116 (reports) can reuse the queue screen.
- The queue is in the app, not the web: the decision was made for the pilot to
  avoid a second client; the rules live in the database, so a web queue later
  needs no new security work.
