import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';

class BusinessPanelMetricTile extends StatelessWidget {
  const BusinessPanelMetricTile({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.onTap,
    this.isLoading = false,
  });

  final IconData icon;
  final String value;
  final String label;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.xl),
        child: Ink(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.xl),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(OurnegoSpacingTokens.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 36, color: colorScheme.onSurface),
                const SizedBox(height: OurnegoSpacingTokens.lg),
                Text(
                  isLoading ? '--' : value,
                  style: OurnegoTextStyles.headline.copyWith(
                    color: colorScheme.onSurface,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: OurnegoTextStyles.caption.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
