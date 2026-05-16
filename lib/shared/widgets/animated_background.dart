import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/routing/route_observer.dart';

class AnimatedBackgroundBlob {
  const AnimatedBackgroundBlob({
    required this.color,
    required this.width,
    required this.height,
    this.opacity = 0.4,
  });

  final Color color;
  final double width;
  final double height;
  final double opacity;
}

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({
    super.key,
    this.blobs,
    this.animationDuration = kBackgroundDriftDuration,
    this.blurSigma = 80,
  });

  final List<AnimatedBackgroundBlob>? blobs;
  final Duration animationDuration;
  final double blurSigma;

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with WidgetsBindingObserver, RouteAware {
  Timer? timerAnimation;
  final Random _random = Random();
  Size _canvasSize = Size.zero;
  List<Offset> _positions = [];
  bool _reducedMotion = false;

  List<AnimatedBackgroundBlob> get _blobs =>
      widget.blobs ??
      const [
        AnimatedBackgroundBlob(
          color: OurnegoColors.aguamarina,
          width: 300,
          height: 300,
          opacity: 0.4,
        ),
        AnimatedBackgroundBlob(
          color: OurnegoColors.azulCielo,
          width: 350,
          height: 350,
          opacity: 0.3,
        ),
        AnimatedBackgroundBlob(
          color: OurnegoColors.verdeCastleton,
          width: 250,
          height: 250,
          opacity: 0.1,
        ),
      ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updatePositions();
      _startTimer();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextReducedMotion = MediaQuery.disableAnimationsOf(context);
    if (_reducedMotion != nextReducedMotion) {
      _reducedMotion = nextReducedMotion;
      if (_reducedMotion) {
        _stopTimer();
      } else {
        _startTimer();
      }
    }
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      AppRouteObserver.instance.subscribe(this, modalRoute);
    }
  }

  void _startTimer() {
    if (_reducedMotion) return;
    if (timerAnimation != null && (timerAnimation?.isActive ?? false)) return;

    timerAnimation = Timer.periodic(widget.animationDuration, (timer) {
      _updatePositions();
    });
  }

  void _stopTimer() {
    timerAnimation?.cancel();
    timerAnimation = null;
    // TODO: Replace `print` with a logger and remove in production.
  }

  void _updatePositions() {
    if (!mounted) return;

    final Size fallbackSize = MediaQuery.of(context).size;
    final Size size = _canvasSize == Size.zero ? fallbackSize : _canvasSize;

    setState(() {
      _positions = _blobs
          .map((blob) {
            final double dx =
                (_random.nextDouble() * size.width) - (blob.width / 2);
            final double dy =
                (_random.nextDouble() * size.height) - (blob.height / 2);
            return Offset(dx, dy);
          })
          .toList(growable: false);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _stopTimer();
    } else if (state == AppLifecycleState.resumed) {
      _startTimer();
    }
  }

  @override
  void didPushNext() {
    _stopTimer();
  }

  @override
  void didPopNext() {
    _startTimer();
    _updatePositions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    AppRouteObserver.instance.unsubscribe(this);
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final Size newSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_canvasSize != newSize) {
          _canvasSize = newSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _updatePositions();
            }
          });
        }

        final List<Widget> layers = [];
        for (int index = 0; index < _blobs.length; index++) {
          final blob = _blobs[index];
          final position = _positions.length > index
              ? _positions[index]
              : Offset.zero;
          final blobLayer = Container(
            width: blob.width,
            height: blob.height,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: blob.color.withValues(alpha: blob.opacity),
            ),
          );
          layers.add(
            _reducedMotion
                ? Positioned(
                    top: position.dy,
                    left: position.dx,
                    child: blobLayer,
                  )
                : AnimatedPositioned(
                    duration: widget.animationDuration,
                    curve: Curves.easeInOut,
                    top: position.dy,
                    left: position.dx,
                    child: blobLayer,
                  ),
          );
        }

        layers.add(
          BackdropFilter(
            filter: ui.ImageFilter.blur(
              sigmaX: _reducedMotion ? 0 : widget.blurSigma,
              sigmaY: _reducedMotion ? 0 : widget.blurSigma,
            ),
            child: Container(
              color: Colors.transparent,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        );

        return Stack(children: layers);
      },
    );
  }
}
