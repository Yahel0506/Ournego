import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';

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
}
