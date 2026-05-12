import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';

class GenericSlide extends StatelessWidget {
  final String title;
  final String description;
  final String imagePath;
  final VoidCallback onNext;

  const GenericSlide({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ------ Imágen ------
        Image(image: AssetImage(imagePath)),
        // ------ Titulo ------
        Text(
          title,
          style: OurnegoTextStyles.header,
          textAlign: TextAlign.center,
        ),
        // ------ Descripción ------
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Text(
            description,
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('onboardingGenericContinueButton'),
              onPressed: onNext,
              child: const Text('Continuar'),
            ),
          ),
        ),
      ],
    );
  }
}
