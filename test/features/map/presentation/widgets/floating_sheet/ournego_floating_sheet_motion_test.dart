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

int _iconsOf(String id) => find
    .byWidgetPredicate(
      (widget) => widget is MinimizedStackIcon && widget.business.id == id,
    )
    .evaluate()
    .length;

void main() {
  group('entry', () {
    testWidgets('opens from its origin and settles at rest', (tester) async {
      final controller = await _pumpSheet(tester);
      const origin = Rect.fromLTWH(180, 500, 40, 40);

      controller.openBusiness(_biz('a'), origin: origin);
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
