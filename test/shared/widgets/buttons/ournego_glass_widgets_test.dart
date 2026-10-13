import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

import 'button_test_helpers.dart';

Border _borderOf(WidgetTester tester, Finder of) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(of: of, matching: find.byType(AnimatedContainer)).first,
  );
  return (container.decoration! as BoxDecoration).border! as Border;
}

void main() {
  final scheme = OurnegoTheme.light.colorScheme;

  testWidgets('active glass icon uses accent ink and the active icon', (
    tester,
  ) async {
    const key = ValueKey('mic');
    await pumpButton(
      tester,
      OurnegoGlassIconButton(
        key: key,
        icon: Icons.mic_none_rounded,
        activeIcon: Icons.mic_rounded,
        active: true,
        showHalo: true,
        semanticLabel: 'Detener búsqueda por voz',
        onPressed: () {},
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);
    expect(
      _borderOf(tester, find.byKey(key)).top.color,
      OurnegoButtonPalette.accentInk(scheme),
    );
    final iconTheme = IconTheme.of(
      tester.element(find.byIcon(Icons.mic_rounded)),
    );
    expect(iconTheme.color, OurnegoButtonPalette.accentInk(scheme));
    // No lip.
    expect(tester.getSize(find.byKey(key)), const Size(52, 52));
  });

  testWidgets('glass surface contour turns active when its field has focus', (
    tester,
  ) async {
    const key = ValueKey('surface');
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await pumpButton(
      tester,
      OurnegoGlassSurface(
        key: key,
        child: TextField(focusNode: focusNode),
      ),
    );

    expect(
      _borderOf(tester, find.byKey(key)).top.color,
      OurnegoGlassPalette.border(scheme),
    );

    focusNode.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      _borderOf(tester, find.byKey(key)).top.color,
      OurnegoGlassPalette.active(scheme),
    );
    // No lip: the surface keeps its 52 px height.
    expect(tester.getSize(find.byKey(key)).height, 52);
  });

  testWidgets('glass chip shows label and action and calls onPressed', (
    tester,
  ) async {
    const key = ValueKey('zone');
    var taps = 0;
    await pumpButton(
      tester,
      OurnegoGlassChip(
        key: key,
        label: 'Zona: Centro',
        actionLabel: 'Cambiar',
        semanticLabel: 'Zona: Centro. Cambiar',
        onPressed: () => taps++,
      ),
    );

    expect(find.text('Zona: Centro'), findsOneWidget);
    expect(find.text('Cambiar'), findsOneWidget);
    // No lip.
    expect(tester.getSize(find.byKey(key)).height, 40);

    await tester.tap(find.byKey(key));
    await tester.pump(kGlassReleaseDuration);
    expect(taps, 1);
  });
}
