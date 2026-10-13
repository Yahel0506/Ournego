import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_glass_pressable.dart';

import 'button_test_helpers.dart';

const _key = ValueKey('glass');

Widget _glass({
  VoidCallback? onPressed,
  bool active = false,
  bool showHalo = false,
}) {
  return OurnegoGlassPressable(
    key: _key,
    onPressed: onPressed,
    height: 52,
    width: 52,
    active: active,
    showHalo: showHalo,
    semanticLabel: 'Buscar por voz',
    child: const Icon(Icons.mic_none_rounded),
  );
}

double _scale(WidgetTester tester) => tester
    .widget<Transform>(find.byKey(ournegoGlassScaleKey))
    .transform
    .storage[0];

BoxDecoration _glassDecoration(WidgetTester tester) {
  final container = tester.widget<AnimatedContainer>(
    find.descendant(
      of: find.byKey(_key),
      matching: find.byType(AnimatedContainer),
    ),
  );
  return container.decoration! as BoxDecoration;
}

void main() {
  testWidgets('has no lip: total height equals the face', (tester) async {
    await pumpButton(tester, _glass(onPressed: () {}));
    expect(tester.getSize(find.byKey(_key)), const Size(52, 52));
  });

  testWidgets('press scales to 0.96 and release never overshoots 1.0', (
    tester,
  ) async {
    await pumpButton(tester, _glass(onPressed: () {}));

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(_key)),
    );
    await tester.pump();
    await tester.pump(kGlassPressDuration);
    expect(_scale(tester), closeTo(0.96, 0.0001));

    await gesture.up();
    await tester.pump();
    var previous = _scale(tester);
    const frame = Duration(milliseconds: 16);
    for (
      var elapsed = Duration.zero;
      elapsed <= kGlassReleaseDuration + frame;
      elapsed += frame
    ) {
      await tester.pump(frame);
      final scale = _scale(tester);
      expect(scale, lessThanOrEqualTo(1.0));
      expect(scale, greaterThanOrEqualTo(previous - 1e-9));
      previous = scale;
    }
    expect(_scale(tester), closeTo(1, 0.0001));
  });

  testWidgets('rest contour is 1 px borderSubtle', (tester) async {
    for (final theme in [OurnegoTheme.light, OurnegoTheme.dark]) {
      await pumpButton(tester, _glass(onPressed: () {}), theme: theme);
      await tester.pumpAndSettle();
      final border = _glassDecoration(tester).border! as Border;
      expect(border.top.width, 1);
      expect(
        border.top.color,
        OurnegoSemanticTokens.borderSubtle(theme.colorScheme),
      );
    }
  });

  testWidgets('uses a BackdropFilter', (tester) async {
    await pumpButton(tester, _glass(onPressed: () {}));
    expect(
      find.descendant(
        of: find.byKey(_key),
        matching: find.byType(BackdropFilter),
      ),
      findsOneWidget,
    );
  });

  testWidgets('active with showHalo shows the halo', (tester) async {
    await pumpButton(tester, _glass(onPressed: () {}));
    expect(find.byKey(ournegoListeningHaloKey), findsNothing);

    await pumpButton(
      tester,
      _glass(onPressed: () {}, active: true, showHalo: true),
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(ournegoListeningHaloKey), findsOneWidget);

    double haloOpacity() => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byKey(ournegoListeningHaloKey),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    final first = haloOpacity();
    await tester.pump(const Duration(milliseconds: 400));
    expect(haloOpacity(), isNot(first));
  });

  testWidgets('reduced motion keeps the halo still at 40%', (tester) async {
    await pumpButton(
      tester,
      _glass(onPressed: () {}, active: true, showHalo: true),
      disableAnimations: true,
    );
    await tester.pump(const Duration(milliseconds: 300));

    double haloOpacity() => tester
        .widget<Opacity>(
          find.descendant(
            of: find.byKey(ournegoListeningHaloKey),
            matching: find.byType(Opacity),
          ),
        )
        .opacity;
    expect(haloOpacity(), closeTo(0.4, 0.001));
    await tester.pump(const Duration(milliseconds: 700));
    expect(haloOpacity(), closeTo(0.4, 0.001));
  });

  testWidgets('tap calls onPressed; null disables it', (tester) async {
    var taps = 0;
    await pumpButton(tester, _glass(onPressed: () => taps++));
    await tester.tap(find.byKey(_key));
    await tester.pump(kGlassReleaseDuration);
    expect(taps, 1);

    await pumpButton(tester, _glass());
    await tester.tap(find.byKey(_key), warnIfMissed: false);
    await tester.pump(kGlassReleaseDuration);
    expect(taps, 1);
  });
}
