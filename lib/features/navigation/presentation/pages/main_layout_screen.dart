import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_flow.dart';
import 'package:ournego/features/navigation/presentation/widgets/navigation_bar_widget.dart';
import 'package:shake/shake.dart';

class MainLayoutScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const MainLayoutScreen({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: TweenAnimationBuilder<double>(
        key: ValueKey<int>(currentIndex),
        tween: Tween<double>(begin: 0, end: 1),
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        child: navigationShell,
        builder: (context, value, child) {
          final opacity = 0.75 + (0.25 * value);
          final dx = (1 - value) * 8;

          return Opacity(
            opacity: opacity,
            child: Transform.translate(offset: Offset(dx, 0), child: child),
          );
        },
      ),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == currentIndex,
          );
        },
      ),
    );
  }
}

class FeedbackShakeListener extends ConsumerStatefulWidget {
  final Widget child;

  const FeedbackShakeListener({super.key, required this.child});

  @override
  ConsumerState<FeedbackShakeListener> createState() =>
      _FeedbackShakeListenerState();
}

class _FeedbackShakeListenerState extends ConsumerState<FeedbackShakeListener>
    with WidgetsBindingObserver {
  ShakeDetector? _detector;
  AppLifecycleState? _appLifecycleState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _detector = ShakeDetector.autoStart(
      onPhoneShake: (shakeEvent) {
        if (_appLifecycleState != AppLifecycleState.resumed) {
          return;
        }

        unawaited(openFeedbackDialog(context, ref));
      },
      shakeThresholdGravity: 2.7,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _appLifecycleState = state;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _detector?.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
