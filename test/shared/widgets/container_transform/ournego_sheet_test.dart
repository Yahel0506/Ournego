import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_sheet_surface.dart';

const _content = Key('content');
const _button = Key('button');

Rect _painted(WidgetTester tester) => tester
    .renderObject<RenderContainerTransformDestination>(
      find.byType(ContainerTransformDestination),
    )
    .lastPaintedRect!;

Future<void> _pump(
  WidgetTester tester, {
  required void Function(Object? result) onResult,
  bool fromButton = false,
}) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: ContainerTransformTrigger(
            radius: 24,
            builder: (context, origin) => GestureDetector(
              key: _button,
              behavior: HitTestBehavior.opaque,
              onTap: () async => onResult(
                await showOurnegoSheet<String>(
                  context: context,
                  origin: fromButton ? origin : null,
                  builder: (_) => const SizedBox(
                    key: _content,
                    height: 200,
                    width: double.infinity,
                    child: Text('hoja'),
                  ),
                ),
              ),
              child: const SizedBox(width: 60, height: 60),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('without an origin it rises from below the screen', (
    tester,
  ) async {
    await _pump(tester, onResult: (_) {});
    await tester.tap(find.byKey(_button));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect(_painted(tester).top, greaterThan(800 - 100));
    await tester.pumpAndSettle();
    final rest = _painted(tester);
    // Docked: its rounded bottom is just below the screen edge.
    expect(rest.bottom, closeTo(800 + OurnegoSheetSurface.hiddenBelow, 1));
    expect(rest.width, closeTo(400, 1));
  });

  testWidgets('from a button it grows out of it', (tester) async {
    await _pump(tester, onResult: (_) {}, fromButton: true);
    final button = tester.getRect(find.byKey(_button));
    await tester.tap(find.byKey(_button));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    expect((_painted(tester).center - button.center).distance, lessThan(300));
    expect(_painted(tester).width, lessThan(400));
    await tester.pumpAndSettle();
  });

  testWidgets('a tap on the scrim closes it and the result is null', (
    tester,
  ) async {
    Object? result = 'pending';
    await _pump(tester, onResult: (r) => result = r);
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(200, 40));
    await tester.pumpAndSettle();
    expect(find.byKey(_content), findsNothing);
    expect(result, isNull);
  });

  testWidgets('a short drag down springs back', (tester) async {
    await _pump(tester, onResult: (_) {});
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();
    final rest = _painted(tester);

    final gesture = await tester.startGesture(const Offset(200, 640));
    await gesture.moveBy(const Offset(0, 30));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    expect(_painted(tester).top, greaterThan(rest.top + 10));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(_content), findsOneWidget);
    expect(_painted(tester).top, closeTo(rest.top, 1));
  });

  testWidgets('a long drag down closes it', (tester) async {
    Object? result = 'pending';
    await _pump(tester, onResult: (r) => result = r);
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();

    final gesture = await tester.startGesture(const Offset(200, 640));
    for (var i = 0; i < 4; i++) {
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump(const Duration(milliseconds: 400));
    }
    await gesture.up();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.byKey(_content), findsNothing);
    expect(result, isNull);
  });

  testWidgets('a fast fling down closes it', (tester) async {
    await _pump(tester, onResult: (_) {});
    await tester.tap(find.byKey(_button));
    await tester.pumpAndSettle();

    await tester.fling(find.byKey(_content), const Offset(0, 80), 1500);
    await tester.pumpAndSettle();
    expect(find.byKey(_content), findsNothing);
  });
}
