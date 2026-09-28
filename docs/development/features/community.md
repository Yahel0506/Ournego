# Community Feature

## Responsibility
Hosts community-facing screens and future social/community capabilities.

## Dependencies
- Shared UI system (`core/ournego_text_styles.dart`, themed assets)
- Router shell tab integration

## Key Entities / Usecases / Providers
- **Entities:** (scaffold pending)
- **Usecases:** (scaffold pending)
- **Providers:** `communityDatasourceProvider`, `communityRepositoryProvider`

## Routes
- `AppRoutes.community`

## Notes / Extension Points
- Current data/domain are scaffolded for iterative expansion.
- Add concrete entities/usecases before integrating remote/local data.

## UI Refactor Notes
- Community placeholders/coming-soon UI should reuse shared presentation widgets (information card/dialog patterns) instead of custom one-off styles.
- Keep future community UI additions aligned with tokenized spacing/radius and shared button/input presets.
