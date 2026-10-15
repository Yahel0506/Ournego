import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/ournego_popover_surface.dart';

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

  group('dropdown options open as a popover below the chip', () {
    const options = [
      OurnegoChipOption<double?>(value: null, label: 'Sin límite'),
      OurnegoChipOption<double?>(value: 1000, label: '1 km'),
      OurnegoChipOption<double?>(value: 5000, label: '5 km'),
    ];

    Future<List<double?>> pumpChip(
      WidgetTester tester, {
      double? value = 1000,
    }) async {
      final picks = <double?>[];
      await tester.pumpWidget(
        host(
          SizedBox(
            width: 180,
            child: OurnegoChip<double?>.dropdown(
              placeholder: 'Distancia',
              value: value,
              options: options,
              onChanged: picks.add,
            ),
          ),
        ),
      );
      return picks;
    }

    testWidgets('it is an Ournego popover, not a Material menu', (
      tester,
    ) async {
      await pumpChip(tester);
      await tester.tap(find.text('1 km'));
      await tester.pumpAndSettle();

      expect(find.byType(OurnegoPopoverSurface), findsOneWidget);
      expect(find.byType(MenuAnchor), findsNothing);
      expect(find.byType(MenuItemButton), findsNothing);
      for (var i = 0; i < options.length; i++) {
        expect(find.byKey(ValueKey('chipOption_$i')), findsOneWidget);
      }
    });

    testWidgets('it sits below the chip and is at least as wide as it', (
      tester,
    ) async {
      await pumpChip(tester);
      final chip = tester.getRect(find.byType(OurnegoChip<double?>));
      await tester.tap(find.text('1 km'));
      await tester.pumpAndSettle();

      final popover = tester.getRect(find.byType(OurnegoPopoverSurface));
      expect(popover.top, greaterThan(chip.bottom));
      expect(popover.width, greaterThanOrEqualTo(chip.width));
    });

    testWidgets('it grows out of the chip', (tester) async {
      await pumpChip(tester);
      final chip = tester.getRect(find.byType(OurnegoChip<double?>));
      await tester.tap(find.text('1 km'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final early = tester
          .renderObject<RenderContainerTransformDestination>(
            find.byType(ContainerTransformDestination),
          )
          .lastPaintedRect!;
      expect((early.center - chip.center).distance, lessThan(60));
      await tester.pumpAndSettle();
    });

    testWidgets('the current value is marked', (tester) async {
      await pumpChip(tester, value: 5000);
      await tester.tap(find.text('5 km'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chipOption_2')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('chipOption_1')),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
    });

    testWidgets('choosing "no limit" reports null, not "dismissed"', (
      tester,
    ) async {
      final picks = await pumpChip(tester);
      await tester.tap(find.text('1 km'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chipOption_0')));
      await tester.pumpAndSettle();

      expect(picks, [null]);
      expect(find.byType(OurnegoPopoverSurface), findsNothing);
    });

    testWidgets('closing it without choosing reports nothing', (tester) async {
      final picks = await pumpChip(tester);
      await tester.tap(find.text('1 km'));
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(picks, isEmpty);
      expect(find.byType(OurnegoPopoverSurface), findsNothing);
    });

    testWidgets('the chip stays reachable after it closes', (tester) async {
      final picks = await pumpChip(tester);
      for (var round = 0; round < 2; round++) {
        await tester.tap(find.text('1 km'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('chipOption_2')));
        await tester.pumpAndSettle();
      }
      expect(picks, [5000, 5000]);
    });
  });
}
