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
