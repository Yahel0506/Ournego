import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/motion/spring_clock.dart';
import 'package:ournego/core/ournego_motion.dart';

void main() {
  late SpringClock clock;

  setUp(() {
    clock = SpringClock(vsync: const TestVSync(), preset: kDialogSpring);
  });
  tearDown(() => clock.dispose());

  Future<void> run(WidgetTester tester, [int ms = 1000]) async {
    for (var t = 0; t < ms; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
    }
  }

  testWidgets('springs to the target and settles there', (tester) async {
    final settled = <double>[];
    clock.onSettled = settled.add;

    clock.animateTo(1);
    await run(tester);

    expect(clock.value, closeTo(1, 0.01));
    expect(clock.isAnimating, isFalse);
    expect(settled, [1.0]);
  });

  testWidgets('a calm preset never overshoots visibly', (tester) async {
    clock.animateTo(1);
    var peak = 0.0;
    for (var t = 0; t < 600; t += 16) {
      await tester.pump(const Duration(milliseconds: 16));
      if (clock.value > peak) peak = clock.value;
    }
    expect(peak, lessThan(1.02));
  });

  testWidgets('reversing mid-way keeps the position and the velocity', (
    tester,
  ) async {
    clock.animateTo(1);
    await run(tester, 80);
    final p = clock.value;
    final v = clock.velocity;
    expect(p, inExclusiveRange(0.05, 0.95));
    expect(v, greaterThan(0));

    clock.animateTo(0);
    // No jump: the first frame after the interruption continues from p.
    expect(clock.value, closeTo(p, 1e-6));
    expect(clock.velocity, closeTo(v, 1e-6));

    await run(tester);
    expect(clock.value, closeTo(0, 0.01));
  });

  testWidgets('an interrupted spring does not report as settled', (
    tester,
  ) async {
    final settled = <double>[];
    clock.onSettled = settled.add;

    clock.animateTo(1);
    await run(tester, 60);
    clock.animateTo(0);
    await run(tester);

    expect(settled, [0.0]);
    expect(clock.target, 0);
  });

  testWidgets('dragTo follows the finger with no velocity', (tester) async {
    clock.animateTo(1);
    await run(tester, 60);

    clock.dragTo(0.3);
    expect(clock.value, 0.3);
    expect(clock.velocity, 0);
    expect(clock.isAnimating, isFalse);
  });

  testWidgets('release springs on in the direction of the fling', (
    tester,
  ) async {
    clock.dragTo(0.4);
    clock.release(velocity: 6);
    expect(clock.target, 1);
    await run(tester);
    expect(clock.value, closeTo(1, 0.01));

    clock.dragTo(0.6);
    clock.release(velocity: -6);
    expect(clock.target, 0);
    await run(tester);
    expect(clock.value, closeTo(0, 0.01));
  });

  testWidgets('release with no velocity snaps to the nearest end', (
    tester,
  ) async {
    clock.dragTo(0.7);
    clock.release(velocity: 0);
    expect(clock.target, 1);
    await run(tester);

    clock.dragTo(0.2);
    clock.release(velocity: 0);
    expect(clock.target, 0);
  });

  testWidgets('jumpTo restores a value without animating', (tester) async {
    clock.jumpTo(1);
    expect(clock.value, 1);
    expect(clock.target, 1);
    expect(clock.isAnimating, isFalse);
  });
}
