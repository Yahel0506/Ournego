import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';

class NegoTokens {
  NegoTokens._();

  static const double baseSize = 256;
  static const double faceStrokeWidth = 10;
  static const double eyeViewBoxWidth = 68;
  static const double eyeViewBoxHeight = 132;
  static const double eyeIdleWidth = 56;
  static const double eyeIdleHeight = 132;
  static const double eyeIdleRadius = 24;
  static const double eyeExcitedWidth = 68;
  static const double eyeExcitedHeight = 122;
  static const double eyeExcitedRadius = 28;
  static const double eyeHappyWidth = 64;
  static const double eyeHappyHeight = 104;
  static const double eyeHappyRadius = 26;
  static const double eyeBaseGap = 8;
  static const double bodyRotationRange = 5;
  static const double eyePointerXRange = 7;
  static const double eyePointerYRange = 4;
  static const double lookAngleMin = -35;
  static const double lookAngleMax = 35;
  static const double lookAngleDefault = -18;
  static const double lookVerticalMultiplier = 0.78;
  static const double lookIntensityMin = 12;
  static const double blinkScaleY = 0.08;
  static const double blinkOpenScaleY = 1.0;
  static const double blinkClosedDurationMs = 60;
  static const double blinkOpenDurationMs = 120;
  // Total "blink=true" time in the reference JSX is 120ms.
  // With close=60ms and open=120ms, we keep the eye fully closed for 60ms.
  static const Duration blinkClosedHold = Duration(milliseconds: 60);

  static const Color faceFill = Color(0xFFDFFDF1);
  static const Color faceStroke = Color(0xFF7EEFC2);
  static const Color eyeFill = Color(0xFF3BCFED);
  static const Color glowColor = Color(0xFFDFFDF1);

  static const Duration idleFloatDuration = Duration(milliseconds: 3200);
  static const Duration activeFloatDuration = Duration(milliseconds: 2200);
  static const Duration eyeSizeTransition = Duration(milliseconds: 180);
  static const Duration eyePathTransition = Duration(milliseconds: 200);
  static const Duration excitedCutoutTransition = Duration(milliseconds: 280);
  static const Duration winkingCutoutTransition = Duration(milliseconds: 220);
  static const Duration motionTransition = Duration(milliseconds: 220);
  static const Duration glowTransition = Duration(milliseconds: 350);
  static const Duration happyPulseDuration = Duration(milliseconds: 650);
  static const Duration happyTemporaryDuration = Duration(milliseconds: 850);
  static const Duration idleBlinkMinDelay = Duration(milliseconds: 1400);
  static const Duration idleBlinkMaxDelay = Duration(milliseconds: 5000);

  static const Curve motionCurve = Curves.easeInOut;
  static const Curve quickCurve = Curves.easeOut;
  static const Curve cutoutCurve = Cubic(0.16, 1.0, 0.3, 1.0);

  static const double glowOpacityIdle = 0.35;
  static const double glowOpacityExcited = 0.62;
  static const double glowOpacityWinking = 0.62;
  static const double glowOpacityHappy = 0.80;
  static const double glowScaleIdle = 1.0;
  static const double glowScaleExcited = 1.08;
  static const double glowScaleWinking = 1.08;
  static const double glowScaleHappy = 1.16;
}
