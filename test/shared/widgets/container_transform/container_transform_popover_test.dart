import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_anchored_position.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_popover_surface.dart';

const _trigger = Key('trigger');
const _other = Key('other');
const _surface = Key('surface');

Future<void> _frames(WidgetTester tester, int count) async {
  for (var i = 0; i < count; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

Rect _painted(WidgetTester tester) => tester
    .renderObject<RenderContainerTransformDestination>(
      find.byType(ContainerTransformDestination),
    )
    .lastPaintedRect!;

bool _hidden(WidgetTester tester, Key trigger) {
  final opacity = tester.widget<Opacity>(
    find
        .descendant(
          of: find.ancestor(
            of: find.byKey(trigger),
            matching: find.byType(ContainerTransformTrigger),
          ),
          matching: find.byType(Opacity),
        )
        .first,
  );
  return opacity.opacity == 0;
}

Widget _popover() => ContainerTransformAnchoredPosition(
  child: Material(
    type: MaterialType.transparency,
    child: OurnegoPopoverSurface(
      child: const SizedBox(key: _surface, width: 150, height: 100),
    ),
  ),
);

/// A 44x44 trigger placed at [alignment] that opens the popover.
Future<void> _pump(
  WidgetTester tester, {
  Alignment alignment = Alignment.topLeft,
  TextDirection direction = TextDirection.ltr,
  Size screen = const Size(400, 800),
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) =>
          Directionality(textDirection: direction, child: child!),
      home: Scaffold(
        body: Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ContainerTransformTrigger(
              radius: 14,
              color: Colors.teal,
              builder: (context, origin) => GestureDetector(
                key: _trigger,
                behavior: HitTestBehavior.opaque,
                onTap: () => showOurnegoPopover<void>(
                  context: context,
                  anchor: origin,
                  builder: (_) => _popover(),
                ),
                child: const SizedBox(width: 44, height: 44),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('anchored position', () {
    testWidgets('sits right below the anchor, aligned with its start', (
      tester,
    ) async {
      await _pump(tester);
      final anchor = tester.getRect(find.byKey(_trigger));
      await tester.tap(find.byKey(_trigger));
      await tester.pumpAndSettle();

      final surface = tester.getRect(find.byKey(_surface));
      expect(surface.left, closeTo(anchor.left, 7)); // the popover's padding
      expect(surface.top, greaterThan(anchor.bottom));
      expect(surface.top - anchor.bottom, lessThan(20));
    });

    testWidgets('flips above the anchor when it does not fit below', (
      tester,
    ) async {
      await _pump(tester, alignment: Alignment.bottomLeft);
      final anchor = tester.getRect(find.byKey(_trigger));
      await tester.tap(find.byKey(_trigger));
      await tester.pumpAndSettle();

      final surface = tester.getRect(find.byKey(_surface));
      expect(surface.bottom, lessThan(anchor.top));
      expect(anchor.top - surface.bottom, lessThan(20));
    });

    testWidgets('aligns with the right edge in right-to-left', (tester) async {
      await _pump(
        tester,
        alignment: Alignment.topRight,
        direction: TextDirection.rtl,
      );
      final anchor = tester.getRect(find.byKey(_trigger));
      await tester.tap(find.byKey(_trigger));
      await tester.pumpAndSettle();

      final surface = tester.getRect(find.byKey(_surface));
      expect(surface.right, closeTo(anchor.right, 7));
    });

    testWidgets('never leaves the screen', (tester) async {
      await _pump(tester, alignment: Alignment.topRight);
      await tester.tap(find.byKey(_trigger));
      await tester.pumpAndSettle();

      final popover = tester.getRect(find.byType(OurnegoPopoverSurface));
      expect(popover.right, lessThanOrEqualTo(400 - 8));
      expect(popover.left, greaterThanOrEqualTo(8));
    });
  });

  group('popover', () {
    testWidgets('grows out of the anchor and settles next to it', (
      tester,
    ) async {
      await _pump(tester);
      final anchor = tester.getRect(find.byKey(_trigger));
      await tester.tap(find.byKey(_trigger));
      await tester.pump();
      await _frames(tester, 2);

      final early = _painted(tester);
      expect((early.center - anchor.center).distance, lessThan(80));

      await tester.pumpAndSettle();
      final end = _painted(tester);
      expect(early.width, lessThan(end.width));
      expect(end, tester.getRect(find.byType(OurnegoPopoverSurface)));
    });

    testWidgets('has the small radius, flat glass, no blur', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(_trigger));
      await tester.pumpAndSettle();

      final container = tester.widget<OurnegoContentContainer>(
        find.byType(OurnegoContentContainer),
      );
      expect(container.borderRadius, OurnegoRadiusTokens.lg);
      expect(container.hasBlur, isFalse);
      expect(find.byType(BackdropFilter), findsNothing);
      expect(find.byType(ImageFiltered), findsNothing);
    });

    testWidgets('has no scrim and a tap outside closes it', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(_trigger));
      await tester.pumpAndSettle();

      // The route's barrier is the topmost one.
      final barrier = tester
          .widgetList<ModalBarrier>(find.byType(ModalBarrier))
          .last;
      expect(barrier.color?.a ?? 0, 0);

      await tester.tapAt(const Offset(380, 700));
      await tester.pumpAndSettle();
      expect(find.byKey(_surface), findsNothing);
    });

    testWidgets('the anchor steps aside and comes back', (tester) async {
      await _pump(tester);
      await tester.tap(find.byKey(_trigger));
      await tester.pumpAndSettle();
      expect(_hidden(tester, _trigger), isTrue);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(_hidden(tester, _trigger), isFalse);
    });

    testWidgets('the content stays put while it closes into a moved anchor', (
      tester,
    ) async {
      await _pump(tester);
      await tester.tap(find.byKey(_trigger));
      await tester.pumpAndSettle();
      final open = tester.getRect(find.byKey(_surface));

      await tester.binding.handlePopRoute();
      await _frames(tester, 2);
      // The anchor is read once, so the popover does not jump on closing.
      expect(tester.getRect(find.byKey(_surface)).top, closeTo(open.top, 25));
    });
  });

  group('static origin and return', () {
    testWidgets('a window with a static origin grows out of that rect', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      late BuildContext host;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              host = context;
              return const Scaffold(body: SizedBox.expand());
            },
          ),
        ),
      );

      const item = Rect.fromLTWH(20, 600, 340, 52);
      showOurnegoDialog<void>(
        context: host,
        staticOrigin: const ContainerTransformOriginData(
          rect: item,
          radius: 18,
          color: Colors.grey,
        ),
        builder: (_) => Center(
          child: OurnegoPopoverSurface(
            child: const SizedBox(key: _surface, width: 200, height: 120),
          ),
        ),
      );
      await tester.pump();
      await _frames(tester, 1);

      final early = _painted(tester);
      expect((early.center - item.center).distance, lessThan(60));
      expect(
        early.width,
        greaterThan(150),
        reason: 'starts as wide as the item',
      );

      await tester.pumpAndSettle();
      expect(
        _painted(tester),
        tester.getRect(find.byType(OurnegoPopoverSurface)),
      );
    });

    testWidgets('it goes back to the return trigger, which steps aside', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: ContainerTransformTrigger(
                radius: 22,
                builder: (context, origin) => GestureDetector(
                  key: _other,
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showOurnegoDialog<void>(
                    context: context,
                    staticOrigin: const ContainerTransformOriginData(
                      rect: Rect.fromLTWH(20, 600, 340, 52),
                      radius: 18,
                      color: Colors.grey,
                    ),
                    returnOrigin: origin,
                    builder: (_) => Center(
                      child: OurnegoPopoverSurface(
                        child: const SizedBox(
                          key: _surface,
                          width: 200,
                          height: 120,
                        ),
                      ),
                    ),
                  ),
                  child: const SizedBox(width: 44, height: 44),
                ),
              ),
            ),
          ),
        ),
      );
      final button = tester.getRect(find.byKey(_other));

      await tester.tap(find.byKey(_other));
      await tester.pumpAndSettle();
      // It opened from the static rect, not from the button: the button was
      // never covered on the way out.
      expect(_hidden(tester, _other), isFalse);

      await tester.binding.handlePopRoute();
      await _frames(tester, 4);
      // Going back, the button is the target: it steps aside while the window
      // is on top of it and the window ends up over the button.
      expect(_hidden(tester, _other), isTrue);
      // Follow it until it is gone: the last thing it paints is on the button.
      var last = _painted(tester);
      for (var i = 0; i < 120; i++) {
        await _frames(tester, 1);
        if (find.byType(ContainerTransformDestination).evaluate().isEmpty) {
          break;
        }
        last = _painted(tester);
      }
      expect(
        (last.center - button.center).distance,
        lessThan(40),
        reason: 'the window shrinks into the button, not into the static rect',
      );

      await tester.pumpAndSettle();
      expect(_hidden(tester, _other), isFalse);
      expect(find.byKey(_surface), findsNothing);
    });
  });

  testWidgets('a handoff captures the rect of the element that was tapped', (
    tester,
  ) async {
    final handoff = ContainerTransformHandoff();
    expect(handoff.data, isNull);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 30, top: 70),
              child: Builder(
                builder: (context) => GestureDetector(
                  key: _trigger,
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      handoff.capture(context, radius: 12, color: Colors.amber),
                  child: const SizedBox(width: 120, height: 40),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(_trigger));

    expect(handoff.data!.rect, tester.getRect(find.byKey(_trigger)));
    expect(handoff.data!.radius, 12);
    expect(handoff.data!.color, Colors.amber);
  });
}
