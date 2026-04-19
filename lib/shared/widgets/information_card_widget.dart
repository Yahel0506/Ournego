import 'package:flutter/material.dart';

import '../../core/ournego_text_styles.dart';
import '../../core/theme/tokens/ournego_spacing_tokens.dart';

class InformationCardWidget extends StatelessWidget {
  const InformationCardWidget({
    super.key,
    required this.title,
    required this.description,
    required this.imagePath,
  });

  final String title;
  final String description;
  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(OurnegoSpacingTokens.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            imagePath,
            height: 250,
            errorBuilder: (_, error, stackTrace) =>
                const Icon(Icons.info_outline, size: 96),
          ),
          const SizedBox(height: OurnegoSpacingTokens.md),
          Text(
            title,
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: OurnegoSpacingTokens.xs),
          Text(
            description,
            textAlign: TextAlign.center,
            style: OurnegoTextStyles.body.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: OurnegoSpacingTokens.xxl),
        ],
      ),
    );
  }
}
