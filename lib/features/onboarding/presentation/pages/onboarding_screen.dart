import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/explore_onboarding_screen.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/discover_onboarding_screen.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/location_onboarding_screen.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ournego/shared/widgets/animated_background.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';
import 'package:ournego/shared/widgets/ournego_information_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../auth/presentation/widgets/auth_selection_widget.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _controller;
  int _currentPage = 0;
  PermissionStatus _locationPermissionStatus = PermissionStatus.denied;
  bool _isShowingLocationDialog = false;

  static const Duration _pageAnimationDuration = Duration(milliseconds: 600);
  static const Curve _pageAnimationCurve = Curves.easeOutQuart;

  late final List<OnboardingNegoPose> _negoPoses;

  Future<void> _showLocationRequiredDialog(
    BuildContext context, {
    required bool isDeniedForever,
  }) async {
    if (_isShowingLocationDialog || !mounted) {
      return;
    }

    _isShowingLocationDialog = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return OurnegoInformationDialog(
          maxWidth: 420,
          title: isDeniedForever
              ? 'Permiso de ubicacion bloqueado'
              : 'Ubicacion requerida',
          description: isDeniedForever
              ? 'Activalo desde los ajustes del dispositivo para continuar.'
              : 'Debes habilitar la ubicacion para poder continuar.',
          imagePath: 'assets/images/location_error.png',
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Entendido'),
              ),
              if (isDeniedForever) ...[
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    await openAppSettings();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Abrir ajustes'),
                ),
              ],
            ],
          ),
        );
      },
    );
    _isShowingLocationDialog = false;
  }

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _negoPoses = const [
      OnboardingNegoPose(
        size: 120,
        alignment: Alignment.bottomCenter,
        offset: Offset(0, -100),
        mood: NegoMood.winking,
        lookAngle: NegoTokens.lookAngleDefault,
        lookVertical: NegoLookVertical.down,
        interactive: true,
      ),
      OnboardingNegoPose(
        size: 120,
        alignment: Alignment.bottomRight,
        offset: Offset(-20, -100),
        mood: NegoMood.looking,
        lookAngle: 18,
        lookVertical: NegoLookVertical.up,
        interactive: false,
      ),
      OnboardingNegoPose(
        size: 200,
        alignment: Alignment.topCenter,
        offset: Offset(0, 540),
        mood: NegoMood.excited,
        lookAngle: 0,
        lookVertical: NegoLookVertical.up,
        interactive: true,
      ),
      OnboardingNegoPose(
        size: 160,
        alignment: Alignment.topCenter,
        offset: Offset(0, 340),
        mood: NegoMood.happy,
        lookAngle: 0,
        lookVertical: NegoLookVertical.up,
        interactive: true,
      ),
      OnboardingNegoPose(
        size: 0,
        alignment: Alignment.topCenter,
        offset: Offset(0, 1000),
        mood: NegoMood.excited,
        lookAngle: 0,
        lookVertical: NegoLookVertical.down,
        interactive: false,
      ),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage(int totalPages) async {
    if (_currentPage >= totalPages - 1) return;

    await _controller.animateToPage(
      _currentPage + 1,
      duration: _pageAnimationDuration,
      curve: _pageAnimationCurve,
    );
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage <= 0) {
      return;
    }

    await _controller.animateToPage(
      _currentPage - 1,
      duration: _pageAnimationDuration,
      curve: _pageAnimationCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final enforceLocationPermission = ref.watch(
      onboardingEnforceLocationPermissionProvider,
    );

    const totalPages = 4;
    final pages = [
      ExploreOnboardingScreen(
        title: 'Tu colonia tiene más de lo que crees',
        onNext: () => _goToNextPage(totalPages),
      ),
      DiscoverOnboardingScreen(onNext: () => _goToNextPage(totalPages)),
      LocationOnboardingScreen(
        title: 'Ve lo que hay a tu alrededor',
        subtitle: 'Activa tu ubicación para descubrir lo que tienes cerca.',
        onNext: () => _goToNextPage(totalPages),
        onPermissionRequired: () async {
          if (!enforceLocationPermission || _currentPage != 2) return;
          if (_locationPermissionStatus.isGranted) return;

          await _showLocationRequiredDialog(
            context,
            isDeniedForever: _locationPermissionStatus.isPermanentlyDenied,
          );
        },
        onPermissionStatusChanged: (status) {
          final wasGranted = _locationPermissionStatus.isGranted;
          setState(() => _locationPermissionStatus = status);

          if (enforceLocationPermission &&
              status.isPermanentlyDenied &&
              _currentPage == 2) {
            _showLocationRequiredDialog(context, isDeniedForever: true);
          }

          if (!wasGranted && status.isGranted && _currentPage == 2 && mounted) {
            _goToNextPage(totalPages);
          }
        },
      ),
      AuthSelectionWidget(
        onSuccess: () {
          context.go(MapRoutes.map);
        },
      ),
    ];

    return Scaffold(
      key: const ValueKey('onboardingScreen'),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          const AnimatedBackground(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: pages,
              ),
            ),
          ),
          _OnboardingSharedNego(
            controller: _controller,
            currentIndex: _currentPage,
            poses: _negoPoses,
          ),
          _OnboardingBackArrow(
            isVisible: _currentPage >= 1,
            onBack: _goToPreviousPage,
          ),
        ],
      ),
    );
  }
}

