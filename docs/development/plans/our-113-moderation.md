# OUR-113 - Moderation and decisions

The current model is defined by the review migrations and the two
`2026-11-19` trust migrations in `docs/sql/`. Clean submissions are published
immediately; automatic filters send doubtful submissions to `pending` with a
`pending_issue_code`. Publication and community verification are separate:
`published_at` records publication, while `verified_at` and
`verification_paused` are trust metadata. The current migration adds and
protects these fields; it does not implement a community voting workflow.

`/moderation` is restricted to members of `public.reviewers`. Its current
client displays pending and published listings. Pending listings may be
approved or rejected; published listings may be withdrawn. The database also
allows a reviewer to restore or withdraw an `under_review` listing. An owner
cannot resolve their own listing even if they are a reviewer. Reviewer
transitions are constrained to `pending → approved/rejected`,
`approved → withdrawn` and `under_review → approved/withdrawn`.
Rejection and reviewer withdrawal require a nonblank reason; approval stamps
`reviewed_at` and `published_at` if needed. Approval of a pending listing
requires valid basic data and an owned image. Restoring a historical
`under_review` listing does not require a replacement image.

Owners can correct rejected listings and resubmit them to `pending`, or withdraw
and later resubmit, subject to validation and capacity. An owner cannot
withdraw an `under_review` listing. Clean edits of published data remain
public; an automatic filter can move an edited listing to `pending` and record
the reason. Identity edits clear `verified_at`. Existing approved listings
retain visibility and may keep their historical image until it is changed.

`business_review_log` records status changes with actor, transition and reason.
Automatic publication and filter decisions are attributed to `system`; owner
and reviewer actions are attributed accordingly. Owners can read their own
history, reviewers can read the queue and history, and clients cannot write the
log directly. Public RLS exposes only active `approved` listings and their
related public rows. See the SQL tests in `docs/sql/tests/`; they require a
Supabase-compatible database with all migrations applied and roll back fixtures.
