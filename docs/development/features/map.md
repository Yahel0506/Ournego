# Map Feature

## Responsibility
Renders map experience, location handling, business marker visualization, modal details, favorites, and map-centric interactions.

## Dependencies
- `geolocator` for device location
- `flutter_map` and map tile providers
- Supabase business/favorites data
- Auth state for protected actions (favorites)

## Key Entities / Usecases / Providers
- **Entities:** `Business`, `Product`, `AppPosition`
- **Usecases:** location and business retrieval/favorite usecases
- **Providers:** `mapProvider`, `businessProvider`, `selectedBusiness`, `isBusinessFavoriteStreamProvider`

## Routes
- `MapRoutes.map`
- `MapRoutes.businessDetails`

## Notes / Extension Points
- Keep tile fallback behavior for missing Mapbox config.
- Keep permission/denied flows centralized in map presentation state.

## UI Refactor Notes
- Map is under active migration to shared UI presets.
- Top navigation now uses shared circular button styles and shared alert dialog patterns in profile/logout flow.
- Floating sheet has partial adoption of shared button presets; remaining inline decorations should be migrated incrementally to preserve visual parity.
- For new map UI work, default to shared dialogs/snackbars/buttons first, then add map-specific presets only when repeated patterns are confirmed.
