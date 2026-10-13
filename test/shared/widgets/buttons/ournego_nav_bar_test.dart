import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_nav_bar.dart';

const _items = [
  OurnegoNavBarItem(icon: Icons.people_rounded, label: 'Inicio'),
  OurnegoNavBarItem(icon: Icons.location_on_rounded, label: 'Mapa'),
  OurnegoNavBarItem(icon: Icons.store_rounded, label: 'Mi Negocio'),
];

const _key = ValueKey('nav');

Widget _host(int index, {bool reduced = false, ValueChanged<int>? onTap}) {
  return MaterialApp(
    theme: OurnegoTheme.light,
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(400, 800),
        disableAnimations: reduced,
      ),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: OurnegoNavBar(
              key: _key,
              items: _items,
              currentIndex: index,
              onTap: onTap ?? (_) {},
            ),
          ),
        ),
      ),
    ),
  );
}

double _indicatorCenterX(WidgetTester tester) =>
    tester.getCenter(find.byKey(ournegoNavIndicatorKey)).dx;

double _itemCenterX(WidgetTester tester, IconData icon) =>
    tester.getCenter(find.byIcon(icon)).dx;

void main() {
  testWidgets('indicator is centered on the active item', (tester) async {
    await tester.pumpWidget(_host(1));
    expect(
      _indicatorCenterX(tester),
      closeTo(_itemCenterX(tester, Icons.location_on_rounded), 1),
    );
  });

  testWidgets('indicator slides monotonically without passing the target', (
    tester,
  ) async {
    await tester.pumpWidget(_host(1));
    final start = _indicatorCenterX(tester);
    final target = _itemCenterX(tester, Icons.store_rounded);

    await tester.pumpWidget(_host(2));
    var previous = start;
    const frame = Duration(milliseconds: 16);
    var moved = false;
    for (
      var elapsed = Duration.zero;
      elapsed <= kNavIndicatorDuration + frame;
      elapsed += frame
    ) {
      await tester.pump(frame);
      final x = _indicatorCenterX(tester);
      expect(x, greaterThanOrEqualTo(previous - 1e-6));
      expect(x, lessThanOrEqualTo(target + 1e-6));
      if (x > start && x < target) moved = true;
      previous = x;
    }
    expect(moved, isTrue);
    expect(_indicatorCenterX(tester), closeTo(target, 1));
  });

  testWidgets('with reduced motion the indicator jumps in one frame', (
    tester,
  ) async {
    await tester.pumpWidget(_host(1, reduced: true));
    await tester.pumpWidget(_host(2, reduced: true));
    await tester.pump();
    expect(
      _indicatorCenterX(tester),
      closeTo(_itemCenterX(tester, Icons.store_rounded), 1),
    );
  });

  testWidgets('active item uses noche ink and exposes selected', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_host(0));
    await tester.pumpAndSettle();

    final icon = tester.widget<Icon>(find.byIcon(Icons.people_rounded));
    expect(icon.color, OurnegoColorTokens.noche);

    expect(
      tester.getSemantics(find.bySemanticsLabel('Inicio')),
      isSemantics(isSelected: true, isButton: true),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Mapa')),
      isSemantics(isSelected: false, isButton: true),
    );
    handle.dispose();
  });

  testWidgets('total height is 72 and taps report the index', (tester) async {
    int? tapped;
    await tester.pumpWidget(_host(0, onTap: (i) => tapped = i));
    expect(tester.getSize(find.byKey(_key)).height, 72);

    await tester.tap(find.byIcon(Icons.store_rounded));
    await tester.pump(kGlassReleaseDuration);
    expect(tapped, 2);
  });
}
