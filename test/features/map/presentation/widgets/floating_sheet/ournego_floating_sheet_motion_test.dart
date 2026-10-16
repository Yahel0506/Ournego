import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/minimized_stack_icon.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_controller.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_state.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/ournego_floating_sheet.dart';

SheetBusinessData _biz(String id) => SheetBusinessData(
  id: id,
  name: 'Negocio $id',
  description: '',
  ownerId: 'owner',
  address: 'Calle $id',
  phoneNumber: null,
  type: BusinessType.drinkAndEat,
  images: const [],
  hours: const [],
);

const _size = Size(600, 800);
const _collapsed = 200.0;
const _expanded = 600.0;
const _bottomOffset = 96.0;

Finder get _frame => find.byKey(frameKey);

Future<FloatingSheetController> _pumpSheet(WidgetTester tester) async {
  tester.view.physicalSize = _size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final controller = FloatingSheetController();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        // The expanded content reads the owner's profile; no network here.
        ownerProfileStreamProvider.overrideWith(
          (ref, ownerId) => const Stream.empty(),
        ),
      ],
      child: MaterialApp(
        theme: OurnegoTheme.light,
        home: Scaffold(
          body: OurnegoFloatingSheet(
            controller: controller,
            collapsedHeight: _collapsed,
            expandedHeight: _expanded,
            bottomOffset: _bottomOffset,
            sideStackTop: 100,
            maxWidth: double.infinity,
            onFavorite: (_) async => true,
            onContact: (_, _) async {},
            onCatalog: (_) {},
            onReviews: (_) {},
            onShare: (_) async {},
          ),
        ),
      ),
    ),
  );
  return controller;
}

/// Copies of the icon of [id] that can be seen: the stack holds its slot with
/// an invisible copy while the sheet is still on its way.
int _iconsOf(String id) {
  var visible = 0;
  final icons = find.byWidgetPredicate(
    (widget) => widget is MinimizedStackIcon && widget.business.id == id,
  );
  for (final element in icons.evaluate()) {
    var seen = true;
    element.visitAncestorElements((ancestor) {
      final widget = ancestor.widget;
      if (widget is Opacity && widget.opacity == 0) {
        seen = false;
        return false;
      }
      return true;
    });
    if (seen) visible++;
  }
  return visible;
}

