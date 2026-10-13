import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';

import 'button_test_helpers.dart';

const _key = ValueKey('button');

void main() {
  testWidgets('shows the label and keeps the key findable', (tester) async {
    var taps = 0;
    await pumpButton(
      tester,
      OurnegoButton.primary(
        key: _key,
        label: 'Guardar',
        onPressed: () => taps++,
      ),
    );

    expect(find.text('Guardar'), findsOneWidget);
    expect(find.byKey(_key), findsOneWidget);

    await tester.tap(find.byKey(_key));
    await tester.pump(kBoingDuration);
    expect(taps, 1);
  });

  testWidgets('total height is face plus lip; ghost has no lip', (
    tester,
  ) async {
    await pumpButton(
      tester,
      OurnegoButton.primary(key: _key, label: 'Guardar', onPressed: () {}),
    );
    expect(tester.getSize(find.byKey(_key)).height, 54);

    await pumpButton(
      tester,
      OurnegoButton.text(key: _key, label: 'Cancelar', onPressed: () {}),
    );
    expect(tester.getSize(find.byKey(_key)).height, 50);
  });

  testWidgets('loading shows Nego eyes, keeps the width and ignores taps', (
    tester,
  ) async {
    var taps = 0;
    Widget button(OurnegoButtonStatus status) => OurnegoButton.primary(
      key: _key,
      label: 'Enviar correo',
      status: status,
      onPressed: () => taps++,
    );

    await pumpButton(tester, button(OurnegoButtonStatus.idle));
    final idleSize = tester.getSize(find.byKey(_key));

    await pumpButton(tester, button(OurnegoButtonStatus.loading));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(NegoEyesLoader), findsOneWidget);
    expect(tester.getSize(find.byKey(_key)), idleSize);

    await tester.tap(find.byKey(_key), warnIfMissed: false);
    await tester.pump(kBoingDuration);
    expect(taps, 0);
  });

  testWidgets('success shows the success label', (tester) async {
    await pumpButton(
      tester,
      OurnegoButton.primary(
        key: _key,
        label: 'Guardar',
        status: OurnegoButtonStatus.success,
        onPressed: () {},
      ),
    );
    await tester.pump(kColorChangeDuration);

    expect(find.text('¡Listo!'), findsOneWidget);
    expect(find.text('Guardar'), findsNothing);
  });

  testWidgets('showNego renders a still Nego mini', (tester) async {
    await pumpButton(
      tester,
      OurnegoButton.primary(
        key: _key,
        label: 'Entrar',
        showNego: true,
        onPressed: () {},
      ),
    );

    final nego = tester.widget<NegoAvatar>(find.byType(NegoAvatar));
    expect(nego.floating, isFalse);
    expect(nego.interactive, isFalse);
    expect(nego.size, 30);
    // No infinite animation inside the button.
    await tester.pumpAndSettle();
  });

  testWidgets('disabled closes Nego eyes', (tester) async {
    await pumpButton(
      tester,
      const OurnegoButton.primary(
        label: 'Entrar',
        showNego: true,
        onPressed: null,
      ),
    );
    expect(
      tester.widget<NegoAvatar>(find.byType(NegoAvatar)).eyesClosed,
      isTrue,
    );
  });

  test('showNego asserts with a non-primary tone', () {
    expect(
      () => OurnegoButton(
        label: 'X',
        onPressed: null,
        tone: OurnegoButtonTone.secondary,
        showNego: true,
      ),
      throwsAssertionError,
    );
  });

  testWidgets('expanded fills the parent width', (tester) async {
    await pumpButton(
      tester,
      OurnegoButton.primary(
        key: _key,
        label: 'Guardar',
        expanded: true,
        onPressed: () {},
      ),
      width: 320,
    );
    expect(tester.getSize(find.byKey(_key)).width, 320);
  });

  testWidgets('minWidth keeps a minimum width', (tester) async {
    await pumpButton(
      tester,
      OurnegoButton.neutral(
        key: _key,
        label: 'Ok',
        minWidth: 200,
        onPressed: () {},
      ),
    );
    expect(tester.getSize(find.byKey(_key)).width, 200);
  });

  testWidgets('uses tone colors in both themes', (tester) async {
    for (final theme in [OurnegoTheme.light, OurnegoTheme.dark]) {
      await pumpButton(
        tester,
        OurnegoButton.destructive(key: _key, label: 'Borrar', onPressed: () {}),
        theme: theme,
      );
      // Theme and tone colors both animate; nothing loops here.
      await tester.pumpAndSettle();
      final expected = OurnegoButtonPalette.of(
        OurnegoButtonTone.destructive,
        theme.colorScheme,
      );
      expect(faceDecoration(tester).color, expected.face);
    }
  });
}
