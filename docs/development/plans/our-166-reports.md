# OUR-166 - Business reports and automatic hiding

Phase F5 of the community verification plan. A signed-in user reports a
business with a reason; enough credible reports hide it, reversibly. The
database decides what a report is worth; the client never learns that rule.

## Data and rules

Migration: `docs/sql/2026-11-26_business_reports.sql`. Test (rolls back):
`docs/sql/tests/2026-11-26_business_reports_test.sql`.

- `business_reports(id, business_id, reporter_id, reason, note, status, counted,
  created_at, resolved_at, resolved_by)`. `reason` is `no_exists | closed |
  incorrect_info | inappropriate | duplicate | other` (`other` needs a note,
  max 500 characters). `status` is `open | dismissed | upheld`.
- One open report per user and business (partial unique index). After
  moderation resolves it, the user may report that business again.
- The only write path is `submit_business_report(p_business_id, p_reason,
  p_note)` (`security definer`). Clients have no insert/update/delete grant and
  cannot read `counted`. Users read only their own rows; reviewers read all.
- Only `approved` and active listings accept reports; the owner is rejected.
  A repeated call keeps the open report and returns it.
- Daily cap: `trust_settings.report_daily_limit` (10 per Mexico City day);
  over the cap the call fails with `report_limit_reached`.
- `counted` uses the same validity as a confirmation: complete profile and an
  account older than `trust_settings.voter_min_age`. Invalid accounts can
  report, but their report never counts.
- Hiding: only `no_exists` and `inappropriate`. When `report_threshold` (3)
  distinct valid reporters of the same reason fall inside `report_window`
  (7 days), an `approved` listing moves to `under_review` and loses
  `verified_at`. A counted `no_exists` community answer counts as a
  `no_exists` report (one person counts once). Signals older than the last
  `under_review -> approved` restoration are ignored.
- The hide writes `business_review_log` with `actor_role = 'system'` and reason
  `reports`. The status guard accepts that one transition (status and
  `verified_at` only) only when it comes from the function owner.
- `closed`, `incorrect_info`, `duplicate` and `other` never hide: they stay
  `open` for moderation. Reports also stay `open` while a listing is hidden;
  resolving them (`dismissed` / `upheld`) belongs to the moderation phase.
- `get_business_open_report_count(p_business_id)`: owner-only aggregate for the
  panel notice (no identities). The panel UI is not part of this issue.
- `submit_business_confirmation` is replaced to evaluate the hiding rule right
  after a counted `no_exists` answer.

## Client

Business feature: `BusinessReportReason`, `BusinessReportRepository` (+ impl and
Supabase datasource), `SubmitBusinessReportUsecase`,
`BusinessReportMenuButtonWidget` (a "more" button in the sheet controls that
opens `showOurnegoMenu`) and `BusinessReportDialogWidget` (reasons and note,
opened with `showOurnegoDialog`). The button is hidden for guests and the
owner. The reporter only sees "Recibimos tu reporte."; nothing about the
internal process. Failures: `BusinessReportLimitFailure`,
`BusinessReportUnavailableFailure`.

## Status

Written and tested; **not applied** to the Ournego Supabase project yet.
On 26 November 2026 the migration and the SQL test ran together, with the
migration's `begin`/`commit` removed, in one transaction on the Ournego project
that ended in `rollback`. All checks passed and a follow-up query confirmed the
table, functions and test data were not left behind. Flutter: analysis clean and
607 tests pass.