void main() {
  group('entry', () {
    testWidgets('opens from its origin and settles at rest', (tester) async {
      final controller = await _pumpSheet(tester);
      const origin = Rect.fromLTWH(180, 500, 40, 40);

      controller.openBusiness(_biz('a'), origin: SheetOrigin(rect: origin));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final early = tester.getRect(_frame);
      expect((early.center - origin.center).distance, lessThan(100));
      expect(early.width, lessThan(200));

      await tester.pumpAndSettle();
      final rest = tester.getRect(_frame);
      expect(rest.left, closeTo(12, 1));
      expect(rest.width, closeTo(576, 1));
      expect(rest.height, closeTo(_collapsed, 1));
      expect(rest.bottom, closeTo(_size.height - _bottomOffset, 1));
      expect(controller.entryProgress.value, closeTo(1, 0.01));
    });

    testWidgets('without an origin it rises from below the bottom edge', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);

      controller.openBusiness(_biz('a'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(tester.getRect(_frame).top, greaterThan(_size.height - 120));
      await tester.pumpAndSettle();
      expect(tester.getRect(_frame).bottom, closeTo(_size.height - 96, 1));
    });

    testWidgets('replacing the business keeps the same frame', (tester) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();
      final frame = tester.element(_frame);

      controller.openBusiness(_biz('b'));
      await tester.pump();

      expect(tester.element(_frame), frame);
      expect(find.text('Negocio b'), findsWidgets);
    });
  });

  group('transit blur', () {
    bool blurred(WidgetTester tester) => tester
        .widgetList<ImageFiltered>(
          find.descendant(of: _frame, matching: find.byType(ImageFiltered)),
        )
        .any((w) => w.enabled);

    testWidgets('the content opens blurred and is sharp at rest', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(
        _biz('a'),
        origin: const SheetOrigin(rect: Rect.fromLTWH(280, 500, 40, 40)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 48));
      expect(blurred(tester), isTrue);

      await tester.pumpAndSettle();
      expect(blurred(tester), isFalse);
    });

    testWidgets('the vertical position leads the horizontal one', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      const origin = Rect.fromLTWH(60, 500, 40, 40);
      controller.openBusiness(_biz('a'), origin: SheetOrigin(rect: origin));
      await tester.pump();
      for (var i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final rest = Rect.fromLTWH(12, 800 - 96 - 200, 576, 200);
      final frame = tester.getRect(_frame);
      final x =
          (frame.center.dx - origin.center.dx) /
          (rest.center.dx - origin.center.dx);
      final y =
          (frame.center.dy - origin.center.dy) /
          (rest.center.dy - origin.center.dy);
      expect(y, greaterThan(x));
      await tester.pumpAndSettle();
    });
  });

  group('origin', () {
    const marker = Rect.fromLTWH(100, 500, 24, 24);

    SheetOrigin markerOrigin({Rect? Function()? resolve}) => SheetOrigin(
      rect: marker,
      radius: 12,
      color: const Color(0xFFD32F2F),
      foregroundColor: const Color(0xFFFFFFFF),
      icon: Icons.restaurant,
      resolve: resolve,
    );

    testWidgets('it starts as the marker: round, its color and its icon', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'), origin: markerOrigin());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(find.byIcon(Icons.restaurant), findsOneWidget);
      final decorated = tester.widget<DecoratedBox>(
        find.ancestor(of: _frame, matching: find.byType(DecoratedBox)).first,
      );
      final color = (decorated.decoration as BoxDecoration).color!;
      expect(color.r, greaterThan(0.6), reason: 'close to the marker red');
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.restaurant), findsNothing);
    });

    testWidgets('it goes back to the marker where it is now', (tester) async {
      final controller = await _pumpSheet(tester);
      const moved = Rect.fromLTWH(300, 300, 24, 24);
      controller.openBusiness(
        _biz('a'),
        origin: markerOrigin(resolve: () => moved),
      );
      await tester.pumpAndSettle();

      controller.closeActiveBusiness();
      Rect? last;
      for (var i = 0; i < 120 && controller.activeBusiness != null; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (_frame.evaluate().isNotEmpty) last = tester.getRect(_frame);
      }
      expect(last, isNotNull);
      expect((last!.center - moved.center).distance, lessThan(80));
    });

    testWidgets('with no origin left it leaves downwards, never upwards', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(
        _biz('a'),
        origin: markerOrigin(resolve: () => null),
      );
      await tester.pumpAndSettle();
      final rest = tester.getRect(_frame);

      controller.closeActiveBusiness();
      var highest = rest.top;
      for (var i = 0; i < 120 && controller.activeBusiness != null; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (_frame.evaluate().isNotEmpty) {
          highest = highest < tester.getRect(_frame).top
              ? highest
              : tester.getRect(_frame).top;
        }
      }
      expect(highest, closeTo(rest.top, 1));
    });
  });

  group('minimize', () {
    testWidgets(
      'the sheet becomes its stacked icon, never two copies at once',
      (tester) async {
        final controller = await _pumpSheet(tester);
        controller.openBusiness(_biz('a'));
        controller.openBusiness(_biz('b'));
        await tester.pumpAndSettle();
        expect(_iconsOf('b'), 0);

        controller.minimizeActiveBusiness();
        var sawFrame = false;
        for (var i = 0; i < 60; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          sawFrame = sawFrame || _frame.evaluate().isNotEmpty;
          expect(_iconsOf('b'), lessThanOrEqualTo(1));
        }

        expect(sawFrame, isTrue);
        expect(_frame, findsNothing);
        expect(_iconsOf('b'), 1);
        expect(controller.activeBusiness, isNull);
      },
    );
  });

  group('stack', () {
    double iconTop(WidgetTester tester, String id) => tester
        .getTopLeft(
          find.byWidgetPredicate(
            (w) => w is MinimizedStackIcon && w.business.id == id,
          ),
        )
        .dy;

    testWidgets('a new icon takes the slot under the stack, no one moves', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      for (final id in ['a', 'b', 'c']) {
        controller.openBusiness(_biz(id));
      }
      await tester.pumpAndSettle();
      final aTop = iconTop(tester, 'a');
      final bTop = iconTop(tester, 'b');
      expect(bTop - aTop, 56);

      controller.minimizeActiveBusiness();
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(iconTop(tester, 'a'), aTop);
        expect(iconTop(tester, 'b'), bTop);
      }
      await tester.pumpAndSettle();
      expect(iconTop(tester, 'c'), aTop + 112);
    });

    testWidgets('a fifth icon pushes the oldest out and the rest move up', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      for (final id in ['a', 'b', 'c', 'd', 'e']) {
        controller.openBusiness(_biz(id));
      }
      await tester.pumpAndSettle();
      final top = iconTop(tester, 'a');

      controller.minimizeActiveBusiness();
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is MinimizedStackIcon && w.business.id == 'a',
        ),
        findsNothing,
      );
      expect(iconTop(tester, 'b'), top);
      expect(iconTop(tester, 'c'), top + 56);
      expect(iconTop(tester, 'd'), top + 112);
      expect(iconTop(tester, 'e'), top + 168);
    });
  });

  group('scrim', () {
    double scrimAlpha(WidgetTester tester) {
      final box = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byKey(const ValueKey('floatingSheetScrim')),
          matching: find.byType(ColoredBox),
        ),
      );
      return box.color.a;
    }

    testWidgets('minimizing from expanded clears it', (tester) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();
      controller.toggleExpandedCollapsed();
      await tester.pumpAndSettle();
      expect(scrimAlpha(tester), closeTo(0.4, 0.01));

      controller.minimizeActiveBusiness();
      await tester.pumpAndSettle();
      expect(controller.activeBusiness, isNull);
      expect(scrimAlpha(tester), 0);
    });

    testWidgets('closing from expanded clears it', (tester) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();
      controller.toggleExpandedCollapsed();
      await tester.pumpAndSettle();

      controller.closeActiveBusiness();
      await tester.pumpAndSettle();
      expect(controller.activeBusiness, isNull);
      expect(scrimAlpha(tester), 0);
    });
  });

  group('dismissal', () {
    testWidgets('mid-drag the sheet is lower and smaller than at rest', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();
      final rest = tester.getRect(_frame);

      final gesture = await tester.startGesture(rest.center);
      await gesture.moveBy(const Offset(0, 40));
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      final dragged = tester.getRect(_frame);
      expect(dragged.top, greaterThan(rest.top + 40));
      expect(dragged.width, lessThan(rest.width));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a short push springs back', (tester) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();
      final rest = tester.getRect(_frame);

      final gesture = await tester.startGesture(rest.center);
      await gesture.moveBy(const Offset(0, 40));
      await gesture.moveBy(const Offset(0, 20));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.activeBusiness, isNotNull);
      expect(tester.getRect(_frame).top, closeTo(rest.top, 1));
      expect(tester.getRect(_frame).width, closeTo(rest.width, 1));
    });

    testWidgets('a long push dismisses: first down, then it goes away', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();
      final rest = tester.getRect(_frame);

      final gesture = await tester.startGesture(rest.center);
      await gesture.moveBy(const Offset(0, 60));
      await gesture.moveBy(const Offset(0, 60));
      await gesture.up();
      var lowest = rest.top;
      for (var i = 0; i < 120 && controller.activeBusiness != null; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (_frame.evaluate().isNotEmpty) {
          final top = tester.getRect(_frame).top;
          if (top > lowest) lowest = top;
        }
      }
      expect(lowest, greaterThan(rest.top + 100));
      expect(controller.activeBusiness, isNull);
    });

    testWidgets('a fast downward fling dismisses', (tester) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();

      await tester.fling(_frame, const Offset(0, 120), 1500);
      await tester.pumpAndSettle();

      expect(controller.activeBusiness, isNull);
    });

    testWidgets('from expanded one long drag collapses and then dismisses', (
      tester,
    ) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();
      controller.toggleExpandedCollapsed();
      await tester.pumpAndSettle();

      final gesture = await tester.startGesture(
        tester.getRect(_frame).topCenter + const Offset(0, 30),
      );
      for (var i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(0, 50));
      }
      await gesture.up();
      await tester.pumpAndSettle();

      expect(controller.activeBusiness, isNull);
    });
  });

  group('expansion', () {
    testWidgets('a fast upward fling expands and dims the map', (tester) async {
      final controller = await _pumpSheet(tester);
      controller.openBusiness(_biz('a'));
      await tester.pumpAndSettle();
      expect(tester.getRect(_frame).height, closeTo(_collapsed, 1));

      await tester.fling(_frame, const Offset(0, -300), 1200);
      await tester.pumpAndSettle();

      expect(controller.state, FloatingSheetState.expanded);
      expect(tester.getRect(_frame).height, closeTo(_expanded, 2));
    });

    testWidgets(
      'a slow drag that stays short of halfway returns to collapsed',
      (tester) async {
        final controller = await _pumpSheet(tester);
        controller.openBusiness(_biz('a'));
        await tester.pumpAndSettle();

        await tester.drag(_frame, const Offset(0, -60));
        await tester.pumpAndSettle();

        expect(controller.state, FloatingSheetState.collapsed);
        expect(tester.getRect(_frame).height, closeTo(_collapsed, 1));
      },
    );
  });
}
