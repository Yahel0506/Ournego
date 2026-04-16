import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/features/navigation/presentation/widgets/navigation_bar_widget.dart';
import 'package:shake/shake.dart';

class MainLayoutScreen extends ConsumerWidget {
  final Widget child;

  const MainLayoutScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final currentIndex = _indexFromLocation(location);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      extendBody: true,
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 320),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (widget, animation) {
          final slideAnimation = Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(animation);

          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slideAnimation, child: widget),
          );
        },
        child: KeyedSubtree(key: ValueKey(location), child: child),
      ),
      bottomNavigationBar: AppNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) {
            return;
          }

          switch (index) {
            case 0:
              context.go(AppRoutes.community);
              return;
            case 1:
              context.go(MapRoutes.map);
              return;
            case 2:
              context.go(BusinessRoutes.panel);
              return;
          }
        },
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith(AppRoutes.community)) {
      return 0;
    }

    if (location.startsWith(BusinessRoutes.panel)) {
      return 2;
    }

    return 1;
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

        if (ref.read(isFeedbackDialogOpenProvider)) {
          return;
        }

        ref.read(isFeedbackDialogOpenProvider.notifier).setIsOpen();
        showDialog<void>(
          context: context,
          builder: (_) => const FeedbackDialogWidget(),
        ).then((_) {
          if (context.mounted) {
            ref.read(isFeedbackDialogOpenProvider.notifier).setIsClosed();
          }
        });
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
