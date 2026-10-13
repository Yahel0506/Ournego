import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
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
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: OurnegoSpacingTokens.sm),
            Text(
              'Cargando tu negocio...',
              style: OurnegoTextStyles.bodyCompact,
            ),
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
            const Icon(
              Icons.error_outline_rounded,
              color: OurnegoColorTokens.error,
            ),
            const SizedBox(height: OurnegoSpacingTokens.sm),
            Text(
              'No pudimos cargar tu panel de negocio.',
              textAlign: TextAlign.center,
              style: OurnegoTextStyles.bodyCompact,
            ),
            const SizedBox(height: OurnegoSpacingTokens.sm),
            OurnegoButton.primary(
              size: OurnegoButtonSize.compact,
              label: 'Reintentar',
              icon: Icons.refresh_rounded,
              iconMotion: OurnegoIconMotion.wiggle,
              onPressed: onRetry,
            ),
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
          style: OurnegoTextStyles.bodyCompact.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
