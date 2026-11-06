# Business feature

## Responsibility

Business registration and the owner's panel: create a listing, edit its data,
and request and follow its publication review (OUR-111, OUR-112).

## Dependencies

- Supabase (`businesses`, `business_hours`, storage bucket `businesses_pictures`).
- LocationIQ geocoding (address suggestions).
- `auth` (`currentUserIdProvider`, session).

## Key pieces

- Entities: `OwnedBusinessProfile`, `BusinessReviewStatus`, `AppSchedule`.
- Repository: `BusinessRepository` / `BusinessRepositoryImpl`.
- Usecases: `RegisterBusinessUsecase`, `GetOwnedBusinessUsecase`,
  `SubmitBusinessForReviewUsecase` and the `Upsert*` / image usecases.
- Providers: `ownedBusinessProvider`, `isOwnerProvider`
  (`presentation/providers/business_providers.dart`).
- Review UI: `BusinessPanelReviewStatusCard` in the owner panel.

## Review flow (OUR-112)

Statuses mirror `businesses.status`: `pending`, `approved`, `rejected`,
`withdrawn`. Only `approved` (and active) listings are public.

| Moment | What happens |
| --- | --- |
| Owner registers a business | Row is created as `pending` and `submitted_at` is set; the form confirms that the request was sent. The panel shows "En revisión". |
| Reviewer approves | Listing becomes public; the panel shows "Publicado". |
| Reviewer rejects | The panel shows "No aprobado" with the reason (`rejection_reason`) and the date. The owner edits the data and taps "Reenviar a revisión" (confirmation dialog) which moves it back to `pending` and clears the reason. |
| Owner withdrew the listing | The panel offers "Solicitar publicación" with the same confirmation. |
| Owner edits public data of an `approved` listing | The server returns it to `pending` (it leaves the public map until approved again). Public data: name, description, category, address/coordinates, images. Phone and hours are published without review. The panel tells the owner after saving. |

The client never sets `approved`/`rejected` and never writes the reason or
decision dates: the trigger `enforce_business_status_change` ignores them for
non-reviewers. The decision UI and log are OUR-113.

SQL: `docs/sql/2026-11-06_business_review_requests.sql` (apply after
`2026-11-05_business_review_status.sql`); tests in
`docs/sql/tests/2026-11-06_business_review_requests_test.sql`. See also
`docs/development/plans/our-112-review-requests.md`.

## Routes

`BusinessRoutes.panel` (shell), `BusinessRoutes.register`, `BusinessRoutes.form`.

## Notes / extension points

- Old clients that edit an approved listing are covered because the S0 rule
  lives in the database, not in the client.
- OUR-113 will add the reviewer screen that sets `approved`/`rejected`.
