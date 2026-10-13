import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/widgets/nego/nego_avatar.dart';
import 'package:ournego/shared/widgets/nego/nego_mood.dart';
import 'package:ournego/shared/widgets/nego/nego_painter.dart';
import 'package:ournego/shared/widgets/nego/nego_tokens.dart';

NegoPainter _painter(WidgetTester tester) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(
      of: find.byType(NegoAvatar),
      matching: find.byWidgetPredicate(
        (widget) => widget is CustomPaint && widget.painter is NegoPainter,
      ),
    ),
  );
  return paint.painter! as NegoPainter;
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('renders and reacts to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NegoAvatar(
              size: 256,
              interactive: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CustomPaint).first);
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('builds as decorative content when interaction is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: NegoAvatar(size: 220, interactive: false)),
        ),
      ),
    );

    expect(find.byType(NegoAvatar), findsOneWidget);
  });

  testWidgets('eyesClosed holds the eyes closed and schedules no blinks', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const NegoAvatar(
          size: 30,
          interactive: false,
          floating: false,
          eyesClosed: true,
        ),
      ),
    );

    expect(_painter(tester).motion.blinkScaleY, NegoTokens.eyesClosedScaleY);

    // Longer than the max blink delay: no blink may open the eyes.
    await tester.pump(const Duration(seconds: 6));
    expect(_painter(tester).motion.blinkScaleY, NegoTokens.eyesClosedScaleY);
    expect(tester.binding.hasScheduledFrame, isFalse);

    await tester.pumpWidget(
      _host(const NegoAvatar(size: 30, interactive: false, floating: false)),
    );
    await tester.pump();
    expect(_painter(tester).motion.blinkScaleY, 1);
  });

  testWidgets('happyTrigger turns Nego happy even when not interactive', (
    tester,
  ) async {
    Widget avatar(Object? trigger) => _host(
      NegoAvatar(
        size: 30,
        interactive: false,
        floating: false,
        happyTrigger: trigger,
      ),
    );

    await tester.pumpWidget(avatar(null));
    expect(_painter(tester).mood, NegoMood.idle);

    await tester.pumpWidget(avatar(1));
    await tester.pump();
    expect(_painter(tester).mood, NegoMood.happy);

    await tester.pump(NegoTokens.happyTemporaryDuration ~/ 2);
    expect(_painter(tester).mood, NegoMood.happy);

    await tester.pump(NegoTokens.happyTemporaryDuration);
    await tester.pump();
    expect(_painter(tester).mood, NegoMood.idle);
  });

  testWidgets(
    'floating: false keeps the body still and lets pumpAndSettle end',
    (tester) async {
      await tester.pumpWidget(
        _host(const NegoAvatar(size: 30, interactive: false, floating: false)),
      );

      await tester.pumpAndSettle();
      expect(_painter(tester).motion.bodyTranslationY, 0);
    },
  );
}