class OnboardingNegoPose {
  const OnboardingNegoPose({
    required this.size,
    required this.alignment,
    required this.offset,
    required this.mood,
    required this.lookAngle,
    required this.lookVertical,
    required this.interactive,
  });

  final double size;
  final Alignment alignment;
  final Offset offset;
  final NegoMood mood;
  final double lookAngle;
  final NegoLookVertical lookVertical;
  final bool interactive;

  static OnboardingNegoPose lerp(
    OnboardingNegoPose a,
    OnboardingNegoPose b,
    double t,
  ) {
    return OnboardingNegoPose(
      size: lerpDouble(a.size, b.size, t) ?? b.size,
      alignment: Alignment.lerp(a.alignment, b.alignment, t) ?? b.alignment,
      offset: Offset.lerp(a.offset, b.offset, t) ?? b.offset,
      mood: t < 0.5 ? a.mood : b.mood,
      lookAngle: lerpDouble(a.lookAngle, b.lookAngle, t) ?? b.lookAngle,
      lookVertical: t < 0.5 ? a.lookVertical : b.lookVertical,
      interactive: t < 0.5 ? a.interactive : b.interactive,
    );
  }
}

class _OnboardingSharedNego extends StatelessWidget {
  const _OnboardingSharedNego({
    required this.controller,
    required this.currentIndex,
    required this.poses,
  });

  final PageController controller;
  final int currentIndex;
  final List<OnboardingNegoPose> poses;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final double rawPage = controller.hasClients
            ? (controller.page ?? currentIndex.toDouble())
            : currentIndex.toDouble();
        final double clampedPage = rawPage.clamp(
          0.0,
          (poses.length - 1).toDouble(),
        );

        final int lowerIndex = clampedPage.floor();
        final int upperIndex = clampedPage.ceil();
        final double t = (upperIndex == lowerIndex)
            ? 0
            : (clampedPage - lowerIndex);

        final OnboardingNegoPose pose = (lowerIndex == upperIndex)
            ? poses[lowerIndex]
            : OnboardingNegoPose.lerp(poses[lowerIndex], poses[upperIndex], t);

        return Positioned.fill(
          child: Align(
            alignment: pose.alignment,
            child: Transform.translate(
              offset: pose.offset,
              child: NegoAvatar(
                size: pose.size,
                mood: pose.mood,
                lookAngle: pose.lookAngle,
                lookVertical: pose.lookVertical,
                interactive: pose.interactive,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _OnboardingBackArrow extends StatelessWidget {
  const _OnboardingBackArrow({required this.isVisible, required this.onBack});

  final bool isVisible;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 12,
      left: 12,
      child: AnimatedOpacity(
        opacity: isVisible ? 1 : 0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        child: IgnorePointer(
          ignoring: !isVisible,
          child: IconButton(
            key: const ValueKey('onboardingBackButton'),
            tooltip: 'Regresar',
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
          ),
        ),
      ),
    );
  }
}
