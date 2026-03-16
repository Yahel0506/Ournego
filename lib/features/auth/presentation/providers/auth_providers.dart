import 'package:flutter_riverpod/flutter_riverpod.dart';
//import 'package:ournego/features/auth/data/datasources/firebase_auth_datasource.dart';
//import 'package:ournego/features/auth/data/datasources/firestore_auth_datasource.dart';
import 'package:ournego/features/auth/data/datasources/local_auth_screen_text_datasource.dart';
import 'package:ournego/features/auth/data/datasources/local_auth_selection_datasource.dart';
import 'package:ournego/features/auth/data/datasources/local_error_messages_datasource.dart';
import 'package:ournego/features/auth/data/datasources/supabase_auth_datasource.dart';
//import 'package:ournego/features/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'package:ournego/features/auth/data/repositories/supabase_auth_repository_impl.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/domain/entities/auth_selection.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:ournego/features/auth/domain/usecases/get_profile_usecase.dart';
import 'package:ournego/features/auth/domain/usecases/log_out_usecase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/usecases/sign_in_with_google_usecase.dart';

/*final firebaseAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  final localAuthSelectionDatasource = LocalAuthSelectionDatasource();
  final firebaseAuthDatasource = FirebaseAuthDatasource();
  final firestoreAuthDatasource = FirestoreAuthDatasource();
  return FirebaseAuthRepositoryImpl(
    authSelectionDatasource: localAuthSelectionDatasource,
    authDatasource: firebaseAuthDatasource,
    databaseDatasource: firestoreAuthDatasource,
  );
});*/

final supabaseAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  final localAuthSelectionDatasource = LocalAuthSelectionDatasource();
  final supabaseAuthDatasource = SupabaseAuthDatasource();
  return SupabaseAuthRepositoryImpl(
    authSelectionDatasource: localAuthSelectionDatasource,
    authDatasource: supabaseAuthDatasource,
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  //final repository = ref.watch(firebaseAuthRepositoryProvider);
  final repository = ref.watch(supabaseAuthRepositoryProvider);
  return repository;
});

final authSelectionProvider = Provider<AuthSelection>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.getAuthSelectionView();
});

final authScreenTextProvider = Provider<LocalAuthScreenTextDatasource>((ref) {
  final datasource = LocalAuthScreenTextDatasource();
  return datasource;
});

final authErrorMessagesProvider = Provider<LocalErrorMessagesDatasource>((ref) {
  final datasource = LocalErrorMessagesDatasource();
  return datasource;
});

final profileStreamProvider = StreamProvider<AppUser>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return GetProfileUsecase(repository: repository)();
});

final logOutUsecaseProvider = Provider<LogOutUsecase>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return LogOutUsecase(repository: repository);
});

final signInWithGoogleUsecaseProvider = Provider<SignInWithGoogleUsecase>((
  ref,
) {
  final repository = ref.watch(authRepositoryProvider);
  return SignInWithGoogleUsecase(repository);
});

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

final authSessionStatusProvider = Provider<bool>((ref) {
  final authState = ref.watch(authSessionProvider);
  return authState.maybeWhen(
    data: (isLogged) => isLogged,
    orElse: () => Supabase.instance.client.auth.currentUser != null,
  );
});
