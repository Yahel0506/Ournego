import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/map/presentation/widgets/map_top_strip_widget.dart';

Widget _strip({
  bool register = false,
  bool banner = false,
  bool chip = false,
}) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 300,
        child: MapTopStrip(
          showRegister: register,
          register: const SizedBox(key: Key('register'), height: 60),
          showBanner: banner,
          banner: const SizedBox(key: Key('banner'), height: 70),
          showChip: chip,
          chip: const SizedBox(key: Key('chip'), width: 120, height: 40),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('a piece that comes grows the strip and fades in', (
    tester,
  ) async {
    await tester.pumpWidget(_strip(register: true));
    await tester.pumpAndSettle();
    final before = tester.getSize(find.byType(MapTopStrip)).height;

    await tester.pumpWidget(_strip(register: true, banner: true));
    await tester.pump(const Duration(milliseconds: 50));
    final during = tester.getSize(find.byType(MapTopStrip)).height;
    await tester.pumpAndSettle();
    final after = tester.getSize(find.byType(MapTopStrip)).height;

    expect(before, 60);
    expect(during, greaterThan(before));
    expect(during, lessThan(after));
    expect(after, 130);
  });

  testWidgets('the others do not jump when one leaves', (tester) async {
    await tester.pumpWidget(_strip(banner: true, chip: true));
    await tester.pumpAndSettle();
    final chipBefore = tester.getTopLeft(find.byKey(const Key('chip'))).dy;
    expect(chipBefore, 78); // 70 of banner + 8 of gap

    await tester.pumpWidget(_strip(chip: true));
    await tester.pump(const Duration(milliseconds: 50));
    final mid = tester.getTopLeft(find.byKey(const Key('chip'))).dy;
    expect(mid, lessThan(chipBefore));
    expect(mid, greaterThan(0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.byKey(const Key('chip'))).dy, 0);
  });

  testWidgets('the chip keeps its own width', (tester) async {
    await tester.pumpWidget(_strip(chip: true));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byKey(const Key('chip'))).width, 120);
  });
}
