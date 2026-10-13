import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'nego_geometry_state.dart';
import 'nego_motion_values.dart';
import 'nego_mood.dart';
import 'nego_paths.dart';
import 'nego_tokens.dart';

class NegoPainter extends CustomPainter {
  NegoPainter({
    required this.size,
    required this.geometry,
    required this.motion,
    required this.mood,
  });

  final double size;
  final NegoGeometryState geometry;
  final NegoMotionValues motion;
  final NegoMood mood;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final double scale = size / NegoTokens.baseSize;
    final Offset center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final double faceStrokeWidth = NegoTokens.faceStrokeWidth * scale;
    final double faceRadius =
        (math.min(canvasSize.width, canvasSize.height) / 2) -
        (faceStrokeWidth / 2);
    final double glowRadius = faceRadius * geometry.glowScale;
    final double bodyScale = geometry.bodyScale * motion.happyBodyScale;

    canvas.save();
    canvas.translate(center.dx, center.dy + (motion.bodyTranslationY * scale));
    canvas.rotate(motion.bodyRotationDegrees * math.pi / 180);
    canvas.scale(bodyScale, bodyScale);
    canvas.translate(-center.dx, -center.dy);

    _drawGlow(
      canvas,
      center,
      glowRadius,
      scale: scale,
      opacity: geometry.glowOpacity,
    );

    final Paint faceFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = NegoTokens.faceFill;
    final Paint faceStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = faceStrokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = NegoTokens.faceStroke;

    canvas.drawCircle(center, faceRadius, faceFillPaint);
    canvas.drawCircle(center, faceRadius, faceStrokePaint);

    _drawPulse(canvas, center, faceRadius, scale);
    _drawEyes(canvas, center, scale);

