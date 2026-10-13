import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_header.dart';

void main() {
  Future<GoRouter> pump(WidgetTester tester, {required bool isLogged}) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: BusinessPanelHeader(profileImageUrl: '', isLogged: isLogged),
          ),
        ),
        GoRoute(
          path: AuthRoutes.authSelection,
          builder: (_, _) => const Text('auth selection'),
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStatusProvider.overrideWithValue(isLogged),
          profileStreamProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(uid: 'u1', name: 'Ana', email: 'ana@test.com'),
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('with a session the profile button opens the account menu', (
    tester,
  ) async {
    await pump(tester, isLogged: true);

    await tester.tap(find.bySemanticsLabel('Perfil'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('profileMenuDialog')), findsOneWidget);
    // Already in the business panel: no entry to go back to it.
    expect(
      find.byKey(const ValueKey('profileMenuBusinessButton')),
      findsNothing,
    );
  });

  testWidgets('without a session the button goes to the access screen', (
    tester,
  ) async {
    await pump(tester, isLogged: false);

    await tester.tap(find.bySemanticsLabel('Iniciar sesión'));
    await tester.pumpAndSettle();

    expect(find.text('auth selection'), findsOneWidget);
    expect(find.byKey(const ValueKey('profileMenuDialog')), findsNothing);
  });
}
