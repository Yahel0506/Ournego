import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/motion/ournego_motion_level.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

const _trigger = Key('trigger');
const _item = Key('item');
const _surface = Key('surface');

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

RenderContainerTransformDestination _destination(WidgetTester tester) =>
    tester.renderObject<RenderContainerTransformDestination>(
      find.byType(ContainerTransformDestination),
    );

Rect _rect(WidgetTester tester) => _destination(tester).lastPaintedRect!;

/// The clock `p` of the open window.
double _progress(WidgetTester tester) => ContainerTransformScope.maybeOf(
  tester.element(find.byType(ContainerTransformDestination)),
)!.animation.value;

/// The blur sigma applied to the content right now (0 when there is none).
double _blur(WidgetTester tester) {
  final filtered = tester.widget<ImageFiltered>(
    find.descendant(
      of: find.byType(ContainerTransformDestination),
      matching: find.byType(ImageFiltered),
    ),
  );
  if (!filtered.enabled) return 0;
  final match = RegExp(
    r'blur\(([\d.]+),',
  ).firstMatch('${filtered.imageFilter}');
  return double.parse(match!.group(1)!);
}

/// Whether the trigger is hidden (opacity 0) at this moment.
bool _triggerHidden(WidgetTester tester) {
  final opacity = tester.widget<Opacity>(
    find.descendant(
      of: find.byType(ContainerTransformTrigger),
      matching: find.byType(Opacity),
    ),
  );
  return opacity.opacity == 0;
}

