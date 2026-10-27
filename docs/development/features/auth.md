# Auth Feature

## Responsibility
Handles authentication and profile lifecycle: email login/signup, Google login, session observation, and profile completion.

## Dependencies
- `core/failures.dart`
- Supabase auth and user profile tables
- RPC `cancel_my_deletion()` (OUR-153) for the account deletion grace period
- Shared onboarding providers for onboarding completion flag

## Key Entities / Usecases / Providers
- **Entities:** `AppUser`, `AuthScreenText`
- **Usecases:** `LogInWithEmailUsecase`, `SignUpWithEmailUsecase`, `SignInWithGoogleUsecase`, `UpdateProfileUsecase`, `HasProfileUsecase`, `CancelMyDeletionUsecase`
- **Providers:** `authRepositoryProvider`, `authSessionProvider`, `profileStreamProvider`, `sessionExpiryProvider`, `accountRestoreProvider`

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
- Account deletion grace period (D10 of [OUR-142](../plans/our-142-account-deletion.md), OUR-154): `accountRestoreProvider` calls `cancel_my_deletion()` on `signedIn` (email or Google), `initialSession` (session restored at startup) and `tokenRefreshed`, once per user per run. It works off the auth events, so it never blocks the sign-in. A failure (offline, expired token) is only logged and retried on the next auth event for that user or the next app start; a `signedOut` clears the checked users, because a deletion requested on the web revokes the sessions and the person signs back in during the same run. When the RPC returns `true`, `AccountRestoredListener` shows "Restauramos tu cuenta" with `showOurnegoDialog`, but only once the router leaves the auth and onboarding routes, so the profile guard's redirect (to the map or to `completeProfile`) never closes it.
- Offline: repositories map network errors to `NetworkFailure` (via `lib/core/network/network_error_classifier.dart`), the router sends the account check to `accountCheckFailed`, and `OurnegoOfflineBanner` shows a global banner and refreshes remote providers when connectivity returns.
- Keep datasource-level mapping/errors and repository-level failure translation.
- Google login on Android depends on the signing key of each build mode being registered as an Android OAuth client; see [OUR-129](../plans/our-129-google-sign-in-android.md) for the per-mode fingerprints and setup.

## UI Refactor Notes
- This feature is one of the most migrated to shared UI presets.
- Prefer `OurnegoPageLayout`, `OurnegoInputField`, the `lib/shared/widgets/buttons/` family, and `OurnegoSnackbars` for new auth screens/flows.
- Avoid inline `InputDecoration`/`styleFrom` unless there is a feature-specific visual requirement that cannot be represented by current shared presets.
