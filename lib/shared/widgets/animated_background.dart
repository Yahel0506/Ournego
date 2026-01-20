import 'dart:async';
import 'dart:math';
import 'dart:ui' as imageUrl;

import 'package:flutter/material.dart';
import 'package:ournego/main.dart';
import 'package:ournego/core/ournego_colors.dart';

class AnimatedBackground extends StatefulWidget {
  const AnimatedBackground({super.key});

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with WidgetsBindingObserver, RouteAware {
  Timer? timerAnimation;

  // TODO: Reuse a single Random instance instead of creating many.
  // Perspective: Create `final _random = Random()` and use it in
  // `_updatePositions` for slightly better performance and testability.

  // Posiciones
  double top1 = 0;
  double left1 = 0;
  double top2 = 0;
  double left2 = 0;
  double top3 = 0;
  double left3 = 0;

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
    final modalRoute = ModalRoute.of(context);
    if (modalRoute is PageRoute) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  void _startTimer() {
    if (timerAnimation != null && (timerAnimation?.isActive ?? false)) return;

    timerAnimation = Timer.periodic(const Duration(seconds: 4), (timer) {
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

    setState(() {
      double w = MediaQuery.of(context).size.width;
      double h = MediaQuery.of(context).size.height;
      // TODO: Consider making these deltas configurable and testable.
      top1 = (Random().nextDouble() * h) - 150;
      left1 = (Random().nextDouble() * w) - 150;

      top2 = (Random().nextDouble() * h) - 175;
      left2 = (Random().nextDouble() * w) - 175;

      top3 = (Random().nextDouble() * h) - 125;
      left3 = (Random().nextDouble() * w) - 125;
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
    routeObserver.unsubscribe(this);
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          top: top1,
          left: left1,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OurnegoColors.aguamarina.withOpacity(0.4),
            ),
          ),
        ),
        // CAPA 2
        AnimatedPositioned(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          top: top2,
          left: left2,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OurnegoColors.azulCielo.withOpacity(0.3),
            ),
          ),
        ),
        // CAPA 3
        AnimatedPositioned(
          duration: const Duration(seconds: 4),
          curve: Curves.easeInOut,
          top: top3,
          left: left3,
          child: Container(
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: OurnegoColors.verdeCastleton.withOpacity(0.1),
            ),
          ),
        ),
        BackdropFilter(
          filter: imageUrl.ImageFilter.blur(sigmaX: 80, sigmaY: 80),
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
          ),
        ),
      ],
    );
  }
}
