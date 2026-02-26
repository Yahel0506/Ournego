import 'package:flutter/material.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/animated_background.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/generic_slide.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/location_slide.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/login_slide.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slides = ref.watch(slidesListProvider);
    final authSelection = ref.watch(authSelectionProvider);
    PageController controller = PageController();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Fondo Colores Desenfocados
          AnimatedBackground(),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isWide = constraints.maxWidth >= 600;

                if (isWide) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton.filled(
                        onPressed: () {
                          controller.animateToPage(
                            ((controller.page ?? 0) - 1).toInt(),
                            duration: Duration(milliseconds: 220),
                            curve: Curves.easeIn,
                          );
                        },
                        icon: Icon(Icons.arrow_left),
                      ),
                      SizedBox(width: 30),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 500),
                        child: PageView(
                          controller: controller,
                          children: [
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
                            // Slide 2: Acceso a la Ubicación
                            LocationSlide(
                              title: slides[2].title,
                              description: slides[2].description.toString(),
                              imagePath: slides[2].imagePath.toString(),
                              buttonText: slides[2].buttonText,
                            ),
                            // Slide 3: Inicio de Sesión
                            LoginSlide(
                              title: authSelection.title,
                              imagePath: authSelection.imagePath.toString(),
                              darkImagePath: authSelection.darkImagePath
                                  .toString(),
                              googleLogin: authSelection.googleLogin.toString(),
                              emailLogin: authSelection.emailLogin.toString(),
                              phoneLogin: authSelection.phoneLogin.toString(),
                              guestAccess: authSelection.guestAccess.toString(),
                              termsText1: authSelection.termsText1.toString(),
                              termsText2: authSelection.termsText2.toString(),
                              termsText3: authSelection.termsText3.toString(),
                              termsText4: authSelection.termsText4.toString(),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 30),
                      IconButton.filled(
                        onPressed: () {
                          controller.animateToPage(
                            ((controller.page ?? 0) + 1).toInt(),
                            duration: Duration(milliseconds: 220),
                            curve: Curves.easeIn,
                          );
                        },
                        icon: Icon(Icons.arrow_right),
                      ),
                    ],
                  );
                } else {
                  // Para móviles, solo mostramos el PageView sin botones laterales
                  return PageView(
                    controller: controller,
                    children: [
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
                      // Slide 2: Acceso a la Ubicación
                      LocationSlide(
                        title: slides[2].title,
                        description: slides[2].description.toString(),
                        imagePath: slides[2].imagePath.toString(),
                        buttonText: slides[2].buttonText,
                      ),
                      // Slide 3: Inicio de Sesión
                      LoginSlide(
                        title: authSelection.title,
                        imagePath: authSelection.imagePath.toString(),
                        darkImagePath: authSelection.darkImagePath.toString(),
                        googleLogin: authSelection.googleLogin.toString(),
                        emailLogin: authSelection.emailLogin.toString(),
                        phoneLogin: authSelection.phoneLogin.toString(),
                        guestAccess: authSelection.guestAccess.toString(),
                        termsText1: authSelection.termsText1.toString(),
                        termsText2: authSelection.termsText2.toString(),
                        termsText3: authSelection.termsText3.toString(),
                        termsText4: authSelection.termsText4.toString(),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
          // ------ Contador de paginas ------
          Column(
            children: [
              Spacer(),
              SmoothPageIndicator(
                controller: controller,
                count: 4,
                effect: JumpingDotEffect(
                  dotColor: Theme.of(context).colorScheme.primaryContainer,
                  activeDotColor: Theme.of(
                    context,
                  ).colorScheme.onPrimaryContainer,
                ),
                onDotClicked: (index) {
                  controller.jumpToPage(index);
                },
              ),
              SizedBox(height: 30),
            ],
          ),
        ],
      ),
    );
  }
}
