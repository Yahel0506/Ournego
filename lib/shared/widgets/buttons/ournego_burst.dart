import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';

/// Burst of dots from the center of [child] (spec §6.4). Drawn in the
/// [Overlay] so no ancestor clip can cut it. Plays once each time [trigger]
/// changes to a non-null value. Nothing is drawn with reduced motion.
class OurnegoBurst extends StatefulWidget {
  const OurnegoBurst({
    super.key,
    required this.child,
    required this.trigger,
    this.count = 14,
  });

  final Widget child;
  final Object? trigger;
  final int count;

  @override
  State<OurnegoBurst> createState() => _OurnegoBurstState();
}

class _OurnegoBurstState extends State<OurnegoBurst>
    with SingleTickerProviderStateMixin {
  static const double _dotSize = 8;
  static const double _maxDistance = 60;
  static const double _canvas = (_maxDistance + _dotSize) * 2;

  final LayerLink _link = LayerLink();
  final OverlayPortalController _portal = OverlayPortalController();
  final math.Random _random = math.Random();
  late final AnimationController _controller;
  List<_Dot> _dots = const [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: kBurstDuration)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _portal.isShowing) {
          _portal.hide();
        }
      });
  }

  @override
  void didUpdateWidget(covariant OurnegoBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger != null && widget.trigger != oldWidget.trigger) {
      _play();
    }
  }

  void _play() {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return;
    _dots = List<_Dot>.generate(widget.count, (i) {
      final degrees = i / widget.count * 360 + _random.nextDouble() * 20;
      return _Dot(
        angle: degrees * math.pi / 180,
        distance: 34 + _random.nextDouble() * 26,
        color: OurnegoButtonPalette
            .burstColors[i % OurnegoButtonPalette.burstColors.length],
      );
    });
    // show() must not run during build; didUpdateWidget runs in build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_portal.isShowing) _portal.show();
      _controller.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _portal,
      overlayChildBuilder: (context) {
        return Align(
          alignment: Alignment.topLeft,
          child: CompositedTransformFollower(
            link: _link,
            showWhenUnlinked: false,
            targetAnchor: Alignment.center,
            followerAnchor: Alignment.center,
            child: IgnorePointer(
              child: SizedBox.square(
                dimension: _canvas,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => CustomPaint(
                    painter: _BurstPainter(
                      dots: _dots,
                      progress: _controller.value,
                      dotSize: _dotSize,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: CompositedTransformTarget(link: _link, child: widget.child),
    );
  }
}

class _Dot {
  const _Dot({
    required this.angle,
    required this.distance,
    required this.color,
  });

  final double angle;
  final double distance;
  final Color color;
}

class _BurstPainter extends CustomPainter {
  _BurstPainter({
    required this.dots,
    required this.progress,
    required this.dotSize,
  });

  final List<_Dot> dots;
  final double progress;
  final double dotSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final t = kEaseOutExpo.transform(progress);
    final scale = 1 - 0.7 * t;
    final opacity = 1 - t;
    for (final dot in dots) {
      final offset =
          center +
          Offset(math.cos(dot.angle), math.sin(dot.angle)) * (dot.distance * t);
      canvas.drawCircle(
        offset,
        dotSize / 2 * scale,
        Paint()..color = dot.color.withValues(alpha: opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.dots != dots;
}
