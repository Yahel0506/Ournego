# Onboarding Feature

## Responsibility
Manages onboarding slides and onboarding completion flag persistence.

## Dependencies
- Shared preferences via local datasource
- Router route for onboarding entry

## Key Entities / Usecases / Providers
- **Entities:** `Slide`
- **Usecases:** `GetHasSeenOnboardingUsecase`, `SetHasSeenOnboardingUsecase`
- **Providers:** `onboardingRepositoryProvider`, `slidesListProvider`, onboarding flag usecase providers

## Routes
- `AppRoutes.onboarding`

## Notes / Extension Points
- Keep `hasSeenOnboarding` persistence in datasource/repository, not directly in UI widgets.
- Use `SlideModel` for serialized/data-layer transformations.
