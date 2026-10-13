import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// How much of the container transform a surface plays.
enum OurnegoMotionLevel {
  /// Per-item blur on top of alpha and translate.
  b,

  /// Alpha and translate only, no blur.
  c,

  /// Reduced motion: a short fade, no travel, scale, blur or stagger.
  r,
}

/// Global switch for the container transform. When false every window falls
/// back to the reduced variant, so a faulty wave can be turned off without
/// reverting code. Exposed in the debug panel.
class OurnegoMotion {
  OurnegoMotion._();

  static final ValueNotifier<bool> containerTransformEnabled =
      ValueNotifier<bool>(true);

  /// Resolves the level for [context]. [wantsBlur] is the preset's own
  /// preference (level B); large or frequent surfaces pass false and stay in C.
  static OurnegoMotionLevel resolveLevel(
    BuildContext context, {
    bool wantsBlur = false,
  }) {
    if (!containerTransformEnabled.value ||
        MediaQuery.disableAnimationsOf(context)) {
      return OurnegoMotionLevel.r;
    }
    if (wantsBlur && !kIsWeb) return OurnegoMotionLevel.b;
    return OurnegoMotionLevel.c;
  }
}
