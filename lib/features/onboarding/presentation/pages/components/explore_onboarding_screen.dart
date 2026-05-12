import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';

class ExploreOnboardingScreen extends StatelessWidget {
  const ExploreOnboardingScreen({
    super.key,
    required this.title,
    required this.description,
    required this.onNext,
  });

  final String title;
  final String description;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          const SizedBox(height: 280),
          Text(
            title,
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('onboardingExploreContinueButton'),
              onPressed: onNext,
              child: const Text('Continuar'),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
