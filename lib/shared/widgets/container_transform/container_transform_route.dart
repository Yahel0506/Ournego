import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'package:ournego/core/motion/ournego_motion_level.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';

/// A popup route whose clock `p` is a spring instead of a fixed-duration tween.
///
/// Flutter calls [createSimulation] on every push and pop, starting from the
/// controller's current value and velocity. That is what makes it interruptible:
/// closing half way through opening continues from where it was, without a jump.
///
/// The route owns the scrim (a `ModalBarrier`, which responds from the first
/// frame), back and Esc. What grows from the trigger is drawn by the
/// [ContainerTransformDestination] inside the page.
class ContainerTransformRoute<T> extends PopupRoute<T> {
  ContainerTransformRoute({
    required this.builder,
    required this.capturedThemes,
    required this.motionLevel,
    required this.preset,
    required this.scrimAlpha,
    this.origin,
    this.staticOrigin,
    this.returnOrigin,
    this.useSafeArea = true,
    this.dismissible = true,
    this.rise = false,
    this.label,
    super.settings,
  });

  final WidgetBuilder builder;
  final CapturedThemes capturedThemes;
  final OurnegoMotionLevel motionLevel;
  final OurnegoSpringPreset preset;
  final double scrimAlpha;
  final ContainerTransformOriginController? origin;
  final ContainerTransformOriginData? staticOrigin;
  final ContainerTransformOriginController? returnOrigin;

  /// Whether the page is inset by the system's safe area. Popovers place
  /// themselves in screen coordinates, so they turn it off.
  final bool useSafeArea;
  final bool dismissible;

  /// See [ContainerTransformController.rise].
  final bool rise;
  final String? label;

  ContainerTransformController? _transform;

  @override
  void install() {
    super.install();
    _transform = ContainerTransformController(
      animation: animation!,
      preset: preset,
      level: motionLevel,
      originSource: origin,
      staticOrigin: staticOrigin,
      returnSource: returnOrigin,
      rise: rise,
    );
    animation!.addListener(_syncTrigger);
    origin?.setHasWindow(true);
  }

  /// Hides the trigger once the container has taken over from it, and shows it
  /// again when the container is back on top of it.
  void _syncTrigger() {
    if (motionLevel == OurnegoMotionLevel.r) return;
    final covered = animation!.value >= kTriggerCoveredAt;
    origin?.setCovered(covered);
    // The return target is only covered on the way back: while the window opens
    // it grows out of something else.
    if (_closing) returnOrigin?.setCovered(covered);
  }

  bool _closing = false;

  /// Progress `p` of the window, for sheets that follow a finger.
  double get progress => controller!.value;

  /// The finger sets `p` directly, with no spring in the way.
  void dragTo(double p) => controller!.value = p.clamp(0.0, 1.0);

  /// Ends a drag: the window either closes (continuing from where the finger
  /// left it) or springs back open with the finger's [velocity] (in units of
  /// `p` per second, positive towards open).
  void endDrag({required bool dismiss, double velocity = 0}) {
    final nav = navigator;
    if (dismiss) {
      nav?.pop();
    } else {
      controller!.animateWith(
        SpringSimulation(
          preset.open,
          controller!.value,
          1,
          velocity,
          tolerance: kOurnegoSpringTolerance,
        ),
      );
    }
  }

  @override
  bool didPop(T? result) {
    _closing = true;
    _transform?.remeasureOrigin();
    returnOrigin?.setHasWindow(true);
    return super.didPop(result);
  }

  @override
  void dispose() {
    animation?.removeListener(_syncTrigger);
    origin?.setCovered(false);
    origin?.setHasWindow(false);
    returnOrigin?.setCovered(false);
    returnOrigin?.setHasWindow(false);
    super.dispose();
  }

  @override
  Simulation? createSimulation({required bool forward}) {
    if (motionLevel == OurnegoMotionLevel.r) return null;
    return SpringSimulation(
      forward ? preset.open : preset.close,
      controller!.value,
      forward ? 1 : 0,
      controller!.velocity,
      tolerance: kOurnegoSpringTolerance,
    );
  }

  /// Only used by the reduced-motion fade; the springs set their own pace.
  @override
  Duration get transitionDuration => kReducedMotionFadeDuration;

  @override
  bool get barrierDismissible => dismissible;

  @override
  String? get barrierLabel => label;

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: scrimAlpha);

  /// The scrim reaches its full alpha while the container is still growing.
  @override
  Curve get barrierCurve => const Interval(0, 0.6);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return ContainerTransformScope(
      controller: _transform!,
      child: Semantics(
        scopesRoute: true,
        explicitChildNodes: true,
        child: useSafeArea
            ? SafeArea(child: capturedThemes.wrap(Builder(builder: builder)))
            : capturedThemes.wrap(Builder(builder: builder)),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _BackGestureObserver(
      route: this,
      child: _FallbackFade(
        controller: _transform!,
        animation: animation,
        child: child,
      ),
    );
  }
}

/// Lets Android's predictive back drive the window: while the finger swipes,
/// the window's progress `p` follows it (so it shrinks back towards where it
/// came from), and when it is let go the window either closes or springs open
/// again with its own spring. The route does the rest (see
/// [TransitionRoute.handleStartBackGesture]); this only forwards the events,
/// the way Material's predictive back transitions do.
class _BackGestureObserver extends StatefulWidget {
  const _BackGestureObserver({required this.route, required this.child});

  final ContainerTransformRoute<dynamic> route;
  final Widget child;

  @override
  State<_BackGestureObserver> createState() => _BackGestureObserverState();
}

class _BackGestureObserverState extends State<_BackGestureObserver>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  bool handleStartBackGesture(PredictiveBackEvent backEvent) {
    final route = widget.route;
    // A back button press is not a gesture: it pops the usual way.
    if (backEvent.isButtonEvent ||
        !route.isCurrent ||
        !route.popGestureEnabled) {
      return false;
    }
    route.handleStartBackGesture(progress: 1 - backEvent.progress);
    return true;
  }

  @override
  void handleUpdateBackGestureProgress(PredictiveBackEvent backEvent) {
    widget.route.handleUpdateBackGestureProgress(
      progress: 1 - backEvent.progress,
    );
  }

  @override
  void handleCancelBackGesture() => widget.route.handleCancelBackGesture();

  @override
  void handleCommitBackGesture() => widget.route.handleCommitBackGesture();

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A window that has no [ContainerTransformDestination] (for example a plain
/// Material dialog) still gets a fade instead of popping in.
class _FallbackFade extends StatelessWidget {
  const _FallbackFade({
    required this.controller,
    required this.animation,
    required this.child,
  });

  final ContainerTransformController controller;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) => Opacity(
        opacity: controller.hasDestination
            ? 1
            : animation.value.clamp(0.0, 1.0),
        child: child,
      ),
    );
  }
}
