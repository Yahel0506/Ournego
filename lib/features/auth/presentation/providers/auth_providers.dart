import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/auth/data/datasources/local_auth_screen_text_datasource.dart';
import 'package:ournego/features/auth/data/datasources/local_error_messages_datasource.dart';
import 'package:ournego/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:ournego/features/auth/data/repositories/supabase_auth_repository_impl.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:ournego/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:ournego/features/auth/domain/usecases/has_profile_usecase.dart';
import 'package:ournego/features/auth/domain/usecases/log_in_with_email_usecase.dart';
import 'package:ournego/features/auth/domain/usecases/log_out_usecase.dart';
import 'package:ournego/features/auth/domain/usecases/sign_in_with_google_usecase.dart';
import 'package:ournego/features/auth/domain/usecases/sign_up_with_email_usecase.dart';
import 'package:ournego/features/auth/domain/usecases/update_profile_usecase.dart';

// |---------------------------------| \\
// |------- LAYER 1: DATASOURCES ---| \\
// |---------------------------------| \\

/// Provides the Supabase auth datasource instance.
final supabaseAuthDatasourceProvider = Provider<SupabaseAuthDatasource>((ref) {
  return SupabaseAuthDatasource();
});

/// Provides UI text content for auth screens.
final authScreenTextProvider = Provider<LocalAuthScreenTextDatasource>((ref) {
  return LocalAuthScreenTextDatasource();
});

/// Provides error messages for auth failures.
final authErrorMessagesProvider = Provider<LocalErrorMessagesDatasource>((ref) {
  return LocalErrorMessagesDatasource();
});

// |---------------------------------| \\
// |------- LAYER 2: REPOSITORIES --| \\
// |---------------------------------| \\

/// Provides the auth repository implementation.
/// All auth operations should go through this repository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(supabaseAuthDatasourceProvider);
  return AuthRepositoryImpl(authDatasource: datasource);
});

// |---------------------------------| \\
// |------- LAYER 3: USECASES ------| \\
// |---------------------------------| \\

/// Usecase for signing up with email and password.
final signUpWithEmailUsecaseProvider = Provider<SignUpWithEmailUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return SignUpWithEmailUsecase(repository: repository);
});

/// Usecase for logging in with email and password.
final logInWithEmailUsecaseProvider = Provider<LogInWithEmailUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogInWithEmailUsecase(repository: repository);
});

/// Usecase for signing in with Google.
final signInWithGoogleUsecaseProvider = Provider<SignInWithGoogleUsecase>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithGoogleUsecase(repository);
});

/// Usecase for logging out.
final logOutUsecaseProvider = Provider<LogOutUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogOutUsecase(repository: repository);
});

/// Usecase for getting user profile.
final getProfileUsecaseProvider = Provider<GetProfileUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetProfileUsecase(repository: repository);
});

/// Usecase for updating user profile.
final updateProfileUsecaseProvider = Provider<UpdateProfileUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return UpdateProfileUsecase(repository: repository);
});

/// Usecase for checking/confirming profile status.
final hasProfileUsecaseProvider = Provider<HasProfileUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return HasProfileUsecase(repository: repository);
});

// |---------------------------------| \\
// |------- LAYER 4: STATE ---------| \\
// |---------------------------------| \\

/// Stream provider for the current user's profile.
/// Emits [AppUser] whenever the profile data changes.
final profileStreamProvider = StreamProvider<AppUser>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetProfileUsecase(repository: repository)();
});

/// Stream provider for auth session state.
/// Emits `true` when user is logged in, `false` otherwise.
///
/// This is the primary provider for checking auth state.
/// Use [authSessionStatusProvider] for synchronous access.
final authSessionProvider = StreamProvider<bool>((ref) async* {
  final auth = Supabase.instance.client.auth;

  // First value avoids transient loading/error UI on web.
  // currentUser fallback helps when session hydration lags on web.
  yield auth.currentSession != null || auth.currentUser != null;

  yield* auth.onAuthStateChange
      .map(
        (event) =>
            event.session != null ||
            Supabase.instance.client.auth.currentUser != null,
      )
      .distinct();
});

/// Synchronous provider for current auth status.
/// Returns `true` if user is logged in, `false` otherwise.
///
/// Use this when you need immediate access to auth state
/// without waiting for stream updates.
final authSessionStatusProvider = Provider<bool>((ref) {
  final authState = ref.watch(authSessionProvider);
  return authState.maybeWhen(
    data: (isLogged) => isLogged,
    orElse: () => Supabase.instance.client.auth.currentUser != null,
  );
});

/// Provides the current user's ID if authenticated, null otherwise.
/// Useful for operations that need the user ID without full profile data.
final currentUserIdProvider = Provider<String?>((ref) {
  final isLoggedIn = ref.watch(authSessionStatusProvider);
  if (!isLoggedIn) return null;
  return Supabase.instance.client.auth.currentUser?.id;
});

/// Family provider to get a specific user's profile by ID.
/// Useful for viewing other users' profiles (e.g., business owners).
final userProfileByIdProvider = StreamProvider.family<AppUser, String>((
  ref,
  userId,
) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getProfile(userId: userId);
});
