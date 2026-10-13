import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_controller.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_state.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

// Characterization of the current behavior of the controller. The container
// transform work replaces only the visual layer of the sheet and has to keep
// every transition below intact.
SheetBusinessData biz(String id) => SheetBusinessData(
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

/// Opens [business] and lets the controller's own 40 ms delay elapse.
void open(FakeAsync async, FloatingSheetController c, SheetBusinessData b) {
  c.openBusiness(b);
  async.elapse(const Duration(milliseconds: 50));
}

void main() {
  group('openBusiness', () {
    test('starts minimized and settles to collapsed after 40 ms', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        c.openBusiness(biz('a'));

        expect(c.activeBusiness?.id, 'a');
        expect(c.state, FloatingSheetState.minimized);

        async.elapse(const Duration(milliseconds: 39));
        expect(c.state, FloatingSheetState.minimized);
        async.elapse(const Duration(milliseconds: 2));
        expect(c.state, FloatingSheetState.collapsed);
      });
    });

    test('a newer business wins over a pending collapse of the older one', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        c.openBusiness(biz('a'));
        c.openBusiness(biz('b'));
        async.elapse(const Duration(milliseconds: 50));

        expect(c.activeBusiness?.id, 'b');
        expect(c.state, FloatingSheetState.collapsed);
        expect(c.minimizedBusinesses.map((b) => b.id), ['a']);
      });
    });

    test('reopening the same business does not push it to the stack', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        open(async, c, biz('a'));

        expect(c.minimizedBusinesses, isEmpty);
      });
    });

    test('drops comparison mode', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        c.restoreState(
          state: FloatingSheetState.collapsed,
          activeBusiness: biz('a'),
          comparisonBusiness: biz('b'),
          minimizedBusinesses: const [],
        );
        expect(c.isComparisonMode, isTrue);

        open(async, c, biz('c'));
        expect(c.isComparisonMode, isFalse);
      });
    });
  });

  group('close and minimize', () {
    test('closeActiveBusiness is two-step: pending clear, then finalize', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));

        c.closeActiveBusiness();
        expect(c.pendingClearActive, isTrue);
        expect(c.state, FloatingSheetState.minimized);
        expect(c.activeBusiness, isNotNull);

        c.finalizeTransitionOut();
        expect(c.activeBusiness, isNull);
        expect(c.pendingClearActive, isFalse);
      });
    });

    test('finalizeTransitionOut without a pending clear does nothing', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        c.finalizeTransitionOut();
        expect(c.activeBusiness?.id, 'a');
      });
    });

    test('closeIfCollapsed ignores an expanded sheet', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        c.transitionTo(FloatingSheetState.expanded);

        c.closeIfCollapsed();
        expect(c.pendingClearActive, isFalse);

        c.transitionTo(FloatingSheetState.collapsed);
        c.closeIfCollapsed();
        expect(c.pendingClearActive, isTrue);
      });
    });

    test('minimizeActiveBusiness pushes to the stack and flags the move', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));

        c.minimizeActiveBusiness();
        expect(c.minimizedBusinesses.map((b) => b.id), ['a']);
        expect(c.pendingMinimizeToStack, isTrue);
        expect(c.pendingClearActive, isTrue);

        c.finalizeTransitionOut();
        expect(c.activeBusiness, isNull);
        expect(c.pendingMinimizeToStack, isFalse);
      });
    });
  });

  group('minimized stack', () {
    test('keeps the 4 most recent, newest first', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        for (final id in ['a', 'b', 'c', 'd', 'e', 'f']) {
          open(async, c, biz(id));
        }
        expect(c.activeBusiness?.id, 'f');
        expect(c.minimizedBusinesses.map((b) => b.id), ['e', 'd', 'c', 'b']);
      });
    });

    test('restoreFromMinimized swaps the active business with the stacked', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        open(async, c, biz('b'));

        c.restoreFromMinimized('a');
        expect(c.activeBusiness?.id, 'a');
        expect(c.state, FloatingSheetState.collapsed);
        expect(c.minimizedBusinesses.map((b) => b.id), ['b']);
      });
    });

    test('restoreFromMinimized with an unknown id is a no-op', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        c.restoreFromMinimized('zzz');
        expect(c.activeBusiness?.id, 'a');
      });
    });

    test('removeFromMinimized', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        open(async, c, biz('b'));
        c.removeFromMinimized('a');
        expect(c.minimizedBusinesses, isEmpty);
      });
    });
  });

  group('comparison', () {
    test('tapping a stacked icon on a collapsed sheet enters comparison', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        open(async, c, biz('b'));

        c.onMinimizedBusinessTap('a');
        expect(c.isComparisonMode, isTrue);
        expect(c.activeBusiness?.id, 'b');
        expect(c.comparisonBusiness?.id, 'a');
        expect(c.minimizedBusinesses, isEmpty);
      });
    });

    test('tapping a stacked icon on an expanded sheet restores instead', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        open(async, c, biz('b'));
        c.transitionTo(FloatingSheetState.expanded);

        c.onMinimizedBusinessTap('a');
        expect(c.isComparisonMode, isFalse);
        expect(c.activeBusiness?.id, 'a');
      });
    });

    test('taps on the stack are ignored while comparing', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        for (final id in ['a', 'b', 'c']) {
          open(async, c, biz(id));
        }
        c.onMinimizedBusinessTap('b');
        expect(c.isComparisonMode, isTrue);

        c.onMinimizedBusinessTap('a');
        expect(c.comparisonBusiness?.id, 'b');
        expect(c.minimizedBusinesses.map((b) => b.id), ['a']);
      });
    });

    FloatingSheetController comparing(FakeAsync async) {
      final c = FloatingSheetController();
      open(async, c, biz('a'));
      open(async, c, biz('b'));
      c.onMinimizedBusinessTap('a'); // active b, comparison a
      return c;
    }

    test('closePrimaryInComparison promotes the second card', () {
      fakeAsync((async) {
        final c = comparing(async);
        c.closePrimaryInComparison();
        expect(c.activeBusiness?.id, 'a');
        expect(c.isComparisonMode, isFalse);
        expect(c.state, FloatingSheetState.collapsed);
      });
    });

    test('closeSecondaryInComparison keeps the primary', () {
      fakeAsync((async) {
        final c = comparing(async);
        c.closeSecondaryInComparison();
        expect(c.activeBusiness?.id, 'b');
        expect(c.isComparisonMode, isFalse);
      });
    });

    test('minimizePrimaryInComparison stacks the first and promotes', () {
      fakeAsync((async) {
        final c = comparing(async);
        c.minimizePrimaryInComparison();
        expect(c.activeBusiness?.id, 'a');
        expect(c.minimizedBusinesses.map((b) => b.id), ['b']);
      });
    });

    test('minimizeSecondaryInComparison stacks the second', () {
      fakeAsync((async) {
        final c = comparing(async);
        c.minimizeSecondaryInComparison();
        expect(c.activeBusiness?.id, 'b');
        expect(c.minimizedBusinesses.map((b) => b.id), ['a']);
      });
    });

    test('minimizeActiveBusiness is ignored while comparing', () {
      fakeAsync((async) {
        final c = comparing(async);
        c.minimizeActiveBusiness();
        expect(c.pendingMinimizeToStack, isFalse);
        expect(c.isComparisonMode, isTrue);
      });
    });
  });

  group('transitions and drag', () {
    test('transitionTo without a business only allows minimized', () {
      final c = FloatingSheetController();
      c.transitionTo(FloatingSheetState.expanded);
      expect(c.state, FloatingSheetState.collapsed);
    });

    test('toggleExpandedCollapsed', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        c.toggleExpandedCollapsed();
        expect(c.state, FloatingSheetState.expanded);
        c.toggleExpandedCollapsed();
        expect(c.state, FloatingSheetState.collapsed);
      });
    });

    void drag(
      FloatingSheetController c,
      double velocity,
      double currentHeight,
    ) {
      c.handleVerticalDragEnd(
        velocity: velocity,
        currentHeight: currentHeight,
        collapsedHeight: 200,
        expandedHeight: 600,
      );
    }

    test('a fast upward fling expands', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));
        drag(c, -800, 210);
        expect(c.state, FloatingSheetState.expanded);
      });
    });

    test(
      'a fast downward fling collapses when expanded, closes when collapsed',
      () {
        fakeAsync((async) {
          final c = FloatingSheetController();
          open(async, c, biz('a'));
          c.transitionTo(FloatingSheetState.expanded);

          drag(c, 800, 590);
          expect(c.state, FloatingSheetState.collapsed);

          drag(c, 800, 210);
          expect(c.pendingClearActive, isTrue);
        });
      },
    );

    test('a slow drag snaps to the nearest height', () {
      fakeAsync((async) {
        final c = FloatingSheetController();
        open(async, c, biz('a'));

        drag(c, 0, 450);
        expect(c.state, FloatingSheetState.expanded);
        drag(c, 0, 350);
        expect(c.state, FloatingSheetState.collapsed);
      });
    });
  });

  group('restoreState', () {
    test('hydrates the state, keeping only 4 stacked businesses', () {
      final c = FloatingSheetController();
      c.restoreState(
        state: FloatingSheetState.expanded,
        activeBusiness: biz('a'),
        minimizedBusinesses: [for (final i in 'bcdefg'.split('')) biz(i)],
      );

      expect(c.state, FloatingSheetState.expanded);
      expect(c.activeBusiness?.id, 'a');
      expect(c.minimizedBusinesses.map((b) => b.id), ['b', 'c', 'd', 'e']);
      expect(c.pendingClearActive, isFalse);
    });

    test('without an active business the state is minimized', () {
      final c = FloatingSheetController();
      c.restoreState(
        state: FloatingSheetState.expanded,
        minimizedBusinesses: const [],
      );
      expect(c.state, FloatingSheetState.minimized);
    });
  });

  group('favorites', () {
    test('toggles the active and the comparison business', () {
      final c = FloatingSheetController();
      c.restoreState(
        state: FloatingSheetState.collapsed,
        activeBusiness: biz('a'),
        comparisonBusiness: biz('b'),
        minimizedBusinesses: const [],
      );

      expect(c.toggleFavorite(), isTrue);
      expect(c.activeBusiness!.isFavorite, isTrue);
      expect(c.toggleFavoriteForBusiness('b'), isTrue);
      expect(c.comparisonBusiness!.isFavorite, isTrue);
      expect(c.toggleFavoriteForBusiness('zzz'), isFalse);
    });
  });
}
