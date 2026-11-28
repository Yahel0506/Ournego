import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/routing/route_observer.dart';
import 'package:ournego/shared/widgets/animated_background.dart';

Widget _app({bool disableAnimations = false, Widget? home}) {
  return MaterialApp(
    navigatorObservers: [AppRouteObserver.instance],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(disableAnimations: disableAnimations),
      child: child!,
    ),
    home: home ?? const Scaffold(body: Stack(children: [AnimatedBackground()])),
  );
}

Finder get _backgroundPaint => find.descendant(
  of: find.byType(AnimatedBackground),
  matching: find.byType(CustomPaint),
);

void main() {
  setUp(AppRouteObserver.instance.clear);

  testWidgets('paints the blobs in their own repaint boundary, no blur', (
    tester,
  ) async {
    await tester.pumpWidget(_app());

    expect(_backgroundPaint, findsWidgets);
    expect(
      find.descendant(
        of: find.byType(AnimatedBackground),
        matching: find.byType(RepaintBoundary),
      ),
      findsWidgets,
    );
    // The blur of the blobs is baked into them: a BackdropFilter would blur
    // everything below it on every frame.
    expect(
      find.descendant(
        of: find.byType(AnimatedBackground),
        matching: find.byType(BackdropFilter),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('keeps drifting without rebuilding the widget', (tester) async {
    await tester.pumpWidget(_app());
    final painter = tester.widget<CustomPaint>(_backgroundPaint.first).painter;

    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.pump(const Duration(seconds: 2));
    expect(tester.binding.hasScheduledFrame, isTrue);
    // Repaints come from the controller; the painter is not recreated.
    expect(tester.widget<CustomPaint>(_backgroundPaint.first).painter, painter);
  });

  testWidgets('stays still when the system asks for reduced motion', (
    tester,
  ) async {
    await tester.pumpWidget(_app(disableAnimations: true));
    await tester.pump(const Duration(seconds: 1));

    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(_backgroundPaint, findsWidgets);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('pauses while the app is in the background', (tester) async {
    await tester.pumpWidget(_app());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(tester.binding.hasScheduledFrame, isFalse);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('pauses while another route covers it and resumes on return', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        home: Builder(
          builder: (context) => Scaffold(
            body: Stack(
              children: [
                const AnimatedBackground(),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const Scaffold(body: Text('next')),
                    ),
                  ),
                  child: const Text('push'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(tester.binding.hasScheduledFrame, isTrue);

    await tester.tap(find.text('push'));
    await tester.pumpAndSettle();
    expect(find.text('next'), findsOneWidget);
    // Nothing left running under the covering route.
    expect(tester.binding.hasScheduledFrame, isFalse);

    Navigator.of(tester.element(find.text('next'))).pop();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.binding.hasScheduledFrame, isTrue);
  });

  testWidgets('renders custom blobs and a zero blur sigma', (tester) async {
    await tester.pumpWidget(
      _app(
        home: const Scaffold(
          body: Stack(
            children: [
              AnimatedBackground(
                blurSigma: 0,
                blobs: [
                  AnimatedBackgroundBlob(
                    color: Colors.red,
                    width: 100,
                    height: 160,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.takeException(), isNull);
  });
}
