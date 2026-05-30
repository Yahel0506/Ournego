import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

class BusinessPanelLockedCenterCard extends StatelessWidget {
  const BusinessPanelLockedCenterCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: colorScheme.onSurface.withValues(alpha: 0.1),
            blurRadius: 16,
          ),
        ],
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.xl),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.lg),
        child: OurnegoContentContainer(
          borderRadius: OurnegoRadiusTokens.xl,
          customHorizontalPadding: OurnegoSpacingTokens.md,
          customVerticalPadding: OurnegoSpacingTokens.md,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(OurnegoRadiusTokens.full),
                ),
                child: Icon(Icons.lock_rounded, color: colorScheme.primary),
              ),
              const SizedBox(width: OurnegoSpacingTokens.sm),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Mi centro', style: OurnegoTextStyles.body),
                    SizedBox(height: 2),
                    Text(
                      'Funcion premium bloqueada',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
            ],
          ),
        ),
      ),
    );
  }
}
