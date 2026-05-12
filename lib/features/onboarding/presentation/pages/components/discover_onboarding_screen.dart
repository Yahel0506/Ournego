import 'dart:math';
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';

class DiscoverOnboardingScreen extends StatelessWidget {
  const DiscoverOnboardingScreen({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Stack(
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [SizedBox(height: 64), _FloatingOrb()],
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Encuentra lo que necesitas, cerca de ti.',
                textAlign: TextAlign.left,
                style: OurnegoTextStyles.onboardingHeader,
              ),
              const SizedBox(height: 12),
              Text(
                'Desde comida hasta servicios, todo en tu zona.',
                textAlign: TextAlign.left,
                style: OurnegoTextStyles.body,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 160,
                height: 56,
                child: OurnegoNeutralPrimaryButton(
                  key: const ValueKey('onboardingDiscoverContinueButton'),
                  onPressed: onNext,
                  child: const Text(
                    'Continuar',
                    style: OurnegoTextStyles.header,
                  ),
                ),
              ),
              const SizedBox(height: 136),
            ],
          ),
        ],
      ),
    );
  }
}

class _FloatingOrb extends StatefulWidget {
  const _FloatingOrb();

  @override
  State<_FloatingOrb> createState() => _FloatingOrbState();
}

class _FloatingOrbState extends State<_FloatingOrb>
    with SingleTickerProviderStateMixin {
  static const double _orbSize = 170;
  static const double _bubbleBaseFactor = 0.2;
  static const double _iconFactor = 0.46;

  static const List<IconData> _bubbleIcons = [
    Icons.restaurant_rounded,
    Icons.local_grocery_store_rounded,
    Icons.local_hospital_rounded,
    Icons.directions_car_rounded,
    Icons.cut_rounded,
    Icons.coffee_rounded,
    Icons.storefront_rounded,
  ];

  static const List<_BubbleOrbitConfig> _configs = [
    _BubbleOrbitConfig(
      baseAngleDeg: 285,
      orbitRadiusFactor: 1.35,
      sizeFactor: 0.92,
      orbitSpeedFactor: 0.10,
      floatAmplitudeX: 0.030,
      floatAmplitudeY: 0.050,
      floatSpeed: 1.00,
      phase: 0.0,
    ),
    _BubbleOrbitConfig(
      baseAngleDeg: 330,
      orbitRadiusFactor: 1.55,
      sizeFactor: 1.05,
      orbitSpeedFactor: -0.07,
      floatAmplitudeX: 0.045,
      floatAmplitudeY: 0.030,
      floatSpeed: 0.82,
      phase: 1.2,
    ),
    _BubbleOrbitConfig(
      baseAngleDeg: 25,
      orbitRadiusFactor: 1.42,
      sizeFactor: 0.98,
      orbitSpeedFactor: 0.13,
      floatAmplitudeX: 0.035,
      floatAmplitudeY: 0.060,
      floatSpeed: 0.74,
      phase: 2.1,
    ),
    _BubbleOrbitConfig(
      baseAngleDeg: 75,
      orbitRadiusFactor: 1.62,
      sizeFactor: 1.12,
      orbitSpeedFactor: -0.09,
      floatAmplitudeX: 0.050,
      floatAmplitudeY: 0.040,
      floatSpeed: 0.93,
      phase: 3.4,
    ),
    _BubbleOrbitConfig(
      baseAngleDeg: 135,
      orbitRadiusFactor: 1.48,
      sizeFactor: 0.95,
      orbitSpeedFactor: 0.08,
      floatAmplitudeX: 0.030,
      floatAmplitudeY: 0.055,
      floatSpeed: 0.69,
      phase: 4.2,
    ),
    _BubbleOrbitConfig(
      baseAngleDeg: 205,
      orbitRadiusFactor: 1.58,
      sizeFactor: 1.08,
      orbitSpeedFactor: -0.12,
      floatAmplitudeX: 0.055,
      floatAmplitudeY: 0.035,
      floatSpeed: 0.88,
      phase: 5.0,
    ),
    _BubbleOrbitConfig(
      baseAngleDeg: 250,
      orbitRadiusFactor: 1.38,
      sizeFactor: 0.90,
      orbitSpeedFactor: 0.11,
      floatAmplitudeX: 0.040,
      floatAmplitudeY: 0.050,
      floatSpeed: 0.77,
      phase: 5.8,
    ),
  ];

  late final AnimationController _motionController;

  @override
  void initState() {
    super.initState();
    _motionController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 28),
    )..repeat();
  }

  @override
  void dispose() {
    _motionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 256,
      width: double.infinity,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          final center = Offset(size.width / 2, size.height / 2);
          return AnimatedBuilder(
            animation: _motionController,
            builder: (context, child) {
              final t = _motionController.value;
              final radians = t * 2 * pi;
              final breath = 0.5 - (0.5 * cos(radians * 1.2));
              final nearGlowBreath = 0.5 - (0.5 * cos(radians * 1.35 + 0.9));
              final farGlowBreath = 0.5 - (0.5 * cos(radians * 0.95 + 2.4));
              final ringBreath = 0.5 - (0.5 * cos(radians * 1.5 + 1.2));

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: size,
                      painter: _FloatingOrbPainter(
                        breath: breath,
                        nearGlowBreath: nearGlowBreath,
                        farGlowBreath: farGlowBreath,
                        ringBreath: ringBreath,
                        rotation: t,
                        orbSize: _orbSize,
                      ),
                    ),
                  ),
                  ...List<Widget>.generate(_configs.length, (index) {
                    final config = _configs[index];
                    final bubbleSize =
                        _orbSize * _bubbleBaseFactor * config.sizeFactor;
                    final bubbleCenter = _bubbleCenter(
                      config: config,
                      t: t,
                      center: center,
                      orbSize: _orbSize,
                    );
                    final bubblePulse =
                        1 +
                        (sin(radians * config.floatSpeed + config.phase) *
                            0.025);
                    return Positioned(
                      left: bubbleCenter.dx - (bubbleSize / 2),
                      top: bubbleCenter.dy - (bubbleSize / 2),
                      width: bubbleSize,
                      height: bubbleSize,
                      child: Transform.scale(
                        scale: bubblePulse.clamp(0.975, 1.035),
                        child: _FloatingEnergyBubble(
                          icon: _bubbleIcons[index],
                          size: bubbleSize,
                          iconFactor: _iconFactor,
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Offset _bubbleCenter({
    required _BubbleOrbitConfig config,
    required double t,
    required Offset center,
    required double orbSize,
  }) {
    final orbRadius = orbSize / 2;
    final baseAngle = _radians(config.baseAngleDeg);
    final orbitAngle = baseAngle + ((t * 2 * pi) * config.orbitSpeedFactor);
    final orbitRadius = orbRadius * config.orbitRadiusFactor;

    final orbitalOffset = Offset(
      cos(orbitAngle) * orbitRadius,
      sin(orbitAngle) * orbitRadius,
    );

    final floatTime = t * 2 * pi * config.floatSpeed;
    final floatOffset = Offset(
      sin(floatTime + config.phase) * orbRadius * config.floatAmplitudeX,
      cos((floatTime * 0.85) + config.phase) *
          orbRadius *
          config.floatAmplitudeY,
    );

    return center + orbitalOffset + floatOffset;
  }

  double _radians(double degrees) => degrees * (pi / 180);
}

class _BubbleOrbitConfig {
  const _BubbleOrbitConfig({
    required this.baseAngleDeg,
    required this.orbitRadiusFactor,
    required this.sizeFactor,
    required this.orbitSpeedFactor,
    required this.floatAmplitudeX,
    required this.floatAmplitudeY,
    required this.floatSpeed,
    required this.phase,
  });

  final double baseAngleDeg;
  final double orbitRadiusFactor;
  final double sizeFactor;
  final double orbitSpeedFactor;
  final double floatAmplitudeX;
  final double floatAmplitudeY;
  final double floatSpeed;
  final double phase;
}

class _FloatingOrbPainter extends CustomPainter {
  const _FloatingOrbPainter({
    required this.breath,
    required this.nearGlowBreath,
    required this.farGlowBreath,
    required this.ringBreath,
    required this.rotation,
    required this.orbSize,
  });

  final double breath;
  final double nearGlowBreath;
  final double farGlowBreath;
  final double ringBreath;
  final double rotation;
  final double orbSize;

  static const Color _orbBase = Color(0xFF009ABE);
  static const Color _orbSoft = Color(0xFF66EAFF);
  static const Color _orbDeep = Color(0xFF006F8F);
  static const Color _orbDarkEdge = Color.fromARGB(255, 0, 106, 145);
  static const Color _orbShadow = Color.fromARGB(255, 0, 104, 149);

  @override
  void paint(Canvas canvas, Size size) {
    final side = orbSize;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = side / 2;
    final orbRect = Rect.fromCircle(center: center, radius: radius);
    final orbClip = Path()..addOval(orbRect);

    final farGlowOpacity = lerpDouble(0.20, 0.34, farGlowBreath) ?? 0.28;
    final nearGlowOpacity = lerpDouble(0.35, 0.62, nearGlowBreath) ?? 0.48;
    final orbScale = lerpDouble(1.0, 1.025, breath) ?? 1.0;
    final ringScale = lerpDouble(1.00, 1.04, ringBreath) ?? 1.0;
    final ringOpacity = lerpDouble(0.52, 0.92, ringBreath) ?? 0.65;

    _paintFarGlow(canvas, center, radius, farGlowOpacity, side);
    _paintNearGlow(canvas, center, radius, nearGlowOpacity, side);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(orbScale);
    canvas.translate(-center.dx, -center.dy);

    _paintMainOrb(canvas, center, radius, orbRect);

    canvas.save();
    canvas.clipPath(orbClip);
    _paintBottomShadow(canvas, center, radius, orbRect);
    _paintInnerGlow(canvas, center, radius, side);
    _paintInternalCurrents(canvas, center, radius, side, rotation, orbRect);
    _paintCore(canvas, center, radius);
    _paintHighlight(canvas, center, radius);
    _paintRim(canvas, center, radius, orbRect);
    canvas.restore();
    canvas.restore();

    _paintRing(canvas, center, radius, ringScale, ringOpacity, side);
  }

  void _paintFarGlow(
    Canvas canvas,
    Offset center,
    double radius,
    double opacity,
    double side,
  ) {
    final paint = Paint()
      ..color = _orbBase.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.315);
    canvas.drawCircle(center, radius * 1.85, paint);
  }

  void _paintNearGlow(
    Canvas canvas,
    Offset center,
    double radius,
    double opacity,
    double side,
  ) {
    final paint = Paint()
      ..color = _orbBase.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.177);
    canvas.drawCircle(center, radius * 1.35, paint);
  }

  void _paintMainOrb(
    Canvas canvas,
    Offset center,
    double radius,
    Rect orbRect,
  ) {
    final radialGradient = RadialGradient(
      center: const Alignment(0, -0.10),
      radius: 0.72,
      colors: [
        const Color(0xFFE6FFFF).withValues(alpha: 0.98),
        const Color(0xFF82F4FF).withValues(alpha: 0.92),
        _orbBase.withValues(alpha: 0.98),
        _orbDeep,
        _orbDarkEdge,
      ],
      stops: const [0.0, 0.16, 0.48, 0.78, 1.0],
    );

    final paint = Paint()..shader = radialGradient.createShader(orbRect);
    canvas.drawCircle(center, radius, paint);
  }

  void _paintBottomShadow(
    Canvas canvas,
    Offset center,
    double radius,
    Rect orbRect,
  ) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0, 1.05),
        radius: 0.85,
        colors: [
          _orbShadow.withValues(alpha: 0.52),
          _orbShadow.withValues(alpha: 0.24),
          Colors.transparent,
        ],
        stops: const [0.0, 0.48, 1.0],
      ).createShader(orbRect);
    canvas.drawCircle(center, radius, paint);
  }

  void _paintInnerGlow(
    Canvas canvas,
    Offset center,
    double radius,
    double side,
  ) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.075
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.045);
    canvas.drawCircle(center, radius * 0.86, paint);
  }

  void _paintInternalCurrents(
    Canvas canvas,
    Offset center,
    double radius,
    double side,
    double rotation,
    Rect orbRect,
  ) {
    final rotationAngle = rotation * 2 * pi;
    canvas.saveLayer(orbRect, Paint());
    canvas.clipPath(Path()..addOval(orbRect));
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotationAngle);
    canvas.translate(-center.dx, -center.dy);

    final paint = Paint()
      ..blendMode = BlendMode.screen
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.027)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.085
      ..strokeCap = StrokeCap.round;

    final currentRect = Rect.fromCircle(center: center, radius: radius * 0.82);
    paint.color = Colors.white.withValues(alpha: 0.14);
    canvas.drawArc(currentRect, _radians(40), _radians(42), false, paint);

    paint.color = _orbSoft.withValues(alpha: 0.18);
    canvas.drawArc(
      currentRect.inflate(side * 0.035),
      _radians(158),
      _radians(72),
      false,
      paint,
    );

    paint.color = Colors.white.withValues(alpha: 0.10);
    canvas.drawArc(
      currentRect.deflate(side * 0.025),
      _radians(306),
      _radians(54),
      false,
      paint,
    );

    canvas.restore();
  }

  void _paintCore(Canvas canvas, Offset center, double radius) {
    final coreCenter = center + Offset(0, -radius * 0.12);
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withValues(alpha: 0.58),
          Colors.white.withValues(alpha: 0.18),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: coreCenter, radius: radius * 0.34))
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(coreCenter, radius * 0.34, paint);
  }

  void _paintHighlight(Canvas canvas, Offset center, double radius) {
    final highlightCenter = center + Offset(-radius * 0.30, -radius * 0.50);
    final paint = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.62),
              Colors.white.withValues(alpha: 0.18),
              Colors.transparent,
            ],
            stops: const [0.0, 0.42, 1.0],
          ).createShader(
            Rect.fromCircle(center: highlightCenter, radius: radius * 0.42),
          )
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(highlightCenter, radius * 0.42, paint);
  }

  void _paintRim(Canvas canvas, Offset center, double radius, Rect orbRect) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.transparent,
          Colors.transparent,
          _orbSoft.withValues(alpha: 0.32),
          Colors.white.withValues(alpha: 0.35),
        ],
        stops: const [0.0, 0.56, 0.72, 1.0],
      ).createShader(orbRect)
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(center, radius, paint);
  }

  void _paintRing(
    Canvas canvas,
    Offset center,
    double radius,
    double ringScale,
    double ringOpacity,
    double side,
  ) {
    final glowPaint = Paint()
      ..color = _orbBase.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeWidth = side * 0.030
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, side * 0.035);
    canvas.drawCircle(center, radius * 1.08, glowPaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(ringScale);
    canvas.translate(-center.dx, -center.dy);

    final ringPaint = Paint()
      ..color = const Color(0xFF8CF6FF).withValues(alpha: ringOpacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = max(1.0, side * 0.004);
    canvas.drawCircle(center, radius * 1.08, ringPaint);

    canvas.restore();
  }

  double _radians(double degrees) => degrees * (pi / 180);

  @override
  bool shouldRepaint(covariant _FloatingOrbPainter oldDelegate) {
    return oldDelegate.breath != breath ||
        oldDelegate.nearGlowBreath != nearGlowBreath ||
        oldDelegate.farGlowBreath != farGlowBreath ||
        oldDelegate.ringBreath != ringBreath ||
        oldDelegate.rotation != rotation ||
        oldDelegate.orbSize != orbSize;
  }
}

