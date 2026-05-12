import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/animated_particles.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';

class ExploreOnboardingScreen extends StatelessWidget {
  const ExploreOnboardingScreen({
    super.key,
    required this.title,
    required this.onNext,
  });

  final String title;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    final String themedImagePath = isDarkMode
        ? 'assets/images/ournego_white.png'
        : 'assets/images/ournego.png';

    return Stack(
      children: [
        AnimatedParticles(),
        Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 64),
              Image.asset(themedImagePath, height: 48),
              const SizedBox(height: 128),
              Text(
                title,
                style: OurnegoTextStyles.onboardingHeader,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 64),
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
