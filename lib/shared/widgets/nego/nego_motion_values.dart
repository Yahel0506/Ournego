import 'package:flutter/foundation.dart';

@immutable
class NegoMotionValues {
  const NegoMotionValues({
    required this.bodyTranslationY,
    required this.bodyRotationDegrees,
    required this.lookRotationDegrees,
    required this.eyeOffsetX,
    required this.eyeOffsetY,
    required this.blinkScaleY,
    required this.happyPulseScale,
    required this.happyPulseOpacity,
    required this.happyBodyScale,
    required this.happyGlowScale,
  });

  final double bodyTranslationY;
  final double bodyRotationDegrees;
  final double lookRotationDegrees;
  final double eyeOffsetX;
  final double eyeOffsetY;
  final double blinkScaleY;
  final double happyPulseScale;
  final double happyPulseOpacity;
  final double happyBodyScale;
  final double happyGlowScale;

  static const NegoMotionValues zero = NegoMotionValues(
    bodyTranslationY: 0,
    bodyRotationDegrees: 0,
    lookRotationDegrees: 0,
    eyeOffsetX: 0,
    eyeOffsetY: 0,
    blinkScaleY: 1,
    happyPulseScale: 0.9,
    happyPulseOpacity: 0,
    happyBodyScale: 1,
    happyGlowScale: 1,
  );
}
