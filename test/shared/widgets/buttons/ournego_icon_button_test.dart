import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

import 'button_test_helpers.dart';

const _key = ValueKey('icon');

void main() {
  testWidgets('semanticLabel reaches Semantics', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpButton(
      tester,
      OurnegoIconButton(
        key: _key,
        icon: Icons.add_rounded,
        semanticLabel: 'Acercar',
        onPressed: () {},
      ),
    );
    expect(find.bySemanticsLabel('Acercar'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('toggle flips selected through onChanged and exposes toggled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var selected = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: OurnegoTheme.light,
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (context, setState) => OurnegoIconButton.toggle(
                key: _key,
                selected: selected,
                icon: Icons.favorite_border_rounded,
                selectedIcon: Icons.favorite_rounded,
                semanticLabel: 'Favorito',
                celebrate: true,
                onChanged: (value) => setState(() => selected = value),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Favorito')),
      matchesSemantics(
        label: 'Favorito',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasToggledState: true,
        isToggled: false,
        hasTapAction: true,
        isFocusable: true,
      ),
    );

    await tester.tap(find.byKey(_key));
    await tester.pump();
    await tester.pump(kBurstDuration);

    expect(selected, isTrue);
    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Favorito')),
      isSemantics(isToggled: true),
    );
    handle.dispose();
  });

  testWidgets('radius 16 is applied', (tester) async {
    await pumpButton(
      tester,
      OurnegoIconButton(
        key: _key,
        icon: Icons.add_rounded,
        semanticLabel: 'Acercar',
        radius: 16,
        onPressed: () {},
      ),
    );
    expect(faceDecoration(tester).borderRadius, BorderRadius.circular(16));
  });

  testWidgets('outlined tonal draws a 1 px contour and the contour lip', (
    tester,
  ) async {
    for (final theme in [OurnegoTheme.light, OurnegoTheme.dark]) {
      await pumpButton(
        tester,
        OurnegoIconButton(
          key: _key,
          tone: OurnegoButtonTone.tonal,
          outlined: true,
          size: OurnegoIconButtonSize.s32,
          radius: 14,
          icon: Icons.share_rounded,
          semanticLabel: 'Compartir',
          onPressed: () {},
        ),
        theme: theme,
      );
      // Theme and tone colors both animate; nothing loops here.
      await tester.pumpAndSettle();

      final scheme = theme.colorScheme;
      final border = faceDecoration(tester).border! as Border;
      expect(border.top.width, 1);
      expect(border.top.color, OurnegoSemanticTokens.borderSubtle(scheme));

      final lipColors = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byKey(_key),
              matching: find.byType(DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as BoxDecoration).color)
          .toList();
      expect(lipColors, contains(OurnegoButtonPalette.outlineLip(scheme)));
    }
  });

  testWidgets('ghost has no lip', (tester) async {
    await pumpButton(
      tester,
      OurnegoIconButton.ghost(
        key: _key,
        icon: Icons.arrow_back_rounded,
        semanticLabel: 'Regresar',
        onPressed: () {},
      ),
    );
    expect(tester.getSize(find.byKey(_key)), const Size(48, 48));
  });
}
