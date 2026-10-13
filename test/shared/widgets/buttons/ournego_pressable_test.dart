import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

import 'button_test_helpers.dart';

const _key = ValueKey('pressable');

Widget _pressable({VoidCallback? onPressed, FocusNode? focusNode}) {
  return OurnegoPressable(
    key: _key,
    onPressed: onPressed,
    colors: OurnegoButtonPalette.of(
      OurnegoButtonTone.primary,
      OurnegoTheme.light.colorScheme,
    ),
    faceHeight: 50,
    lipDepth: 4,
    borderRadius: BorderRadius.circular(24),
    width: 160,
    focusNode: focusNode,
    child: const Text('Guardar'),
  );
}

void main() {
  testWidgets('tap calls onPressed once', (tester) async {
    var taps = 0;
    await pumpButton(tester, _pressable(onPressed: () => taps++));

    await tester.tap(find.byKey(_key));
    await tester.pump(kBoingDuration);

    expect(taps, 1);
  });

  testWidgets('null onPressed is inert and semantically disabled', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pumpButton(tester, _pressable());

    await tester.tap(find.byKey(_key), warnIfMissed: false);
    await tester.pump(kBoingDuration);

    expect(
      tester.getSemantics(find.text('Guardar')),
      matchesSemantics(
        isButton: true,
        hasEnabledState: true,
        isEnabled: false,
        label: 'Guardar',
      ),
    );
    handle.dispose();
  });

  testWidgets('total height is face plus lip', (tester) async {
    await pumpButton(tester, _pressable(onPressed: () {}));
    expect(tester.getSize(find.byKey(_key)).height, 54);
  });

  testWidgets('pressing lowers the face by the lip and it returns to 0', (
    tester,
  ) async {
    await pumpButton(tester, _pressable(onPressed: () {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_key)),
    );
    await tester.pump();
    await tester.pump(kPressDownDuration);
    expect(faceDy(tester), closeTo(4, 0.01));

    await gesture.up();
    await tester.pump();
    await tester.pump(kBoingDuration);
    await tester.pump();
    expect(faceDy(tester), closeTo(0, 0.01));
    expect(faceScaleX(tester), closeTo(1, 0.0001));
  });

  testWidgets('releasing plays the boing (squash and stretch)', (tester) async {
    await pumpButton(tester, _pressable(onPressed: () {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_key)),
    );
    await tester.pump();
    await tester.pump(kPressDownDuration);
    await gesture.up();
    await tester.pump();
    await tester.pump(kBoingDuration ~/ 4);

    expect(faceScaleX(tester), isNot(closeTo(1, 0.001)));
    await tester.pump(kBoingDuration);
  });

  testWidgets('reduced motion skips the boing', (tester) async {
    await pumpButton(
      tester,
      _pressable(onPressed: () {}),
      disableAnimations: true,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_key)),
    );
    await tester.pump();
    await tester.pump(kPressDownDuration);
    expect(faceDy(tester), closeTo(4, 0.01));

    await gesture.up();
    await tester.pump();
    await tester.pump(kBoingDuration ~/ 4);
    // No squash: only the release offset animates, without overshoot.
    expect(faceScaleX(tester), 1);
    expect(faceDy(tester), inInclusiveRange(0, 4));

    await tester.pump(kPressReleaseDuration);
    expect(faceDy(tester), closeTo(0, 0.01));
  });

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.space]) {
    testWidgets('${key.keyLabel} activates when focused', (tester) async {
      var taps = 0;
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await pumpButton(
        tester,
        _pressable(onPressed: () => taps++, focusNode: focusNode),
      );

      focusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(key);
      await tester.pump();
      await tester.pump(kPressDownDuration);
      await tester.pump(kBoingDuration);

      expect(taps, 1);
    });
  }

  testWidgets('s28 keeps a 48 px tap target around the visible face', (
    tester,
  ) async {
    var taps = 0;
    const key = ValueKey('small');
    await pumpButton(
      tester,
      OurnegoIconButton(
        key: key,
        size: OurnegoIconButtonSize.s28,
        icon: Icons.edit_rounded,
        semanticLabel: 'Editar',
        onPressed: () => taps++,
      ),
    );

    final rect = tester.getRect(find.byKey(key));
    expect(rect.width, 28);

    // 10 px outside the visible face, still inside the 48 px target.
    await tester.tapAt(rect.centerLeft - const Offset(10, 0));
    await tester.pump(kBoingDuration);
    expect(taps, 1);

    // Clearly outside the target.
    await tester.tapAt(rect.centerLeft - const Offset(14, 0));
    await tester.pump(kBoingDuration);
    expect(taps, 1);
  });
}
