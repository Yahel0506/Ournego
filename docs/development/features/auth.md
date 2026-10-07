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
- `AuthRoutes.accountCheckFailed` (signed-in user whose verification/profile check failed offline; offers retry or continue to the map)
- `AuthRoutes.authCompletion` (internal redirect after authenticated email/mobile Google success)

## Notes / Extension Points
- Keep navigation cross-feature through route constants, not direct screen imports.
- The internal auth completion route checks the live Supabase session, email verification, and profile before routing to verification, profile completion, or the map. The same checks guard existing logged-in non-shell routes.
- Session loss: `sessionExpiryProvider` flags a `signedOut` event that did not come from `SupabaseAuthDatasource.logOut()`; `SessionExpiredListener` then shows a dialog (sign in again / continue as guest) and `pendingReturnLocationProvider` restores the previous route after re-login. Offline refresh failures are retried by the SDK and never trigger it.
- Offline: repositories map network errors to `NetworkFailure` (via `lib/core/network/network_error_classifier.dart`), the router sends the account check to `accountCheckFailed`, and `OurnegoOfflineBanner` shows a global banner and refreshes remote providers when connectivity returns.
- Keep datasource-level mapping/errors and repository-level failure translation.

## UI Refactor Notes
- This feature is one of the most migrated to shared UI presets.
- Prefer `OurnegoPageLayout`, `OurnegoInputField`, `OurnegoButtonStyles`, and `OurnegoSnackbars` for new auth screens/flows.
- Avoid inline `InputDecoration`/`styleFrom` unless there is a feature-specific visual requirement that cannot be represented by current shared presets.
