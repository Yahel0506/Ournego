import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/features/map/presentation/widgets/search_morph_surface.dart';

const _bar = Rect.fromLTWH(60, 40, 220, 52);

Future<AnimationController> _pumpMorph(WidgetTester tester) async {
  final controller = AnimationController.unbounded(vsync: tester, value: 0);
  addTearDown(controller.dispose);
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SearchMorphSurface(
          progress: controller,
          barRect: _bar,
          panelRect: (size) => Rect.fromLTRB(16, 120, size.width - 16, 700),
          fill: Colors.white,
          preset: kSearchInPlaceSpring,
          child: const Text('contenido', key: Key('content')),
        ),
      ),
    ),
  );
  return controller;
}

Rect _frame(WidgetTester tester) =>
    tester.getRect(find.byKey(SearchMorphSurface.frameKey));

double _contentOpacity(WidgetTester tester) => tester
    .widget<Opacity>(
      find.ancestor(
        of: find.byKey(const Key('content')),
        matching: find.byType(Opacity),
      ),
    )
    .opacity;

void main() {
  testWidgets('at rest it is the bar, and at full progress the panel', (
    tester,
  ) async {
    final controller = await _pumpMorph(tester);
    expect(_frame(tester), _bar);
    expect(_contentOpacity(tester), 0);

    controller.value = 1;
    await tester.pump();
    expect(_frame(tester), const Rect.fromLTRB(16, 120, 384, 700));
    expect(_contentOpacity(tester), 1);
  });

  testWidgets('the content stays hidden until the frame is mostly open', (
    tester,
  ) async {
    final controller = await _pumpMorph(tester);
    controller.value = kSearchInPlaceSpring.contentStart * 0.9;
    await tester.pump();
    expect(_contentOpacity(tester), 0);

    controller.value = kSearchInPlaceSpring.contentEnd;
    await tester.pump();
    expect(_contentOpacity(tester), 1);
  });

  testWidgets(
    'the frame lerps its rect and keeps the bar radius at the start',
    (tester) async {
      final controller = await _pumpMorph(tester);
      controller.value = 0.5;
      await tester.pump();
      final middle = _frame(tester);
      expect(middle.top, lessThan(120));
      expect(middle.bottom, greaterThan(_bar.bottom));
      expect(middle.width, greaterThan(_bar.width));
      expect(find.byType(BackdropFilter), findsNothing);
    },
  );
}
