import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

void main() {
  Widget host(Widget child) => MaterialApp(
    theme: OurnegoTheme.light,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('filter toggles', (tester) async {
    var selected = false;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => OurnegoChip.filter(
            label: 'Abiertos',
            selected: selected,
            onSelected: (value) => setState(() => selected = value),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsNothing);
    await tester.tap(find.text('Abiertos'));
    await tester.pump(kBoingDuration);
    expect(selected, isTrue);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.text('Abiertos'));
    await tester.pump(kBoingDuration);
    expect(selected, isFalse);
  });

  testWidgets('dropdown opens, picks an option and shows the placeholder '
      'for null', (tester) async {
    double? value = 1000;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) => SizedBox(
            width: 180,
            child: OurnegoChip<double?>.dropdown(
              placeholder: 'Distancia',
              value: value,
              options: const [
                OurnegoChipOption(value: null, label: 'Sin límite'),
                OurnegoChipOption(value: 1000, label: '1 km'),
                OurnegoChipOption(value: 5000, label: '5 km'),
              ],
              onChanged: (next) => setState(() => value = next),
            ),
          ),
        ),
      ),
    );

    expect(find.text('1 km'), findsOneWidget);

    await tester.tap(find.text('1 km'));
    await tester.pumpAndSettle();
    expect(find.text('5 km'), findsOneWidget);

    await tester.tap(find.text('5 km'));
    await tester.pumpAndSettle();
    expect(value, 5000);
    expect(find.text('5 km'), findsOneWidget);

    await tester.tap(find.text('5 km'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sin límite'));
    await tester.pumpAndSettle();
    expect(value, isNull);
    expect(find.text('Distancia'), findsOneWidget);
  });
}
