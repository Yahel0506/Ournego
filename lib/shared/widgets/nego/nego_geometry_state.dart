import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'nego_mood.dart';
import 'nego_tokens.dart';

@immutable
class NegoGeometryState {
  const NegoGeometryState({
    required this.eyeWidth,
    required this.eyeHeight,
    required this.eyeRadius,
    required this.eyeGroupYOffset,
    required this.bodyScale,
    required this.glowScale,
    required this.glowOpacity,
    required this.floatAmplitude,
    required this.floatDuration,
  });

  final double eyeWidth;
  final double eyeHeight;
  final double eyeRadius;
  final double eyeGroupYOffset;
  final double bodyScale;
  final double glowScale;
  final double glowOpacity;
  final double floatAmplitude;
  final Duration floatDuration;

  static NegoGeometryState forMood({required NegoMood mood}) {
    switch (mood) {
      case NegoMood.idle:
      case NegoMood.looking:
        return const NegoGeometryState(
          eyeWidth: NegoTokens.eyeIdleWidth,
          eyeHeight: NegoTokens.eyeIdleHeight,
          eyeRadius: NegoTokens.eyeIdleRadius,
          eyeGroupYOffset: 0,
          bodyScale: 1.0,
          glowScale: NegoTokens.glowScaleIdle,
          glowOpacity: NegoTokens.glowOpacityIdle,
          floatAmplitude: 14,
          floatDuration: NegoTokens.idleFloatDuration,
        );
      case NegoMood.excited:
        return const NegoGeometryState(
          eyeWidth: NegoTokens.eyeExcitedWidth,
          eyeHeight: NegoTokens.eyeExcitedHeight,
          eyeRadius: NegoTokens.eyeExcitedRadius,
          eyeGroupYOffset: -10.0,
          bodyScale: 1.04,
          glowScale: NegoTokens.glowScaleExcited,
          glowOpacity: NegoTokens.glowOpacityExcited,
          floatAmplitude: 18,
          floatDuration: NegoTokens.activeFloatDuration,
        );
      case NegoMood.winking:
        return const NegoGeometryState(
          eyeWidth: NegoTokens.eyeIdleWidth,
          eyeHeight: NegoTokens.eyeIdleHeight,
          eyeRadius: NegoTokens.eyeIdleRadius,
          eyeGroupYOffset: -10.0,
          bodyScale: 1.04,
          glowScale: NegoTokens.glowScaleWinking,
          glowOpacity: NegoTokens.glowOpacityWinking,
          floatAmplitude: 18,
          floatDuration: NegoTokens.activeFloatDuration,
        );
      case NegoMood.happy:
        return const NegoGeometryState(
          eyeWidth: NegoTokens.eyeHappyWidth,
          eyeHeight: NegoTokens.eyeHappyHeight,
          eyeRadius: NegoTokens.eyeHappyRadius,
          eyeGroupYOffset: 0,
          bodyScale: 1.0,
          glowScale: NegoTokens.glowScaleHappy,
          glowOpacity: NegoTokens.glowOpacityHappy,
          floatAmplitude: 14,
          floatDuration: NegoTokens.idleFloatDuration,
        );
    }
  }

  static NegoGeometryState lerp(
    NegoGeometryState begin,
    NegoGeometryState end,
    double t,
  ) {
    return NegoGeometryState(
      eyeWidth: lerpDouble(begin.eyeWidth, end.eyeWidth, t)!,
      eyeHeight: lerpDouble(begin.eyeHeight, end.eyeHeight, t)!,
      eyeRadius: lerpDouble(begin.eyeRadius, end.eyeRadius, t)!,
      eyeGroupYOffset: lerpDouble(begin.eyeGroupYOffset, end.eyeGroupYOffset, t)!,
      bodyScale: lerpDouble(begin.bodyScale, end.bodyScale, t)!,
      glowScale: lerpDouble(begin.glowScale, end.glowScale, t)!,
      glowOpacity: lerpDouble(begin.glowOpacity, end.glowOpacity, t)!,
      floatAmplitude: lerpDouble(begin.floatAmplitude, end.floatAmplitude, t)!,
      floatDuration: t < 0.5 ? begin.floatDuration : end.floatDuration,
    );
  }
}
