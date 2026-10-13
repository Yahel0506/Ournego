import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/navigation/presentation/widgets/profile_menu/profile_menu_dialog_widget.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_dialog_surface.dart';

void main() {
  Future<List<String>> pumpDialog(
    WidgetTester tester, {
    bool destructive = false,
  }) async {
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: OurnegoTheme.light,
        home: Scaffold(
          body: OurnegoAlertDialog(
            title: 'Cerrar sesión',
            content: '¿Seguro?',
            primaryAction: OurnegoDialogAction(
              key: const ValueKey('primary'),
              label: 'Cerrar sesión',
              isDestructive: destructive,
              onPressed: () => calls.add('primary'),
            ),
            secondaryAction: OurnegoDialogAction(
              key: const ValueKey('secondary'),
              label: 'Cancelar',
              onPressed: () => calls.add('secondary'),
            ),
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('renders both actions with findable keys', (tester) async {
    final calls = await pumpDialog(tester);

    expect(find.byKey(const ValueKey('primary')), findsOneWidget);
    expect(find.byKey(const ValueKey('secondary')), findsOneWidget);

    final primary = tester.widget<OurnegoButton>(
      find.byKey(const ValueKey('primary')),
    );
    final secondary = tester.widget<OurnegoButton>(
      find.byKey(const ValueKey('secondary')),
    );
    expect(primary.tone, OurnegoButtonTone.primary);
    expect(secondary.tone, OurnegoButtonTone.ghost);

    await tester.tap(find.byKey(const ValueKey('secondary')));
    await tester.pump(kBoingDuration);
    await tester.tap(find.byKey(const ValueKey('primary')));
    await tester.pump(kBoingDuration);
    expect(calls, ['secondary', 'primary']);
  });

  testWidgets('isDestructive uses the destructive tone', (tester) async {
    await pumpDialog(tester, destructive: true);
    final primary = tester.widget<OurnegoButton>(
      find.byKey(const ValueKey('primary')),
    );
    expect(primary.tone, OurnegoButtonTone.destructive);
  });

  testWidgets('its padding is the same as the options menu\'s, not excessive', (
    tester,
  ) async {
    // The inset of the options menu is the reference.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authSessionStatusProvider.overrideWithValue(false)],
        child: MaterialApp(
          theme: OurnegoTheme.light,
          home: const Scaffold(body: ProfileMenuDialogWidget()),
        ),
      ),
    );
    final menuSurface = tester.getRect(find.byType(OurnegoDialogSurface));
    final menuInset =
        tester.getRect(find.byType(CircleAvatar)).left - menuSurface.left;

    await pumpDialog(tester);
    final surface = tester.getRect(find.byType(OurnegoDialogSurface));
    final title = tester.getRect(find.text('Cerrar sesión').first);
    final body = tester.getRect(find.text('¿Seguro?'));
    // The bar of actions; the test font is wider than the real one, so the two
    // buttons may stack here, but the bar itself spans the padded width.
    final actions = tester.getRect(find.byType(OverflowBar));

    expect(title.left - surface.left, closeTo(menuInset, 0.5));
    expect(body.left - surface.left, closeTo(menuInset, 0.5));
    expect(surface.right - actions.right, closeTo(menuInset, 1));
    // Top and bottom: the same surface padding as the menu, not 24 on top of 24.
    expect(title.top - surface.top, lessThan(24));
    expect(surface.bottom - actions.bottom, lessThan(24));
    // So the text can use almost the whole width of the dialog.
    expect(surface.width - body.width, lessThan(60));
  });

  testWidgets('it is a plain surface: no Material AlertDialog inside', (
    tester,
  ) async {
    await pumpDialog(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(Dialog), findsNothing);
  });
}
