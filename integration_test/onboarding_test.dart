import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/routing/route_names.dart';

import '../test/fakes/fake_auth_repository.dart';
import '../test/fakes/fake_map_repository.dart';
import '../test/fakes/fake_onboarding_repository.dart';
import '../test/helpers/app_helper.dart';

void main() {
  group('Onboarding y sesion', () {
    patrolTest(
      '1) Usuario nuevo ve onboarding completo y el flag queda guardado en storage',
      tags: ['onboarding', 'auth', 'critical'],
      ($) async {
        await resetAppState();

        final onboardingRepository = FakeOnboardingRepository(hasSeen: false);
        final authState = StreamController<bool>.broadcast();
        authState.add(false);

        await $.pumpWidgetAndSettle(
          buildTestApp([
            ...onboardingOverrides(onboardingRepository),
            ...authOverrides(
              FakeAuthRepository(state: FakeAuthState.unauthenticated),
              sessionStream: authState.stream,
            ),
            ...mapOverrides(FakeMapRepository()),
          ], startOnMap: false),
        );

        expect(find.byKey(const ValueKey('onboardingScreen')), findsOneWidget);

        await $.tester.tap(
          find.byKey(const ValueKey('onboardingExploreContinueButton')),
        );
        await $.pumpAndSettle();

        await $.tester.tap(
          find.byKey(const ValueKey('onboardingDiscoverContinueButton')),
        );
        await $.pumpAndSettle();

        await $.tester.tap(
          find.byKey(const ValueKey('activateLocationButton')),
        );
        await $.pumpAndSettle();

        if (await $.native.isPermissionDialogVisible()) {
          await $.native.grantPermissionWhenInUse();
          await $.pumpAndSettle();
        }

        await $.tester.tap(find.byKey(const ValueKey('guestAccessButton')));
        await $.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('hasSeenOnboarding'), isTrue);

        await authState.close();
      },
    );

    patrolTest(
      '2) Usuario que ya completó onboarding salta directo a la pantalla de login',
      tags: ['onboarding', 'auth'],
      ($) async {
        await resetAppState();

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('hasSeenOnboarding', true);

        final authState = StreamController<bool>.broadcast();
        authState.add(false);

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                FakeAuthRepository(state: FakeAuthState.unauthenticated),
                sessionStream: authState.stream,
              ),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: true,
            initialLocation: AuthRoutes.loginEmail,
          ),
        );

        expect(find.byKey(const ValueKey('loginEmailScreen')), findsOneWidget);

        await authState.close();
      },
    );

    patrolTest(
      '3) Usuario con sesión activa válida entra a la app sin pasar por login',
      tags: ['onboarding', 'auth', 'critical'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        authState.add(true);

        await $.pumpWidgetAndSettle(
          buildTestApp([
            ...authOverrides(
              FakeAuthRepository(state: FakeAuthState.authenticatedAsCustomer),
              sessionStream: authState.stream,
              initialSessionStatus: true,
            ),
            ...mapOverrides(FakeMapRepository()),
          ], startOnMap: true),
        );

        expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);
        expect(find.byKey(const ValueKey('authSelectionScreen')), findsNothing);

        await authState.close();
      },
    );

    patrolTest(
      '4) Usuario con token expirado es redirigido a login sin crash ni spinner infinito',
      tags: ['onboarding', 'auth', 'critical'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        authState.add(false);

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                FakeAuthRepository(state: FakeAuthState.expiredToken),
                sessionStream: authState.stream,
              ),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: true,
            initialLocation: BusinessRoutes.form,
          ),
        );

        expect(
          find.byKey(const ValueKey('authSelectionScreen')),
          findsOneWidget,
        );
        expect(find.byType(CircularProgressIndicator), findsNothing);

        await authState.close();
      },
    );

    patrolTest(
      '5) Usuario que cierra la app a mitad del onboarding mantiene el progreso real actual',
      tags: ['onboarding'],
      ($) async {
        await resetAppState();

        final onboardingRepository = FakeOnboardingRepository(hasSeen: false);
        final authState = StreamController<bool>.broadcast();
        authState.add(false);

        await $.pumpWidgetAndSettle(
          buildTestApp([
            ...onboardingOverrides(onboardingRepository),
            ...authOverrides(
              FakeAuthRepository(state: FakeAuthState.unauthenticated),
              sessionStream: authState.stream,
            ),
            ...mapOverrides(FakeMapRepository()),
          ], startOnMap: false),
        );

        await $.tester.tap(
          find.byKey(const ValueKey('onboardingExploreContinueButton')),
        );
        await $.pumpAndSettle();

        final prefsBefore = await SharedPreferences.getInstance();
        expect(prefsBefore.getBool('hasSeenOnboarding'), isNot(true));

        await $.pumpWidgetAndSettle(
          buildTestApp([
            ...onboardingOverrides(onboardingRepository),
            ...authOverrides(
              FakeAuthRepository(state: FakeAuthState.unauthenticated),
              sessionStream: authState.stream,
            ),
            ...mapOverrides(FakeMapRepository()),
          ], startOnMap: false),
        );

        expect(find.byKey(const ValueKey('onboardingScreen')), findsOneWidget);

        await authState.close();
      },
    );

    patrolTest(
      '6) Logout manual -> próxima apertura solicita credenciales',
      tags: ['onboarding', 'auth', 'critical'],
      ($) async {
        await resetAppState();

        final authState = StreamController<bool>.broadcast();
        authState.add(true);

        final repository = FakeAuthRepository(
          state: FakeAuthState.authenticatedAsCustomer,
          onLogout: () => authState.add(false),
        );

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                repository,
                sessionStream: authState.stream,
                initialSessionStatus: true,
              ),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: true,
            initialLocation: MapRoutes.map,
          ),
        );

        expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);

        await $.tester.tap(find.byKey(const ValueKey('mapProfileButton')));
        await $.pumpAndSettle();
        await $.tester.tap(find.byKey(const ValueKey('confirmLogoutButton')));
        await $.pumpAndSettle();

        expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);

        await $.pumpWidgetAndSettle(
          buildTestApp(
            [
              ...authOverrides(
                repository,
                sessionStream: authState.stream,
                initialSessionStatus: false,
              ),
              ...mapOverrides(FakeMapRepository()),
            ],
            startOnMap: true,
            initialLocation: BusinessRoutes.form,
          ),
        );

        expect(
          find.byKey(const ValueKey('authSelectionScreen')),
          findsOneWidget,
        );

        await authState.close();
      },
    );
  });
}
