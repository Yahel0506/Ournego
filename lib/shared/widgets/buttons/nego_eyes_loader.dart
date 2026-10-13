import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_motion.dart';

/// Loader shaped like Nego's eyes (spec §6.3): two capsules that hop and
/// squash, the second one 120 ms behind. With reduced motion both eyes only
/// pulse their opacity 1 → 0.35 → 1 in 1200 ms.
class NegoEyesLoader extends StatefulWidget {
  const NegoEyesLoader({
    super.key,
    required this.color,
    this.eyeWidth = 7,
    this.eyeHeight = 17,
    this.gap = 5,
  });

  final Color color;
  final double eyeWidth;
  final double eyeHeight;
  final double gap;

  @override
  State<NegoEyesLoader> createState() => _NegoEyesLoaderState();
}

class _NegoEyesLoaderState extends State<NegoEyesLoader>
    with SingleTickerProviderStateMixin {
  static const Duration _pulsePeriod = Duration(milliseconds: 1200);
  static const Duration _secondEyeDelay = Duration(milliseconds: 120);

  late final AnimationController _controller;
  bool? _reduced;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced == _reduced) return;
    _reduced = reduced;
    _controller
      ..duration = reduced ? _pulsePeriod : kEyesLoaderPeriod
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Keyframes per eye: (t, dy, scaleY), eased with easeInOut per segment.
  static const List<(double, double, double)> _frames = [
    (0, 0, 1),
    (0.30, -4, 1.08),
    (0.55, 1, 0.5),
    (1, 0, 1),
  ];

  static (double, double) _hop(double t) {
    for (var i = 0; i < _frames.length - 1; i++) {
      final a = _frames[i];
      final b = _frames[i + 1];
      if (t <= b.$1) {
        final u = Curves.easeInOut.transform((t - a.$1) / (b.$1 - a.$1));
        return (lerpDouble(a.$2, b.$2, u)!, lerpDouble(a.$3, b.$3, u)!);
      }
    }
    return (0, 1);
  }

  Widget _eye() {
    return Container(
      width: widget.eyeWidth,
      height: widget.eyeHeight,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = _reduced ?? false;
    final eye = _eye();
    return Semantics(
      label: 'Cargando',
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final t = _controller.value;
          if (reduced) {
            // 1 -> 0.35 -> 1: |2t - 1| goes 1 -> 0 -> 1.
            final wave = Curves.easeInOut.transform((2 * t - 1).abs());
            final opacity = lerpDouble(0.35, 1, wave)!;
            return Opacity(
              opacity: opacity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  eye,
                  SizedBox(width: widget.gap),
                  eye,
                ],
              ),
            );
          }
          final delay =
              _secondEyeDelay.inMicroseconds / kEyesLoaderPeriod.inMicroseconds;
          Widget hopping(double phase) {
            final (dy, scaleY) = _hop(phase % 1);
            return Transform.translate(
              offset: Offset(0, dy),
              child: Transform.scale(scaleX: 1, scaleY: scaleY, child: eye),
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              hopping(t),
              SizedBox(width: widget.gap),
              hopping(t - delay + 1),
            ],
          );
        },
      ),
    );
  }
}
