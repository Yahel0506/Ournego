import 'package:flutter/animation.dart';

import 'package:ournego/core/ournego_motion.dart';

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

/// Blur sigma in dp of content that travels with a container: constant while it
/// travels, cleared from `preset.blurClearStart` (slowly at first, since a
/// spring's tail is slow) and exactly 0 at `p = 1`. Windows and the floating
/// sheet share it.
double transitBlurSigma(double p, OurnegoSpringPreset preset) {
  final cleared = seg(p, preset.blurClearStart, 1, Curves.easeInQuad);
  return preset.maxItemBlur * (1 - cleared);
}
