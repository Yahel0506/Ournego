import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/debugging/presentation/pages/button_gallery_screen.dart';
import 'package:ournego/core/theme/ournego_theme.dart';

void main() {
  // The gallery shows looping loaders and halos: use pump(Duration), never
  // pumpAndSettle.
  testWidgets('gallery builds and switches theme and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(theme: OurnegoTheme.light, home: const ButtonGalleryScreen()),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Acción principal'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Oscuro'));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Simular reduced motion'));
    await tester.pump(const Duration(milliseconds: 500));

    await tester.scrollUntilVisible(
      find.text('Chips'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
  });
}
