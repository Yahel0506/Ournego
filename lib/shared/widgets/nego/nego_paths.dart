import 'package:flutter/widgets.dart';

import 'nego_tokens.dart';

class NegoPaths {
  NegoPaths._();

  static Path eyePath({
    double width = NegoTokens.eyeViewBoxWidth,
    double height = NegoTokens.eyeViewBoxHeight,
    double radius = NegoTokens.eyeIdleRadius,
  }) {
    final double bottomY = height - radius;
    return Path()
      ..moveTo(radius, 0)
      ..lineTo(width - radius, 0)
      ..cubicTo(width - radius / 2, 0, width, radius / 2, width, radius)
      ..lineTo(width, bottomY)
      ..cubicTo(
        width,
        height - radius / 2,
        width - radius / 2,
        height,
        width - radius,
        height,
      )
      ..lineTo(radius, height)
      ..cubicTo(radius / 2, height, 0, height - radius / 2, 0, bottomY)
      ..lineTo(0, radius)
      ..cubicTo(0, radius / 2, radius / 2, 0, radius, 0)
      ..close();
  }

  static Path excitedCutoutActive() {
    return Path()
      ..moveTo(0, 132)
      ..lineTo(68, 132)
      ..lineTo(68, 108)
      ..cubicTo(56, 96, 46, 90, 34, 90)
      ..cubicTo(22, 90, 12, 96, 0, 108)
      ..close();
  }

  static Path excitedCutoutInactive() {
    return Path()
      ..moveTo(0, 150)
      ..lineTo(68, 150)
      ..lineTo(68, 150)
      ..lineTo(0, 150)
      ..close();
  }

  static Path winkingCutoutActive() {
    return Path()
      ..moveTo(68, 18)
      ..lineTo(68, 96)
      ..lineTo(30, 96)
      ..quadraticBezierTo(10, 96, 20, 80)
      ..lineTo(62, 23)
      ..lineTo(68, 18)
      ..close();
  }

  static Path winkingCutoutInactive() {
    // Matches the reference JSX/README: a degenerate path positioned outside
    // the 68px viewBox width so it never appears in non-winking moods.
    return Path()
      ..moveTo(92, 66)
      ..lineTo(92, 66)
      ..quadraticBezierTo(92, 66, 92, 66)
      ..lineTo(92, 66)
      ..quadraticBezierTo(92, 66, 92, 66)
      ..lineTo(92, 66)
      ..quadraticBezierTo(92, 66, 92, 66)
      ..close();
  }
}
