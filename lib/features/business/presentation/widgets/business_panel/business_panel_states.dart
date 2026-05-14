import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

class BusinessPanelLoadingState extends StatelessWidget {
  const BusinessPanelLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return OurnegoContentContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OurnegoSpacingTokens.lg),
        child: Column(
          children: const [
            CircularProgressIndicator(),
            SizedBox(height: OurnegoSpacingTokens.sm),
            Text('Cargando tu negocio...'),
          ],
        ),
      ),
    );
  }
}

class BusinessPanelErrorState extends StatelessWidget {
  const BusinessPanelErrorState({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return OurnegoContentContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OurnegoSpacingTokens.md),
        child: Column(
          children: [
            const Text(
              'No pudimos cargar tu panel de negocio.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OurnegoSpacingTokens.sm),
            FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}

class BusinessPanelEmptyState extends StatelessWidget {
  const BusinessPanelEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return OurnegoContentContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: OurnegoSpacingTokens.md),
        child: Text(
          'No encontramos un negocio asociado a esta cuenta.',
          textAlign: TextAlign.center,
          style: OurnegoTextStyles.body.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
