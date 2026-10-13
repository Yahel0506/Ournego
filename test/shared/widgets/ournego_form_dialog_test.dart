import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';

void main() {
  Widget host({
    required List<String> calls,
    bool isSaving = false,
    double keyboard = 0,
  }) {
    return MaterialApp(
      theme: OurnegoTheme.light,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(viewInsets: EdgeInsets.only(bottom: keyboard)),
          child: Scaffold(
            body: OurnegoFormDialog(
              title: 'Editar teléfono',
              isSaving: isSaving,
              primaryAction: OurnegoDialogAction(
                key: const ValueKey('primary'),
                label: 'Guardar',
                onPressed: () => calls.add('primary'),
              ),
              secondaryAction: OurnegoDialogAction(
                key: const ValueKey('secondary'),
                label: 'Cancelar',
                onPressed: () => calls.add('secondary'),
              ),
              child: const TextField(key: ValueKey('field')),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders title, body and both actions', (tester) async {
    final calls = <String>[];
    await tester.pumpWidget(host(calls: calls));

    expect(find.text('Editar teléfono'), findsOneWidget);
    expect(find.byKey(const ValueKey('field')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('primary')));
    await tester.tap(find.byKey(const ValueKey('secondary')));
    expect(calls, ['primary', 'secondary']);
  });

  testWidgets('isSaving shows loading and ignores both actions', (
    tester,
  ) async {
    final calls = <String>[];
    await tester.pumpWidget(host(calls: calls, isSaving: true));

    final primary = tester.widget<OurnegoButton>(
      find.byKey(const ValueKey('primary')),
    );
    expect(primary.status, OurnegoButtonStatus.loading);
    expect(primary.onPressed, isNull);
    expect(
      tester
          .widget<OurnegoButton>(find.byKey(const ValueKey('secondary')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('moves above the keyboard', (tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = <String>[];

    await tester.pumpWidget(host(calls: calls));
    final closed = tester.getBottomLeft(find.byKey(const ValueKey('primary')));

    await tester.pumpWidget(host(calls: calls, keyboard: 400));
    await tester.pumpAndSettle();
    final open = tester.getBottomLeft(find.byKey(const ValueKey('primary')));

    expect(open.dy, lessThan(closed.dy));
    expect(open.dy, lessThanOrEqualTo(1200 - 400));
  });
}
