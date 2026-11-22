# Map feature

## Responsibility

Shows public businesses on the map, search and business deep links. The map
uses GPS when available, a saved manual zone, or Ciudad Guzmán as the pilot
reference. The zone picker also offers the pilot zone without requiring GPS or
a geocoding request.

## Dependencies and flow

`map_providers.dart` connects the presentation layer to map and manual-zone
use cases, repositories, Supabase, geolocation and local zone storage.
`MapNotifier` owns location and manual-zone state. `businessesStreamProvider`
loads businesses and `mapBusinessesProvider` retains the most recent list in
memory during connection failures (OUR-150). Search operates on that list.

An empty catalog offers the zone picker. Empty search results offer to clear
the query and filters. A failed initial load offers retry; retained results
remain visible with a stale-data notice and refresh action. Location denial
keeps the location access sheet and zone picker available (OUR-133). A failed
deep-link lookup offers retry; a missing or unavailable listing shows a notice.

Public map reads require approved status and `is_active` other than false. The
individual lookup applies both filters in its query; the realtime stream filters
activity again on the client because owners and reviewers have wider RLS access.
The public RLS policy in `docs/sql/2026-11-05_business_review_status.sql`
enforces the same rule for public readers. Approval is the publication state;
`published_at` can be null on historical approved rows and verification is
independent of visibility (OUR-164). Owner/reviewer access is intentional for
their private workflows and must not be used to populate the public map.

## Routes and extension points

`MapRoutes.map` and `MapRoutes.businessDetails` are registered in the central
router. Map windows use the shared Ournego window helpers. New map data sources
should preserve the public listing rule, distinguish failures from empty data,
and avoid persisting stale business details across sessions.
