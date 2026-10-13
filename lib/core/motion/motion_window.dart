import 'package:flutter/animation.dart';

/// Local progress of a property inside its own window of the clock `p`.
///
/// `p` is not bounded (a spring can overshoot or, when interrupted, go below
/// 0), so the result is always clamped to [0, 1] before the [curve] is applied.
double seg(double p, double a, double b, [Curve curve = Curves.linear]) {
  assert(b > a, 'The window end must be greater than its start.');
  return curve.transform(((p - a) / (b - a)).clamp(0.0, 1.0));
}

/// A `[start, end]` window of `p` with its curve.
class MotionWindow {
  const MotionWindow(this.start, this.end, [this.curve = Curves.easeOut]);

  final double start;
  final double end;
  final Curve curve;

  double at(double p) => seg(p, start, end, curve);

  /// The same window shifted by [offset], used to stagger list items.
  MotionWindow shifted(double offset) =>
      MotionWindow(start + offset, end + offset, curve);
}
