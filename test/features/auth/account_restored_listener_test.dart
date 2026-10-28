import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:ournego/features/auth/presentation/providers/account_restore_providers.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/auth/presentation/providers/session_expiry_providers.dart';
import 'package:ournego/features/auth/presentation/widgets/account_restored_listener.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.cancelled);

  final bool cancelled;

  @override
  Future<Either<Failure, bool>> cancelMyDeletion() async => Right(cancelled);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _session = Session(
  accessToken: 'token',
  tokenType: 'bearer',
  user: const User(
    id: 'u1',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: '2026-10-27T00:00:00Z',
  ),
);

void main() {
  late StreamController<AuthState> events;

  setUp(() {
    events = StreamController<AuthState>.broadcast();
    addTearDown(events.close);
  });

  Future<(GoRouter, ProviderContainer)> pumpApp(
    WidgetTester tester, {
    required String initialLocation,
    bool cancelled = true,
  }) async {
    final navigatorKey = GlobalKey<NavigatorState>();
    GoRoute route(String path) => GoRoute(
      path: path,
      builder: (context, state) => Scaffold(body: Text('page $path')),
    );
    final router = GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: initialLocation,
      routes: [
        route(MapRoutes.map),
        route(AuthRoutes.authSelection),
        route(AuthRoutes.completeProfile),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authEventsProvider.overrideWithValue(events.stream),
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(cancelled),
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          builder: (context, child) => AccountRestoredListener(
            router: router,
            navigatorKey: navigatorKey,
            child: child!,
          ),
        ),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AccountRestoredListener)),
    );
    return (router, container);
  }

  Future<void> signIn(WidgetTester tester) async {
    events.add(AuthState(AuthChangeEvent.signedIn, _session));
    await tester.pumpAndSettle();
  }

  testWidgets('shows the notice once the deletion is cancelled', (
    tester,
  ) async {
    final (_, container) = await pumpApp(
      tester,
      initialLocation: MapRoutes.map,
    );

    await signIn(tester);

    expect(find.byType(OurnegoAlertDialog), findsOneWidget);
    expect(
      find.textContaining('Tu cuenta estaba programada para eliminarse'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('account-restored-ok')));
    await tester.pumpAndSettle();

    expect(find.byType(OurnegoAlertDialog), findsNothing);
    expect(container.read(accountRestoreProvider), AccountRestoreStatus.none);
  });

  testWidgets('waits for the profile guard to leave the auth routes', (
    tester,
  ) async {
    final (router, _) = await pumpApp(
      tester,
      initialLocation: AuthRoutes.authSelection,
    );

    await signIn(tester);
    expect(find.byType(OurnegoAlertDialog), findsNothing);

    // The guard sends an account without profile to complete it.
    router.go(AuthRoutes.completeProfile);
    await tester.pumpAndSettle();

    expect(find.text('page ${AuthRoutes.completeProfile}'), findsOneWidget);
    expect(find.byType(OurnegoAlertDialog), findsOneWidget);
  });

  testWidgets('shows nothing when there was nothing to cancel', (tester) async {
    await pumpApp(tester, initialLocation: MapRoutes.map, cancelled: false);

    await signIn(tester);

    expect(find.byType(OurnegoAlertDialog), findsNothing);
  });

  test('auth and onboarding routes are not settled; the rest are', () {
    expect(
      isSettledLocationForAccountNotice(AuthRoutes.authSelection),
      isFalse,
    );
    expect(
      isSettledLocationForAccountNotice(AuthRoutes.authCompletion),
      isFalse,
    );
    expect(isSettledLocationForAccountNotice(AuthRoutes.loginEmail), isFalse);
    expect(isSettledLocationForAccountNotice(AppRoutes.onboarding), isFalse);
    expect(isSettledLocationForAccountNotice(MapRoutes.map), isTrue);
    expect(
      isSettledLocationForAccountNotice(AuthRoutes.completeProfile),
      isTrue,
    );
  });
}
