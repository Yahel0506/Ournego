# Map Feature

## Responsibility
Renders map experience, location handling, business marker visualization, modal details, favorites, and map-centric interactions.

## Dependencies
- `geolocator` for device location
- `flutter_map` and map tile providers
- Supabase business/favorites data
- Auth state for protected actions (favorites)

## Key Entities / Usecases / Providers
- **Entities:** `Business`, `Product`, `AppPosition`, `MapLocationState`, `ReferenceLocation`, `ManualZone`
- **Usecases:** location and business retrieval/favorite usecases; location access (`CheckLocationAccessUsecase`, `RequestLocationPermissionUsecase`, `EnableLocationServiceUsecase`, `WatchLocationServiceUsecase`); manual zone (`SearchZoneSuggestionsUsecase`, `ResolveZoneFromPointUsecase`, `Get/Save/ClearManualZoneUsecase`)
- **Providers:** `mapProvider` (`AsyncNotifier<MapLocationState>`), `businessProvider`, `selectedBusiness`, `isBusinessFavoriteStreamProvider`

## Routes
- `MapRoutes.map`
- `MapRoutes.businessDetails`

## Notes / Extension Points
- Keep tile fallback behavior for missing Mapbox config.
- Keep permission/denied flows centralized in map presentation state.

## Working without location (OUR-133)

`mapProvider` never ends in error or in an endless loading state. Every location
failure becomes a `LocationAccessStatus` (`granted`, `permissionDenied`,
`permissionDeniedForever`, `serviceDisabled`, `unavailable`) inside
`MapLocationState`, and the map always has a `ReferenceLocation`:
GPS fix → saved manual zone → default zone (Ciudad Guzmán). The reference is
what centers the map and measures distances in search.

| Situation | What the user sees |
|---|---|
| Permission denied (can be asked again) | Nego sheet: **Permitir** (system dialog) / **Continuar sin ubicación**. If dismissed, a persistent banner on the map only. |
| Permission denied for good | Nego sheet: **Elegir mi zona** / **Abrir ajustes**, then a `Zona: X · Cambiar` chip. |
| GPS off | Native "turn on location" dialog (Android, Google Play Services). If declined, banner **Activar**. |

Rules worth keeping:
- Startup never prompts for permission; the system dialog only appears after the user taps **Permitir**.
- The sheet opens once per status change, never in a loop. A declined native GPS dialog is remembered (`serviceDialogOffered`) so coming back to the app does not reopen it.
- The position timeout only counts while the app is in the foreground, because the system dialogs send it to `inactive`.
- The app rechecks on resume and when the device location service is toggled.
- The manual zone (LocationIQ search or "Usar el centro del mapa") is persisted in `SharedPreferences` (`map_manual_zone`). Geocoding lives in `core/geocoding` and is shared with business registration.
- The onboarding still requires the permission (OUR-6); this only covers what happens afterwards.

## UI Refactor Notes
- Map is under active migration to shared UI presets.
- Top navigation now uses shared circular button styles and shared alert dialog patterns in profile/logout flow.
- Floating sheet has partial adoption of shared button presets; remaining inline decorations should be migrated incrementally to preserve visual parity.
- For new map UI work, default to shared dialogs/snackbars/buttons first, then add map-specific presets only when repeated patterns are confirmed.
