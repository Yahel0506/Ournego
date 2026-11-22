# Business feature

## Responsibility and dependencies

Business registration, editing and the owner panel use Supabase businesses,
hours and `businesses_pictures` storage, LocationIQ and the auth session.
`BusinessRepository`, `RegisterBusinessUsecase`, the owner providers and
`BusinessPanelReviewStatusCard` implement these flows.

## Publication and review

`submit_business_listing` validates the profile, data, owned image, hours and
limits, then applies automatic filters. A clean submission becomes `approved`
and public immediately with `published_at`; a doubtful submission becomes
`pending`, hidden from the public and accompanied by a reason code. A direct
legacy insert remains pending and cannot self-publish. Only active `approved`
rows and their public child rows are visible publicly.

The five statuses are `pending` (awaiting review), `approved` (published),
`rejected` (correctable), `withdrawn` (hidden) and `under_review` (hidden
for community review). The owner can edit a rejection and resubmit to pending;
a reviewer can approve or reject it. Owners can withdraw and resubmit except
that an owner cannot withdraw while `under_review`. Reviewer withdrawals show
the reason and date. Clean edits to a published listing stay public; a filter
may instead send it to pending. Changes to name, category, address or position
clear `verified_at`; contact-only edits do not. Verification is distinct from
publication: `verified_at` and `verification_paused` are protected metadata,
not proof that a voting workflow is already implemented.

Historical approved listings remain visible without a new photo; new
submissions and image changes require a valid owned image. The authoritative
server rules are in `docs/sql/2026-11-19_business_under_review_status.sql`
and `docs/sql/2026-11-19_business_trust_submission.sql`, after the earlier
review migrations. Tests are in `docs/sql/tests/`.

## Routes

`BusinessRoutes.panel` (shell), `BusinessRoutes.register` and
`BusinessRoutes.form`. Moderation is owned by `lib/features/moderation`.
