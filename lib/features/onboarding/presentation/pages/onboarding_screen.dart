import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/generic_slide.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/location_slide.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ournego/shared/widgets/animated_background.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';
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
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InformationCardWidget(
                  title: isDeniedForever
                      ? 'Permiso de ubicacion bloqueado'
                      : 'Ubicacion requerida',
                  description: isDeniedForever
                      ? 'Activalo desde los ajustes del dispositivo para continuar.'
                      : 'Debes habilitar la ubicacion para poder continuar.',
                  imagePath: 'assets/images/location_error.png',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
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
                ),
              ],
            ),
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
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goToNextPage(BuildContext context, int totalPages) async {
    if (_currentPage >= totalPages - 1) {
      return;
    }

    if (_currentPage == 2 && !_locationPermissionStatus.isGranted) {
      await _showLocationRequiredDialog(
        context,
        isDeniedForever: _locationPermissionStatus.isPermanentlyDenied,
      );
      return;
    }

    await _controller.animateToPage(
      _currentPage + 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeIn,
    );
  }

  Future<void> _goToPreviousPage() async {
    if (_currentPage <= 0) {
      return;
    }

    await _controller.animateToPage(
      _currentPage - 1,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeIn,
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = ref.watch(slidesListProvider);

    final pages = [
      // Slide 0: Bienvenida
      GenericSlide(
        title: slides[0].title,
        description: slides[0].description.toString(),
        imagePath: slides[0].imagePath.toString(),
      ),
      // Slide 1: Funciones de la App
      GenericSlide(
        title: slides[1].title,
        description: slides[1].description.toString(),
        imagePath: slides[1].imagePath.toString(),
      ),
      // Slide 2: Acceso a la Ubicacion
      LocationSlide(
        title: slides[2].title,
        description: slides[2].description.toString(),
        imagePath: slides[2].imagePath.toString(),
        buttonText: slides[2].buttonText,
        onPermissionStatusChanged: (status) {
          final wasGranted = _locationPermissionStatus.isGranted;
          setState(() {
            _locationPermissionStatus = status;
          });

          // Avanza automaticamente cuando el permiso se concede en la slide de ubicacion.
          if (!wasGranted && status.isGranted && _currentPage == 2) {
            _controller.animateToPage(
              3,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeIn,
            );
          }

          if (status.isPermanentlyDenied && _currentPage == 2) {
            _showLocationRequiredDialog(context, isDeniedForever: true);
          }
        },
      ),
      // Slide 3: Inicio de sesion
      AuthSelectionWidget(
        onSuccess: () {
          context.go(MapRoutes.map);
        },
      ),
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Fondo Colores Desenfocados
          AnimatedBackground(),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: pages,
              ),
            ),
          ),
          // ------ Contador de paginas ------
          Column(
            children: [
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _currentPage > 0 ? _goToPreviousPage : null,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Anterior'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _currentPage < pages.length - 1
                        ? () => _goToNextPage(context, pages.length)
                        : null,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Siguiente'),
                  ),
                ],
              ),
              const SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}
