# Moderation feature

## Responsibility and dependencies

Authorized reviewers use `/moderation` to inspect pending and published
listings, approve or reject pending submissions, withdraw published listings,
and inspect decision history. The app uses Supabase `businesses`, `reviewers`
and `business_review_log`, the auth session and business status entities.
`ModerationRepository`, review usecases and providers back the screen.

## Current model and security

Clean submissions publish automatically; filters queue doubtful submissions
with a reason. Public access is limited to active `approved` rows. `pending`,
`rejected`, `withdrawn` and `under_review` are not public. Publication does
not imply community verification: `verified_at` and `verification_paused` are
protected metadata, and a community voting workflow is not supplied by these
migrations.

The database, not the UI, restricts decisions to reviewers and prevents
self-review. Reviewer transitions are pending to approved/rejected, approved
to withdrawn, and under_review to approved/withdrawn. Reasons are required for
rejection and reviewer withdrawal. Pending approval checks basic data and an
owned photo. The client also runs `checkListing` and presents blocking issues
and duplicate warnings; its extra checks are not a substitute for server
validation. The current UI tabs expose pending and approved, not a dedicated
under-review queue.

The append-only `business_review_log` records status changes. Automatic filter
and publication decisions use the system actor; owners can read their own
history and reviewers can read all history. See
`docs/development/plans/our-113-moderation.md` and the review and trust
migrations in `docs/sql/` for details.

## Adding a reviewer

Manage the allow-list through the dashboard or service role:

```sql
insert into public.reviewers (user_id) values ('<auth.users id>');
```
