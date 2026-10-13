import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart' as gsi;

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/data/datasources/local_error_messages_datasource.dart';
import 'package:ournego/features/auth/data/repositories/supabase_auth_repository_impl.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/auth/presentation/widgets/auth_selection_widget.dart';
import 'package:ournego/features/onboarding/domain/usecases/set_has_seen_onboarding_usecase.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';

import '../../fakes/fake_auth_repository.dart';

class _ScriptedGoogleRepository extends FakeAuthRepository {
  _ScriptedGoogleRepository(this.results);

  final List<Either<Failure, void>> results;
  int calls = 0;

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    final index = calls < results.length ? calls : results.length - 1;
    calls++;
    return results[index];
  }
}

class _NoopSetHasSeenOnboarding implements SetHasSeenOnboardingUsecase {
  @override
  Future<void> call() async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('googleSignInFailureFor', () {
    Failure mapCode(gsi.GoogleSignInExceptionCode code) =>
        googleSignInFailureFor(gsi.GoogleSignInException(code: code));

    test('maps a cancelled sign-in to its own failure', () {
      expect(
        mapCode(gsi.GoogleSignInExceptionCode.canceled),
        isA<GoogleSignInCancelledFailure>(),
      );
    });

    test('maps configuration and UI errors to the unavailable failure', () {
      for (final code in [
        gsi.GoogleSignInExceptionCode.clientConfigurationError,
        gsi.GoogleSignInExceptionCode.providerConfigurationError,
        gsi.GoogleSignInExceptionCode.uiUnavailable,
      ]) {
        expect(mapCode(code), isA<GoogleSignInUnavailableFailure>());
      }
    });

    test('maps the remaining codes and unknown errors to ServerFailure', () {
      for (final code in [
        gsi.GoogleSignInExceptionCode.interrupted,
        gsi.GoogleSignInExceptionCode.userMismatch,
        gsi.GoogleSignInExceptionCode.unknownError,
      ]) {
        expect(mapCode(code), isA<ServerFailure>());
      }
      expect(googleSignInFailureFor(StateError('boom')), isA<ServerFailure>());
    });

    test('maps connectivity errors to NetworkFailure', () {
      expect(
        googleSignInFailureFor(const SocketException('offline')),
        isA<NetworkFailure>(),
      );
    });
  });

  group('getGoogleSignInErrorMessage', () {
    final messages = LocalErrorMessagesDatasource();

    test('gives a distinct, retry-friendly message per failure', () {
      final cancelled = messages.getGoogleSignInErrorMessage(
        GoogleSignInCancelledFailure(),
      );
      final unavailable = messages.getGoogleSignInErrorMessage(
        GoogleSignInUnavailableFailure(),
      );
      final generic = messages.getGoogleSignInErrorMessage(ServerFailure());
      final offline = messages.getGoogleSignInErrorMessage(NetworkFailure());

      expect({cancelled, unavailable, generic, offline}.length, 4);
      expect(cancelled, contains('Cancelaste'));
      expect(offline, contains('Sin conexión'));
    });

    test('never exposes the raw failure', () {
      for (final failure in <Failure>[
        GoogleSignInCancelledFailure(),
        GoogleSignInUnavailableFailure(),
        ServerFailure(),
        NetworkFailure(),
      ]) {
        final message = messages.getGoogleSignInErrorMessage(failure);
        expect(message, isNot(contains('Instance of')));
        expect(message, isNot(contains('Failure')));
      }
    });
  });

  group('GoogleLoginButton', () {
    Future<_ScriptedGoogleRepository> pumpButton(
      WidgetTester tester,
      List<Either<Failure, void>> results, {
      VoidCallback? onSuccess,
    }) async {
      final repository = _ScriptedGoogleRepository(results);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(repository),
            setHasSeenOnboardingUsecaseProvider.overrideWithValue(
              _NoopSetHasSeenOnboarding(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: GoogleLoginButton(
                  config: AuthSelectionWidget(onSuccess: onSuccess),
                ),
              ),
            ),
          ),
        ),
      );
      return repository;
    }

    testWidgets('shows a clear message and a retry action on failure', (
      tester,
    ) async {
      final repository = await pumpButton(tester, [
        Left(GoogleSignInUnavailableFailure()),
      ]);

      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        find.textContaining('No pudimos abrir el inicio de sesión de Google'),
        findsOneWidget,
      );
      expect(find.textContaining('Instance of'), findsNothing);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(repository.calls, 1);
    });

    testWidgets('tells the user when the sign-in was cancelled', (
      tester,
    ) async {
      await pumpButton(tester, [Left(GoogleSignInCancelledFailure())]);

      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Cancelaste el inicio de sesión'), findsOne);
      expect(find.text('Reintentar'), findsOneWidget);
    });

    testWidgets('retry runs the sign-in again and succeeds', (tester) async {
      var succeeded = 0;
      final repository = await pumpButton(tester, [
        Left(ServerFailure()),
        const Right(null),
      ], onSuccess: () => succeeded++);

      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(succeeded, 0);

      await tester.tap(find.byKey(const ValueKey('snackbarAction')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(repository.calls, 2);
      expect(succeeded, 1);
      expect(find.text('Reintentar'), findsNothing);
    });

    testWidgets('shows no message when the sign-in succeeds', (tester) async {
      var succeeded = 0;
      await pumpButton(tester, [
        const Right(null),
      ], onSuccess: () => succeeded++);

      await tester.tap(find.text('Continuar con Google'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(succeeded, 1);
      expect(find.text('Reintentar'), findsNothing);
    });
  });
}
