import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ournego/features/auth/domain/entities/app_user.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/navigation/presentation/widgets/profile_menu/profile_menu_dialog_widget.dart';

void main() {
  Future<ProfileMenuAction?> openAndTap(
    WidgetTester tester, {
    required bool isLogged,
    required Key target,
  }) async {
    ProfileMenuAction? result;

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
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await showProfileMenuDialog(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profileMenuDialog')), findsOneWidget);

    await tester.tap(find.byKey(target));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profileMenuDialog')), findsNothing);
    return result;
  }

  testWidgets('logged-in user can choose log out', (tester) async {
    final result = await openAndTap(
      tester,
      isLogged: true,
      target: const ValueKey('profileMenuLogoutButton'),
    );

    expect(result, ProfileMenuAction.logOut);
  });

  testWidgets('logged-in menu shows profile header and account section', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStatusProvider.overrideWithValue(true),
          profileStreamProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(uid: 'u1', name: 'Ana', email: 'ana@test.com'),
            ),
          ),
        ],
        child: const MaterialApp(home: ProfileMenuDialogWidget()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('ana@test.com'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profileMenuBusinessButton')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profileMenuLogInButton')), findsNothing);
  });

  testWidgets('guest sees log in entry and settings, but no log out', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionStatusProvider.overrideWithValue(false)],
        child: const MaterialApp(home: ProfileMenuDialogWidget()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Invitado'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('profileMenuLocationButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profileMenuFeedbackButton')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('profileMenuLogoutButton')), findsNothing);
    expect(
      find.byKey(const ValueKey('profileMenuBusinessButton')),
      findsNothing,
    );
  });

  testWidgets('guest log in entry returns logIn action', (tester) async {
    final result = await openAndTap(
      tester,
      isLogged: false,
      target: const ValueKey('profileMenuLogInButton'),
    );

    expect(result, ProfileMenuAction.logIn);
  });

  testWidgets('from the business panel the business entry is not offered', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authSessionStatusProvider.overrideWithValue(true),
          profileStreamProvider.overrideWith(
            (ref) => Stream.value(
              const AppUser(uid: 'u1', name: 'Ana', email: 'ana@test.com'),
            ),
          ),
        ],
        child: const MaterialApp(
          home: ProfileMenuDialogWidget(
            origin: ProfileMenuOrigin.businessPanel,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('profileMenuBusinessButton')),
      findsNothing,
    );
    // The section would be empty without that entry.
    expect(find.text('CUENTA'), findsNothing);
    // Everything else stays.
    expect(
      find.byKey(const ValueKey('profileMenuLogoutButton')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('profileMenuFeedbackButton')),
      findsOneWidget,
    );
  });
}
