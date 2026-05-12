import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:ournego/core/routing/route_observer.dart';

class AnimatedParticles extends StatefulWidget {
  const AnimatedParticles({
    super.key,
    this.particleCount = 60,
    this.colors = const [Color(0xFF009ABE), Color(0xFF3EBF89)],
    this.layerBlur = 0.65,
  });

  final int particleCount;
  final List<Color> colors;
  final double layerBlur;

  @override
  State<AnimatedParticles> createState() => _AnimatedParticlesState();
}

class _AnimatedParticlesState extends State<AnimatedParticles>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  late final AnimationController _controller;
  final Random _random = Random();
  final List<_Particle> _particles = [];

  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      AppRouteObserver.instance.subscribe(this, modalRoute);
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.particleCount != widget.particleCount ||
        oldWidget.colors != widget.colors) {
      _resetParticles();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopAnimation();
    } else if (state == AppLifecycleState.resumed) {
      _startAnimation();
    }
  }

  @override
  void didPushNext() {
    _stopAnimation();
  }

  @override
  void didPopNext() {
    _startAnimation();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppRouteObserver.instance.unsubscribe(this);
    _controller.dispose();
    super.dispose();
  }

  void _startAnimation() {
    if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  void _stopAnimation() {
    if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  void _resetParticles() {
    _particles
      ..clear()
      ..addAll(
        List<_Particle>.generate(
          widget.particleCount,
          (index) => _createParticle(index, _canvasSize),
        ),
      );
  }

  _Particle _createParticle(int index, Size size) {
    final depth = _random.nextDouble();
    final radius = switch (depth) {
      < 0.32 => _randomRange(6, 9),
      < 0.75 => _randomRange(8, 13),
      _ => _randomRange(12, 18),
    };
    final velocityDepthFactor = 0.45 + depth;
    final colors = widget.colors.isEmpty
        ? const [Color(0xFF009ABE), Color(0xFF3EBF89)]
        : widget.colors;

    return _Particle(
      x: _randomRange(0, size.width),
      y: _randomRange(0, size.height),
      vx: _randomRange(-0.045, 0.045) * velocityDepthFactor,
      vy: _randomRange(-0.06, 0.06) * velocityDepthFactor,
      radius: radius,
      color: colors[index % colors.length],
      alpha: _randomRange(0.22, 0.52),
      pulsePhase: _randomRange(0, pi * 2),
      pulseSpeed: _randomRange(0.0025, 0.008),
      driftFactor: _randomRange(0.0007, 0.0022),
      depth: depth,
    );
  }

  double _randomRange(double min, double max) {
    return min + (_random.nextDouble() * (max - min));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fallbackSize = MediaQuery.sizeOf(context);
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : fallbackSize.width;
        final height = constraints.hasBoundedHeight
            ? constraints.maxHeight
            : fallbackSize.height;
        final newSize = Size(width, height);

        if (_canvasSize != newSize) {
          _canvasSize = newSize;
          _resetParticles();
        }

        return SizedBox(
          width: width,
          height: height,
          child: RepaintBoundary(
            child: CustomPaint(
              painter: _AnimatedParticlesPainter(
                animation: _controller,
                particles: _particles,
                layerBlur: widget.layerBlur,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Particle {
  _Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.color,
    required this.alpha,
    required this.pulsePhase,
    required this.pulseSpeed,
    required this.driftFactor,
    required this.depth,
  });

  double x;
  double y;
  final double vx;
  final double vy;
  final double radius;
  final Color color;
  final double alpha;
  double pulsePhase;
  final double pulseSpeed;
  final double driftFactor;
  final double depth;
}

class _AnimatedParticlesPainter extends CustomPainter {
  _AnimatedParticlesPainter({
    required Listenable animation,
    required this.particles,
    required this.layerBlur,
  }) : super(repaint: animation);

  final List<_Particle> particles;
  final double layerBlur;

  static const double _pulseAmplitude = 0.22;
  static const double _pulseOffset = 0.78;
  static const double _visualRadiusMultiplier = 1.15;
  static const double _driftAmplitude = 0.018;
  static const double _wrapMargin = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    final time = DateTime.now().millisecondsSinceEpoch.toDouble();

    if (layerBlur > 0) {
      canvas.saveLayer(
        bounds,
        Paint()
          ..imageFilter = ui.ImageFilter.blur(
            sigmaX: layerBlur,
            sigmaY: layerBlur,
          ),
      );
    }

    for (final particle in particles) {
      _updateParticle(particle, size, time);
    }

    for (final particle in particles) {
      _drawParticle(canvas, particle);
    }

    if (layerBlur > 0) {
      canvas.restore();
    }
  }

  void _updateParticle(_Particle particle, Size size, double time) {
    particle.pulsePhase += particle.pulseSpeed;
    final driftPhase = time * particle.driftFactor + particle.depth * 10;

    particle.x += particle.vx + sin(driftPhase) * _driftAmplitude;
    particle.y += particle.vy + cos(driftPhase) * _driftAmplitude;

    if (particle.x < -_wrapMargin) {
      particle.x = size.width + _wrapMargin;
    }
    if (particle.x > size.width + _wrapMargin) {
      particle.x = -_wrapMargin;
    }
    if (particle.y < -_wrapMargin) {
      particle.y = size.height + _wrapMargin;
    }
    if (particle.y > size.height + _wrapMargin) {
      particle.y = -_wrapMargin;
    }
  }

  void _drawParticle(Canvas canvas, _Particle particle) {
    final pulse = sin(particle.pulsePhase) * _pulseAmplitude + _pulseOffset;
    final currentRadius = particle.radius * pulse;
    final visualRadius = currentRadius * _visualRadiusMultiplier;
    final center = Offset(particle.x, particle.y);

    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          particle.color.withValues(alpha: particle.alpha * pulse),
          particle.color.withValues(alpha: particle.alpha * 0.55 * pulse),
          particle.color.withValues(alpha: particle.alpha * 0.16 * pulse),
          particle.color.withValues(alpha: 0),
        ],
        stops: const [0, 0.36, 0.72, 1],
      ).createShader(Rect.fromCircle(center: center, radius: visualRadius));

    canvas.drawCircle(center, visualRadius, paint);
  }

  @override
  bool shouldRepaint(covariant _AnimatedParticlesPainter oldDelegate) {
    return oldDelegate.particles != particles ||
        oldDelegate.layerBlur != layerBlur;
  }
}