    canvas.restore();
  }

  void _drawGlow(
    Canvas canvas,
    Offset center,
    double radius, {
    required double scale,
    required double opacity,
  }) {
    final Paint glowPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = NegoTokens.glowColor.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 40 * scale);

    canvas.drawCircle(center, radius, glowPaint);
  }

  void _drawPulse(
    Canvas canvas,
    Offset center,
    double faceRadius,
    double scale,
  ) {
    if (motion.happyPulseOpacity <= 0) {
      return;
    }

    final Paint pulsePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale
      ..color = NegoTokens.glowColor.withValues(alpha: motion.happyPulseOpacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);

    canvas.drawCircle(center, faceRadius * motion.happyPulseScale, pulsePaint);
  }

  void _drawEyes(Canvas canvas, Offset center, double scale) {
    final double eyeWidth = geometry.eyeWidth * scale;
    final double eyeHeight = geometry.eyeHeight * scale;
    final double eyeRadius = geometry.eyeRadius;
    final double gap = NegoTokens.eyeBaseGap * scale;
    final double eyeGroupYOffset = geometry.eyeGroupYOffset * scale;
    final double groupCenterX = center.dx + (motion.eyeOffsetX * scale);
    final double groupCenterY =
        center.dy + eyeGroupYOffset + (motion.eyeOffsetY * scale);
    final Offset groupCenter = Offset(groupCenterX, groupCenterY);
    final bool drawWinking = mood == NegoMood.winking;
    final bool drawExcited = mood == NegoMood.excited;
    final double eyeRotation = motion.lookRotationDegrees * math.pi / 180;

    canvas.save();
    canvas.translate(groupCenter.dx, groupCenter.dy);
    canvas.rotate(eyeRotation);
    canvas.translate(-groupCenter.dx, -groupCenter.dy);

    _drawEye(
      canvas: canvas,
      center: groupCenter,
      left: true,
      width: eyeWidth,
      height: eyeHeight,
      radius: eyeRadius,
      gap: gap,
      blinkScaleY: motion.blinkScaleY,
      eyePaint: Paint()..color = NegoTokens.eyeFill,
      cutoutPath: drawExcited
          ? NegoPaths.excitedCutoutActive()
          : NegoPaths.excitedCutoutInactive(),
      cutoutColor: NegoTokens.faceFill,
      applyExcitedCutout: drawExcited,
      applyWinkingCutout: false,
    );

    _drawEye(
      canvas: canvas,
      center: groupCenter,
      left: false,
      width: eyeWidth,
      height: eyeHeight,
      radius: eyeRadius,
      gap: gap,
      blinkScaleY: motion.blinkScaleY,
      eyePaint: Paint()..color = NegoTokens.eyeFill,
      cutoutPath: drawExcited
          ? NegoPaths.excitedCutoutActive()
          : NegoPaths.excitedCutoutInactive(),
      cutoutColor: NegoTokens.faceFill,
      applyExcitedCutout: drawExcited,
      applyWinkingCutout: drawWinking,
    );

    canvas.restore();
  }

  void _drawEye({
    required Canvas canvas,
    required Offset center,
    required bool left,
    required double width,
    required double height,
    required double radius,
    required double gap,
    required double blinkScaleY,
    required Paint eyePaint,
    required Path cutoutPath,
    required Color cutoutColor,
    required bool applyExcitedCutout,
    required bool applyWinkingCutout,
  }) {
    final double x = left ? center.dx - gap / 2 - width : center.dx + gap / 2;
    final double y = center.dy - height / 2;
    final Offset topLeft = Offset(x, y);

    canvas.save();
    canvas.translate(topLeft.dx, topLeft.dy);
    canvas.scale(
      width / NegoTokens.eyeViewBoxWidth,
      height / NegoTokens.eyeViewBoxHeight,
    );

    // Blink: scale around center of the eye, in viewBox coordinates.
    canvas.translate(
      NegoTokens.eyeViewBoxWidth / 2,
      NegoTokens.eyeViewBoxHeight / 2,
    );
    canvas.scale(1, blinkScaleY);
    canvas.translate(
      -NegoTokens.eyeViewBoxWidth / 2,
      -NegoTokens.eyeViewBoxHeight / 2,
    );

    final Path eyePath = NegoPaths.eyePath(
      width: NegoTokens.eyeViewBoxWidth,
      height: NegoTokens.eyeViewBoxHeight,
      radius: radius,
    );
    canvas.drawPath(eyePath, eyePaint);

    if (applyExcitedCutout) {
      _drawExcitedCutout(canvas: canvas, path: cutoutPath, color: cutoutColor);
    } else if (applyWinkingCutout) {
      _drawWinkingCutout(canvas: canvas, color: cutoutColor);
    }

    canvas.restore();
  }

  void _drawExcitedCutout({
    required Canvas canvas,
    required Path path,
    required Color color,
  }) {
    final Paint fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final Paint strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = color
      ..strokeWidth = NegoTokens.faceStrokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawWinkingCutout({required Canvas canvas, required Color color}) {
    canvas.drawPath(
      NegoPaths.winkingCutoutActive(),
      Paint()
        ..style = PaintingStyle.fill
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant NegoPainter oldDelegate) {
    return oldDelegate.size != size ||
        oldDelegate.mood != mood ||
        oldDelegate.geometry.eyeWidth != geometry.eyeWidth ||
        oldDelegate.geometry.eyeHeight != geometry.eyeHeight ||
        oldDelegate.geometry.eyeRadius != geometry.eyeRadius ||
        oldDelegate.geometry.eyeGroupYOffset != geometry.eyeGroupYOffset ||
        oldDelegate.geometry.bodyScale != geometry.bodyScale ||
        oldDelegate.geometry.glowScale != geometry.glowScale ||
        oldDelegate.geometry.glowOpacity != geometry.glowOpacity ||
        oldDelegate.geometry.floatAmplitude != geometry.floatAmplitude ||
        oldDelegate.motion.bodyTranslationY != motion.bodyTranslationY ||
        oldDelegate.motion.bodyRotationDegrees != motion.bodyRotationDegrees ||
        oldDelegate.motion.lookRotationDegrees != motion.lookRotationDegrees ||
        oldDelegate.motion.eyeOffsetX != motion.eyeOffsetX ||
        oldDelegate.motion.eyeOffsetY != motion.eyeOffsetY ||
        oldDelegate.motion.blinkScaleY != motion.blinkScaleY ||
        oldDelegate.motion.happyPulseScale != motion.happyPulseScale ||
        oldDelegate.motion.happyPulseOpacity != motion.happyPulseOpacity ||
        oldDelegate.motion.happyBodyScale != motion.happyBodyScale;
  }
}