class _FloatingEnergyBubble extends StatelessWidget {
  const _FloatingEnergyBubble({
    required this.icon,
    required this.size,
    required this.iconFactor,
  });

  final IconData icon;
  final double size;
  final double iconFactor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size.square(size),
          painter: _EnergyBubblePainter(size: size),
        ),
        Icon(
          icon,
          size: size * iconFactor,
          color: const Color(0xFFE6FFFF).withValues(alpha: 0.9),
        ),
      ],
    );
  }
}

class _EnergyBubblePainter extends CustomPainter {
  const _EnergyBubblePainter({required this.size});

  final double size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final center = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final radius = size / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final glowPaint = Paint()
      ..color = const Color(0xFF009ABE).withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.20);
    canvas.drawCircle(center, radius * 0.92, glowPaint);

    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.25, -0.35),
        radius: 0.9,
        colors: [
          Colors.white.withValues(alpha: 0.32),
          const Color(0xFF66EAFF).withValues(alpha: 0.22),
          const Color(0xFF009ABE).withValues(alpha: 0.18),
          const Color(0xFF006F8F).withValues(alpha: 0.28),
        ],
        stops: const [0.0, 0.32, 0.68, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius * 0.90, bodyPaint);

    final innerHighlightCenter =
        center + Offset(-radius * 0.30, -radius * 0.36);
    final innerHighlight = Paint()
      ..shader =
          RadialGradient(
            colors: [
              Colors.white.withValues(alpha: 0.34),
              Colors.white.withValues(alpha: 0.08),
              Colors.transparent,
            ],
            stops: const [0.0, 0.36, 1.0],
          ).createShader(
            Rect.fromCircle(
              center: innerHighlightCenter,
              radius: radius * 0.62,
            ),
          )
      ..blendMode = BlendMode.screen;
    canvas.drawCircle(innerHighlightCenter, radius * 0.62, innerHighlight);

    final innerShadow = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.15, 1.0),
        radius: 1.0,
        colors: [Colors.black.withValues(alpha: 0.10), Colors.transparent],
        stops: const [0.0, 1.0],
      ).createShader(rect);
    canvas.drawCircle(center, radius * 0.88, innerShadow);

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.025
      ..color = const Color(0xFF8CF6FF).withValues(alpha: 0.40);
    canvas.drawCircle(center, radius * 0.90, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _EnergyBubblePainter oldDelegate) {
    return oldDelegate.size != size;
  }
}
