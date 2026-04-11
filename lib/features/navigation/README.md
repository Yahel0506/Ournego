# Navigation Feature

## Responsibility
Provides shell layout, bottom navigation interactions, and navigation-specific UI state integration (e.g. feedback shake listener wrapper).

## Dependencies
- `go_router` shell routing and route constants
- Feature tab routes (map, business, community)
- Feedback modal widget/provider

## Key Entities / Usecases / Providers
- **Entities:** n/a (presentation-focused feature)
- **Usecases:** n/a
- **Providers:** `appNavigationBarProvider`, `isFeedbackDialogOpenProvider`

## Routes
- Consumes shell child routes from `app_router.dart`.

## Notes / Extension Points
- Keep this feature decoupled from direct imports of other feature screens in layout widgets.
- Tab routing should remain route-based (`context.go`) instead of page controller coupling.
