import 'package:flutter/widgets.dart';
import 'package:flutter/physics.dart';

import 'package:ournego/core/ournego_motion.dart';

/// The clock `p` of a surface that lives inside the widget tree (the search
/// panel, the floating sheet) instead of in a route.
///
/// It is an unbounded [AnimationController] driven by springs. Every new target
/// starts from the current value *and* velocity, so an interruption never
/// restarts or jumps; during a drag the value follows the finger directly.
class SpringClock {
  SpringClock({
    required TickerProvider vsync,
    required this.preset,
    double initial = 0,
  }) : _target = initial,
       _controller = AnimationController.unbounded(
         vsync: vsync,
         value: initial,
       ) {
    _controller.addStatusListener(_onStatus);
  }

  /// Can be swapped between movements, e.g. a slower spring for one origin.
  OurnegoSpringPreset preset;
  final AnimationController _controller;
  double _target;

  /// Called when a spring comes to rest, with the target it reached. A spring
  /// that is interrupted by another one never reports: check `target == 0`
  /// before tearing anything down.
  void Function(double target)? onSettled;

  Animation<double> get animation => _controller.view;
  double get value => _controller.value;
  double get velocity => _controller.velocity;
  double get target => _target;
  bool get isAnimating => _controller.isAnimating;

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      onSettled?.call(_target);
    }
  }

  /// Springs to [target] from the current value and velocity. Targets above
  /// 0.5 use the opening spring, the others the closing one.
  void animateTo(double target) =>
      settleTo(target, velocity: _controller.velocity);

  /// Springs to [target] starting at [velocity] (units of `p` per second), e.g.
  /// the speed a finger left on a drag.
  void settleTo(double target, {double velocity = 0}) {
    _target = target;
    final spring = target > 0.5 ? preset.open : preset.close;
    _controller.animateWith(
      SpringSimulation(
        spring,
        _controller.value,
        target,
        velocity,
        tolerance: kOurnegoSpringTolerance,
      ),
    );
  }

  /// Follows a drag: no spring, zero velocity.
  void dragTo(double p) {
    _controller.stop();
    _controller.value = p;
  }

  /// Ends a drag: springs to 1 or 0 depending on where the value is going.
  void release({required double velocity, double threshold = 0.5}) {
    // The value 0.1 s from now is a good guess of where the finger was heading.
    final projected = _controller.value + velocity * 0.1;
    settleTo(projected >= threshold ? 1.0 : 0.0, velocity: velocity);
  }

  /// Sets the value with no animation, e.g. when restoring from storage.
  void jumpTo(double p) {
    _controller.stop();
    _target = p;
    _controller.value = p;
  }

  void dispose() {
    _controller.removeStatusListener(_onStatus);
    _controller.dispose();
  }
}
