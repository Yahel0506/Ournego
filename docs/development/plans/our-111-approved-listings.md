# OUR-111 - Only approved listings are public

Status: SQL written and dry-run (rolled back) against the Supabase project;
**not applied**. Apply `docs/sql/2026-11-05_business_review_status.sql` before
shipping the client that filters on `status`, then run
`docs/sql/tests/2026-11-05_business_review_status_test.sql`.

## Model

- `businesses.status public.business_status not null` with values `pending`,
  `approved`, `rejected`, `withdrawn`. Existing rows are migrated as
  `approved`; the default for new rows is `pending`.
- `public.reviewers (user_id)`: allow-list of reviewers, managed with the
  service role / dashboard. `public.is_reviewer()` reads it.
- `public.is_business_public(uuid)`: approved and not hidden (`is_active`).

## Access rules (RLS)

| Actor | Read | Write |
| --- | --- | --- |
| public / anon | `status = 'approved' and is_active` | none |
| other signed-in user | same as public | none |
| owner | own listings in any status | insert only as `pending`; edits own fields; status may only move to `withdrawn` |
| reviewer | every listing | any status (trigger `enforce_business_status_change`) |

`business_hours`, `business_products` and `business_exceptions` follow the
parent: public reads only for public listings; owners and reviewers read the
rest. `is_active = false` (account deletion) hides even approved listings.

## Client

`SupabaseMapDatasource.getBusinesses/getBusinessById` also filter on
`status = 'approved'` and `is_active` (`isPublicListing`), so an owner or
reviewer session never shows unpublished listings on the public map.

## Out of scope / follow-ups

- Owner request flow and pending/rejected labels: OUR-112. Moderation and
  decision log: OUR-113.
- Storage bucket `businesses_pictures` stays publicly readable by URL; images
  of unpublished listings are reachable only by someone who has the URL.
- `reviews`, `businesses_views`, `user_interactions` and `user_favorites` still
  allow public reads keyed by `business_id`; they hold no listing content.
- Existing owner policies on `business_products`, `business_exceptions` and
  `reviews` compare `id` instead of `business_id`; not touched here.