class _Harness {
  Object? result;
  bool itemTapped = false;
  bool resultSet = false;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  bool disableAnimations = false,
  bool withDestination = true,
  bool dismissible = true,
}) async {
  final harness = _Harness();
  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(disableAnimations: disableAnimations),
          child: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ContainerTransformTrigger(
                  radius: 22,
                  color: Colors.teal,
                  builder: (context, origin) => GestureDetector(
                    key: _trigger,
                    behavior: HitTestBehavior.opaque,
                    onTap: () async {
                      final value = await showOurnegoDialog<String>(
                        context: context,
                        origin: origin,
                        barrierDismissible: dismissible,
                        builder: (_) {
                          final surface = SizedBox(
                            key: _surface,
                            width: 300,
                            height: 200,
                            child: ColoredBox(
                              color: Colors.white,
                              child: Center(
                                child: GestureDetector(
                                  key: _item,
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    harness.itemTapped = true;
                                    Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop('chosen');
                                  },
                                  child: const SizedBox(
                                    width: 120,
                                    height: 48,
                                    child: Text('Aceptar'),
                                  ),
                                ),
                              ),
                            ),
                          );
                          return Center(
                            child: withDestination
                                ? ContainerTransformDestination(child: surface)
                                : surface,
                          );
                        },
                      );
                      harness.result = value;
                      harness.resultSet = true;
                    },
                    child: const SizedBox(width: 44, height: 44),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  return harness;
}

void main() {
  setUp(() => OurnegoMotion.containerTransformEnabled.value = true);

  testWidgets('grows out of the trigger and settles on the surface', (
    tester,
  ) async {
    await _pump(tester);
    final triggerRect = tester.getRect(find.byKey(_trigger));

    await tester.tap(find.byKey(_trigger));
    await tester.pump();
    await _frames(tester, 1);

    // First frames: still on top of the trigger.
    final start = _rect(tester);
    expect((start.center - triggerRect.center).distance, lessThan(30));
    expect(start.width, lessThan(120));

    await tester.pumpAndSettle();
    final end = _rect(tester);
    expect(end.size, const Size(300, 200));
    expect(tester.getRect(find.byKey(_surface)), end);
    expect(find.byKey(_item), findsOneWidget);
  });

  testWidgets('the trigger steps aside while the window is open', (
    tester,
  ) async {
    await _pump(tester);
    expect(_triggerHidden(tester), isFalse);

    await tester.tap(find.byKey(_trigger));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_triggerHidden(tester), isTrue);

    // It keeps its place in the layout.
    expect(tester.getSize(find.byKey(_trigger)), const Size(44, 44));

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(_triggerHidden(tester), isFalse);
  });

  testWidgets('pop returns the value, as showDialog does, while it closes', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_item));
    await tester.pump();
    // The future completes when the pop starts (like showDialog's), so the
    // caller can already chain the next window; this one is still animating.
    expect(harness.result, 'chosen');
    expect(find.byKey(_item), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byKey(_item), findsNothing);
  });

  testWidgets('back and a tap on the scrim close it', (tester) async {
    final harness = await _pump(tester);

    await tester.tap(find.byKey(_trigger));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(_item), findsNothing);
    expect(harness.resultSet, isTrue);

    harness.resultSet = false;
    await tester.tap(find.byKey(_trigger));
    await tester.pumpAndSettle();
    await tester.tapAt(const Offset(5, 590));
    await tester.pumpAndSettle();
    expect(find.byKey(_item), findsNothing);
    expect(harness.resultSet, isTrue);
  });

  testWidgets('a non-dismissible window ignores the scrim', (tester) async {
    await _pump(tester, dismissible: false);
    await tester.tap(find.byKey(_trigger));
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(5, 590));
    await tester.pumpAndSettle();
    expect(find.byKey(_item), findsOneWidget);
  });

  testWidgets('the scrim responds from the first frame', (tester) async {
    final harness = await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();
    await _frames(tester, 2);

    await tester.tapAt(const Offset(5, 590));
    await tester.pumpAndSettle();

    expect(harness.resultSet, isTrue);
    expect(find.byKey(_item), findsNothing);
  });

  testWidgets('items do not respond until they are half visible', (
    tester,
  ) async {
    final harness = await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();
    await _frames(tester, 2);

    // The item is in the tree from the first frame...
    expect(find.byKey(_item), findsOneWidget);
    // ...but a tap on it does not reach it yet: it falls on the scrim, which
    // does respond, and closes the window.
    await tester.tap(find.byKey(_item), warnIfMissed: false);
    expect(harness.itemTapped, isFalse);
    await tester.pumpAndSettle();
    expect(find.byKey(_item), findsNothing);

    // Once it is half visible it is a normal button.
    await tester.tap(find.byKey(_trigger));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(_item));
    expect(harness.itemTapped, isTrue);
  });

  testWidgets('reversing mid-way is continuous: no jump in the rect', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();

    final widths = <double>[];
    // Open until the container is about half way.
    for (var i = 0; i < 120; i++) {
      await _frames(tester, 1);
      widths.add(_rect(tester).width);
      if (widths.last > 160) break;
    }
    expect(widths.last, inExclusiveRange(160, 290));
    final openStep = _maxStep(widths);

    // Change of mind.
    await tester.binding.handlePopRoute();
    final closing = <double>[widths.last];
    for (var i = 0; i < 120; i++) {
      await _frames(tester, 1);
      if (find.byType(ContainerTransformDestination).evaluate().isEmpty) break;
      closing.add(_rect(tester).width);
    }
    expect(closing.length, greaterThan(5));

    // Nothing moves more in one frame than it did while opening.
    expect(_maxStep(closing), lessThan(openStep * 1.25));
    // And it ends back on the trigger.
    await tester.pumpAndSettle();
    expect(find.byKey(_item), findsNothing);
    expect(_triggerHidden(tester), isFalse);
  });

  testWidgets('the content travels with the container, it does not stay put', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();
    await _frames(tester, 1);

    final distances = <double>[];
    final itemStarts = <Offset>[];
    for (var i = 0; i < 40; i++) {
      await _frames(tester, 1);
      final container = _rect(tester).center;
      final item = tester.getCenter(find.byKey(_item));
      // The item sits at the middle of the surface, so it rides the middle of
      // the container the whole way.
      distances.add((item - container).distance);
      itemStarts.add(item);
    }
    expect(distances.every((d) => d < 1), isTrue, reason: '$distances');

    await tester.pumpAndSettle();
    final finalItem = tester.getCenter(find.byKey(_item));
    // Early on it is far from where it ends: it moves, it is not revealed in
    // place.
    expect((itemStarts.first - finalItem).distance, greaterThan(80));
  });

  testWidgets('it starts gently: no snap in the first frames', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();
    await _frames(tester, 1);
    final start = _rect(tester);

    await _frames(tester, 3);
    final early = _rect(tester);
    await tester.pumpAndSettle();
    final end = _rect(tester);

    final progress = (early.width - start.width) / (end.width - start.width);
    expect(progress, lessThan(0.25), reason: 'after about 50 ms');
  });

  testWidgets('it takes a calm amount of time to settle', (tester) async {
    await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();

    var frames = 0;
    final end = Size(300, 200);
    while (frames < 120) {
      await _frames(tester, 1);
      frames++;
      final r = _rect(tester);
      if ((r.width - end.width).abs() < 1.5 &&
          (r.height - end.height).abs() < 1.5) {
        break;
      }
    }
    // About a third of a second, not a snap and not sluggish.
    expect(frames * 16, inInclusiveRange(250, 520));
  });

  testWidgets('the content appears fully blurred and stays so while it travels', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();

    final samples = <(double, double, double)>[];
    for (var i = 0; i < 80; i++) {
      await _frames(tester, 1);
      samples.add((
        _progress(tester),
        _blur(tester),
        _destination(tester).lastContentOpacity,
      ));
    }
    const maxBlur = 12.0;

    // The content is already visible while the container is still travelling...
    final early = samples.where((s) => s.$1 >= 0.35 && s.$1 <= 0.55);
    expect(early, isNotEmpty);
    expect(early.every((s) => s.$3 == 1), isTrue, reason: '$early');
    // ...and fully blurred: the same strong blur the whole time, not easing.
    expect(
      samples
          .where((s) => s.$1 >= 0.08 && s.$1 <= 0.55)
          .every((s) => s.$2 == maxBlur),
      isTrue,
      reason: '$samples',
    );
  });

  testWidgets(
    'the blur clears in the last moments and ends with the container',
    (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(_trigger));
      await tester.pump();

      final samples = <(double, double)>[];
      for (var i = 0; i < 120; i++) {
        await _frames(tester, 1);
        samples.add((_progress(tester), _blur(tester)));
        if (_progress(tester) >= 1) break;
      }
      // It really goes through the clearing, not a jump.
      final clearing = samples.where((s) => s.$1 > 0.7 && s.$1 < 0.99).toList();
      expect(clearing.length, greaterThan(4));
      for (var i = 1; i < clearing.length; i++) {
        expect(clearing[i].$2, lessThanOrEqualTo(clearing[i - 1].$2));
      }
      expect(clearing.first.$2, greaterThan(clearing.last.$2));
      // Gradual: no frame changes the blur by more than a fifth of its range.
      var worst = 0.0;
      for (var i = 1; i < samples.length; i++) {
        final step = (samples[i].$2 - samples[i - 1].$2).abs();
        if (step > worst) worst = step;
      }
      expect(worst, lessThan(12 / 5));

      // It is gone at the exact moment the container's animation finishes.
      await tester.pumpAndSettle();
      expect(_progress(tester), 1);
      expect(_blur(tester), 0);
    },
  );

  testWidgets('opening curves: Y leans in, passes its end slightly, settles', (
    tester,
  ) async {
    await _pump(tester);
    final trigger = tester.getRect(find.byKey(_trigger));
    await tester.tap(find.byKey(_trigger));
    await tester.pump();

    final path = <Offset>[];
    final sizes = <Size>[];
    for (var i = 0; i < 90; i++) {
      await _frames(tester, 1);
      final r = _rect(tester);
      path.add(r.center);
      sizes.add(r.size);
    }
    final end = _rect(tester);
    final travelY = end.center.dy - trigger.center.dy;
    final travelX = end.center.dx - trigger.center.dx;

    // It passes where it ends by a few percent of the travel, not more...
    final peakY = path.map((o) => o.dy).reduce((a, b) => a > b ? a : b);
    final overshoot = (peakY - end.center.dy) / travelY;
    expect(overshoot, inInclusiveRange(0.015, 0.06));
    // ...late in the path, and comes back to exactly where it ends.
    final peakAt = path.indexWhere((o) => o.dy == peakY);
    expect(peakAt, greaterThan(path.length ~/ 6));
    expect(path.last.dy, closeTo(end.center.dy, 0.5));

    // The path is a curve, not a diagonal: Y runs ahead of X.
    final lead = [
      for (final o in path)
        (o.dy - trigger.center.dy) / travelY -
            (o.dx - trigger.center.dx) / travelX,
    ].reduce((a, b) => a > b ? a : b);
    expect(lead, greaterThan(0.1));

    // The other axis takes the plain route: it never passes its destination.
    final minX = path.map((o) => o.dx).reduce((a, b) => a < b ? a : b);
    expect(minX, greaterThanOrEqualTo(end.center.dx - 0.5));
    // Neither does the size.
    expect(sizes.every((z) => z.width <= end.width + 0.5), isTrue);
    expect(sizes.every((z) => z.height <= end.height + 0.5), isTrue);
  });

  testWidgets('the motion is smooth: no abrupt change of speed', (
    tester,
  ) async {
    await _pump(tester);
    final trigger = tester.getRect(find.byKey(_trigger));
    await tester.tap(find.byKey(_trigger));
    await tester.pump();

    final ys = <double>[];
    final widths = <double>[];
    for (var i = 0; i < 60; i++) {
      await _frames(tester, 1);
      ys.add(_rect(tester).center.dy);
      widths.add(_rect(tester).width);
    }
    final end = _rect(tester);
    final travelY = end.center.dy - trigger.center.dy;

    double worst(List<double> v, double scale) {
      var max = 0.0;
      for (var i = 2; i < v.length; i++) {
        final d2 = (v[i] - 2 * v[i - 1] + v[i - 2]).abs() / scale;
        if (d2 > max) max = d2;
      }
      return max;
    }

    // Change of speed per frame, as a fraction of the travel.
    expect(worst(ys, travelY), lessThan(0.04));
    expect(worst(widths, end.width - 44), lessThan(0.04));
  });

  testWidgets('closing retraces the same curve, with no jump', (tester) async {
    await _pump(tester);
    final trigger = tester.getRect(find.byKey(_trigger));
    await tester.tap(find.byKey(_trigger));
    await tester.pumpAndSettle();
    final end = _rect(tester);
    final travelY = end.center.dy - trigger.center.dy;

    await tester.binding.handlePopRoute();
    final ys = <double>[end.center.dy];
    for (var i = 0; i < 90; i++) {
      await _frames(tester, 1);
      if (find.byType(ContainerTransformDestination).evaluate().isEmpty) break;
      ys.add(_rect(tester).center.dy);
    }
    expect(ys.length, greaterThan(8));

    // The same gentle excursion as opening, in reverse, never more.
    final excursion =
        (ys.reduce((a, b) => a > b ? a : b) - end.center.dy) / travelY;
    expect(excursion, lessThan(0.06));
    // And it is smooth.
    var worst = 0.0;
    for (var i = 2; i < ys.length; i++) {
      final d2 = (ys[i] - 2 * ys[i - 1] + ys[i - 2]).abs() / travelY;
      if (d2 > worst) worst = d2;
    }
    expect(worst, lessThan(0.05));
    // It ends back over the trigger.
    expect(ys.last, lessThan(end.center.dy));
  });

  testWidgets('reversing mid-way keeps the vertical position continuous', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();

    final ys = <double>[];
    for (var i = 0; i < 120; i++) {
      await _frames(tester, 1);
      ys.add(_rect(tester).center.dy);
      if (_rect(tester).width > 220) break;
    }
    final openStep = _maxStep(ys);

    await tester.binding.handlePopRoute();
    final out = <double>[ys.last];
    for (var i = 0; i < 120; i++) {
      await _frames(tester, 1);
      if (find.byType(ContainerTransformDestination).evaluate().isEmpty) break;
      out.add(_rect(tester).center.dy);
    }
    expect(out.length, greaterThan(4));
    expect(_maxStep(out), lessThan(openStep * 1.5));
  });

  testWidgets('closing and reopening quickly does not stack windows', (
    tester,
  ) async {
    await _pump(tester);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();
    await _frames(tester, 5);
    await tester.binding.handlePopRoute();
    await _frames(tester, 3);

    // The trigger is hidden while the window is still on screen, so a second
    // tap cannot open another one.
    await tester.tap(find.byKey(_trigger), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.byType(ContainerTransformDestination), findsNothing);
  });

  group('reduced motion', () {
    testWidgets('the system setting turns the growth into a fade', (
      tester,
    ) async {
      await _pump(tester, disableAnimations: true);
      await tester.tap(find.byKey(_trigger));
      await tester.pump();

      final rects = <Rect>[];
      for (var i = 0; i < 12; i++) {
        await _frames(tester, 1);
        rects.add(_rect(tester));
        expect(_triggerHidden(tester), isFalse);
      }
      // The surface is already where it will end: no travel, no scale.
      expect(rects.every((r) => r == rects.first), isTrue);
      expect(rects.first.size, const Size(300, 200));

      await tester.pumpAndSettle();
      expect(find.byKey(_item), findsOneWidget);
    });

    testWidgets('the global switch does the same', (tester) async {
      OurnegoMotion.containerTransformEnabled.value = false;
      await _pump(tester);
      await tester.tap(find.byKey(_trigger));
      await tester.pump();
      await _frames(tester, 2);

      expect(_rect(tester).size, const Size(300, 200));
      expect(_triggerHidden(tester), isFalse);
    });
  });

  testWidgets('a window without a destination still fades in and out', (
    tester,
  ) async {
    await _pump(tester, withDestination: false);
    await tester.tap(find.byKey(_trigger));
    await tester.pump();
    await _frames(tester, 1);

    final fade = find.ancestor(
      of: find.byKey(_surface),
      matching: find.byType(Opacity),
    );
    expect(tester.widget<Opacity>(fade.first).opacity, lessThan(1));

    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(fade.first).opacity, 1);
    expect(find.byKey(_surface), findsOneWidget);
  });
}

double _maxStep(List<double> values) {
  var max = 0.0;
  for (var i = 1; i < values.length; i++) {
    final step = (values[i] - values[i - 1]).abs();
    if (step > max) max = step;
  }
  return max;
}
