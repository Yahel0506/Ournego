import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/animated_particles.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';

class LocationOnboardingScreen extends StatelessWidget {
  const LocationOnboardingScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onNext,
  });

  final String title;
  final String subtitle;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedParticles(),
        Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 72),
              Text(
                title,
                style: OurnegoTextStyles.onboardingHeader,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: OurnegoTextStyles.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 140,
                height: 60,
                child: OurnegoPrimaryButton(
                  key: const ValueKey('onboardingLocationContinueButton'),
                  onPressed: onNext,
                  child: const Text('Activar', style: OurnegoTextStyles.header),
                ),
              ),
              const SizedBox(height: 32),
              Icon(Icons.location_on, size: 180, color: Colors.redAccent),
            ],
          ),
        ),
      ],
    );
  }
}
