# Onboarding Feature

## Responsibility
Manages the custom onboarding flow, role selection state, location permission step,
exit transition, and onboarding completion flag persistence.

## Dependencies
- Shared preferences via local datasource
- Router route for onboarding entry

## Key Entities / Usecases / Providers
- **Flow state:** `OnboardingUserRole`
- **Usecases:** `GetHasSeenOnboardingUsecase`, `SetHasSeenOnboardingUsecase`
- **Providers:** `onboardingRepositoryProvider`, onboarding flag usecase providers

## Routes
- `AppRoutes.onboarding`

## Notes / Extension Points
- Keep `hasSeenOnboarding` persistence in datasource/repository, not directly in UI widgets.
- The current flow has 5 screens: explore, discover, location, role selection, and exit transition.
- `slidesListProvider` and hardcoded `SlideModel` data are legacy support from the previous generic flow.

## UI Refactor Notes
- Onboarding informational dialogs are migrated to `OurnegoInformationDialog`.
- Keep onboarding visuals consistent with shared styles before introducing screen-specific UI primitives.
- The screen layout uses local responsive wrappers to preserve the visual direction while avoiding overflows on short screens.
