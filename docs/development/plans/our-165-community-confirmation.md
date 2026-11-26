# OUR-165 - Community confirmation ("¿Conoces este negocio?")

Phase F3 of the community verification plan. A signed-in user answers one
question per business from a card inside the business sheet. The database
decides what the answer is worth; the client never learns that rule.

## Data and rules

Migration: `docs/sql/2026-11-25_business_confirmations.sql`. Test (rolls back):
`docs/sql/tests/2026-11-25_business_confirmations_test.sql`.

- `business_confirmations(business_id, user_id, answer, counted, created_at)`,
  unique per `(business_id, user_id)`; `answer` is `yes | no_exists | unsure`.
- The only write path is `submit_business_confirmation(p_business_id, p_answer)`
  (`security definer`). `anon` and `authenticated` have no insert, update or
  delete grant. Each user reads only their own row, and the `counted` column is
  not readable by clients.
- The first answer wins; repeating the call returns the stored answer.
- Only `approved` and active listings accept answers.
- `counted` is true only when the account is not the owner, has a complete
  profile, is older than `trust_settings.voter_min_age` (3 days) and has not
  reached `trust_settings.voter_daily_limit` (15 per Mexico City day). An
  invalid account can still answer; the function never returns `counted`.
- A counted `no_exists` is what the reports phase reads as a report with reason
  "no existe" (partial index `business_confirmations_no_exists_idx`).

## Client

Business feature: `BusinessConfirmationAnswer`,
`BusinessConfirmationRepository` (+ impl and Supabase datasource),
`GetMyBusinessConfirmationUsecase`, `SubmitBusinessConfirmationUsecase`,
`businessConfirmationProvider` and `BusinessConfirmationCardWidget`, placed in
the expanded content of the map sheet as one more card (no popup or modal).

The card disappears once the server holds an answer; nothing is stored locally.
It is hidden for the business owner and for signed-out users.

## Decision: signed-out users

Signed-out users see no card and no sign-in link. The card is meant to be
discreet, and a prompt on every sheet would push people to sign in only to
answer. Revisit with the response-rate metric (open question 1 of the plan) if
too few answers arrive.

## Status

Applied to the Ournego Supabase project on 25 November 2026 as migration
`business_confirmations` (the SQL file without its `begin`/`commit`). Checked
afterwards: RLS on, 0 rows, no insert for `authenticated`, no access for `anon`,
`counted` unreadable, RPC executable by `authenticated` only.

On 25 November 2026 the migration and the SQL test ran together, with the
migration's `begin`/`commit` removed, in one transaction on the Ournego project
that ended in `rollback`. All checks passed, and a follow-up query confirmed
that the table, the function and the test users were not left behind and that
`voter_daily_limit` is still 15.
