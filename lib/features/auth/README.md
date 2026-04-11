# Auth Feature

## Responsibility
Handles authentication and profile lifecycle: email login/signup, Google login, session observation, and profile completion.

## Dependencies
- `core/failures.dart`
- Supabase auth and user profile tables
- Shared onboarding providers for onboarding completion flag

## Key Entities / Usecases / Providers
- **Entities:** `AppUser`, `AuthScreenText`
- **Usecases:** `LogInWithEmailUsecase`, `SignUpWithEmailUsecase`, `SignInWithGoogleUsecase`, `UpdateProfileUsecase`, `HasProfileUsecase`
- **Providers:** `authRepositoryProvider`, `authSessionProvider`, `profileStreamProvider`

## Routes
- `AuthRoutes.authSelection`
- `AuthRoutes.loginEmail`
- `AuthRoutes.signupEmail`
- `AuthRoutes.createPassword`
- `AuthRoutes.completeProfile`

## Notes / Extension Points
- Keep navigation cross-feature through route constants, not direct screen imports.
- Keep datasource-level mapping/errors and repository-level failure translation.
