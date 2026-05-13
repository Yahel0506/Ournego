import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/onboarding/presentation/pages/components/onboarding_responsive_layout.dart';
import 'package:ournego/shared/widgets/animated_particles.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';

class ExploreOnboardingScreen extends StatelessWidget {
  const ExploreOnboardingScreen({
    super.key,
    required this.title,
    required this.onNext,
    this.isActive = true,
  });

  final String title;
  final VoidCallback onNext;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    final String themedImagePath = isDarkMode
        ? 'assets/images/ournego_white.png'
        : 'assets/images/ournego.png';

    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topGap = (screenHeight * 0.08).clamp(32.0, 64.0).toDouble();
    final titleGap = (screenHeight * 0.14).clamp(72.0, 128.0).toDouble();

    return Stack(
      children: [
        if (!disableAnimations)
          TickerMode(enabled: isActive, child: const AnimatedParticles()),
        OnboardingResponsiveLayout(
          scrollBelowHeight: 680,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: topGap),
              Image.asset(themedImagePath, height: 48),
              SizedBox(height: titleGap),
              Text(
                title,
                style: OurnegoTextStyles.onboardingHeader,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: 200,
                height: 56,
                child: OurnegoNeutralPrimaryButton(
                  key: const ValueKey('onboardingExploreContinueButton'),
                  onPressed: onNext,
                  child: const Text(
                    'Explorar',
                    style: OurnegoTextStyles.header,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
