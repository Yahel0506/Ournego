import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:ournego/core/routing/route_names.dart';

import '../test/fakes/fake_auth_repository.dart';
import '../test/fakes/fake_business_repository.dart';
import '../test/fakes/fake_map_repository.dart';
import '../test/fakes/fake_onboarding_repository.dart';
import '../test/fixtures/mock_users.dart';
import '../test/helpers/app_helper.dart';

Future<void> _loginWithEmail(PatrolIntegrationTester $) async {
  await $.tester.enterText(
    find.byKey(const ValueKey('loginEmailInput')),
    MockCredentials.validEmail,
  );
  await $.tester.enterText(
    find.byKey(const ValueKey('loginPasswordInput')),
    MockCredentials.validPassword,
  );
  await $.tester.tap(find.byKey(const ValueKey('loginSubmitButton')));
  await $.pumpAndSettle();
}

void main() {
  group('Login por tipo de usuario', () {
    patrolTest(
      '1) Login como cliente normal -> navega a HomeScreen con mapa activo',
      tags: ['auth', 'critical'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        final authRepository = FakeAuthRepository(
          state: FakeAuthState.authenticatedAsCustomer,
          onLogin: (_) => authState.add(true),
        );

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...onboardingOverrides(FakeOnboardingRepository(hasSeen: false)),
              ...authOverrides(
                authRepository,
                sessionStream: authState.stream,
                initialSessionStatus: false,
              ),
              ...businessOverrides(FakeBusinessRepository(isOwner: false)),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: false,
            initialLocation: AuthRoutes.loginEmail,
            authStateChanges: authState.stream,
          ),
        );

        await _loginWithEmail($);

        expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);

        await authState.close();
      },
    );

    patrolTest(
      '2) Login como dueño con negocio registrado -> navega a BusinessDashboard',
      tags: ['auth', 'critical'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        final authRepository = FakeAuthRepository(
          state: FakeAuthState.authenticatedAsOwnerWithBusiness,
          onLogin: (_) => authState.add(true),
        );

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...onboardingOverrides(FakeOnboardingRepository(hasSeen: false)),
              ...authOverrides(
                authRepository,
                sessionStream: authState.stream,
                initialSessionStatus: false,
              ),
              ...businessOverrides(FakeBusinessRepository(isOwner: true)),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: false,
            initialLocation: AuthRoutes.loginEmail,
            authStateChanges: authState.stream,
          ),
        );

        await _loginWithEmail($);
        await $.tester.tap(find.byIcon(Icons.store_rounded));
        await $.pumpAndSettle();

        expect(find.byKey(const ValueKey('businessDashboardScreen')), findsOneWidget);

        await authState.close();
      },
    );

    patrolTest(
      '3) Login como dueño sin negocio -> navega a RegisterBusinessScreen',
      tags: ['auth', 'critical'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        final authRepository = FakeAuthRepository(
          state: FakeAuthState.authenticatedAsOwnerWithoutBusiness,
          onLogin: (_) => authState.add(true),
        );

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...onboardingOverrides(FakeOnboardingRepository(hasSeen: false)),
              ...authOverrides(
                authRepository,
                sessionStream: authState.stream,
                initialSessionStatus: false,
              ),
              ...businessOverrides(FakeBusinessRepository(isOwner: false)),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: false,
            initialLocation: AuthRoutes.loginEmail,
            authStateChanges: authState.stream,
          ),
        );

        await _loginWithEmail($);
        await $.tester.tap(find.byIcon(Icons.store_rounded));
        await $.pumpAndSettle();

        expect(find.byKey(const ValueKey('registerBusinessScreen')), findsOneWidget);

        await authState.close();
      },
    );

    patrolTest(
      '4) Login con credenciales incorrectas -> muestra error legible, no crash',
      tags: ['auth'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        final authRepository = FakeAuthRepository(
          state: FakeAuthState.unauthenticated,
          forceInvalidCredentials: true,
        );

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                authRepository,
                sessionStream: authState.stream,
              ),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: false,
            initialLocation: AuthRoutes.loginEmail,
          ),
        );

        await $.tester.enterText(
          find.byKey(const ValueKey('loginEmailInput')),
          MockCredentials.invalidEmail,
        );
        await $.tester.enterText(
          find.byKey(const ValueKey('loginPasswordInput')),
          MockCredentials.invalidPassword,
        );
        await $.tester.tap(find.byKey(const ValueKey('loginSubmitButton')));
        await $.pumpAndSettle();

        expect(
          find.text('El correo o la contraseña son incorrectos.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('loginEmailScreen')), findsOneWidget);

        await authState.close();
      },
    );

    patrolTest(
      '5) Login sin conexión -> error manejado con mensaje, no estado roto',
      tags: ['auth'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        final authRepository = FakeAuthRepository(
          state: FakeAuthState.authenticatedAsCustomer,
          forceNoConnection: true,
        );

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                authRepository,
                sessionStream: authState.stream,
              ),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: false,
            initialLocation: AuthRoutes.loginEmail,
          ),
        );

        await _loginWithEmail($);

        expect(
          find.text('Ha habido un error. Por favor, inténtalo de nuevo.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('loginEmailScreen')), findsOneWidget);

        await authState.close();
      },
    );

    patrolTest(
      '6) Si hay cuenta suspendida en el modelo: flujo de mensaje claro',
      tags: ['auth'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        final authRepository = FakeAuthRepository(
          state: FakeAuthState.authenticatedAsCustomer,
          forceSuspendedAccount: true,
        );

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                authRepository,
                sessionStream: authState.stream,
              ),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: false,
            initialLocation: AuthRoutes.loginEmail,
          ),
        );

        await _loginWithEmail($);

        // TODO: El modelo actual no expone estado "suspendida" ni Failure dedicado.
        // Comportamiento esperado futuro: mostrar mensaje explícito de suspensión.
        expect(
          find.text('Ha habido un error. Por favor, inténtalo de nuevo.'),
          findsOneWidget,
        );
        expect(find.byKey(const ValueKey('loginEmailScreen')), findsOneWidget);

        await authState.close();
      },
    );
  });
}
