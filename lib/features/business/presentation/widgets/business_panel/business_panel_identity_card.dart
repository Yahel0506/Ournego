import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_labels.dart';

class BusinessPanelIdentityCard extends StatelessWidget {
  const BusinessPanelIdentityCard({super.key, required this.ownedBusiness});

  final OwnedBusinessProfile ownedBusiness;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
      ),
      padding: const EdgeInsets.all(OurnegoSpacingTokens.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ownedBusiness.name,
            style: OurnegoTextStyles.body.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: OurnegoSpacingTokens.xs),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: OurnegoSpacingTokens.sm,
              vertical: OurnegoSpacingTokens.xs,
            ),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(OurnegoRadiusTokens.full),
            ),
            child: Text(
              businessTypeLabel(ownedBusiness.category),
              style: OurnegoTextStyles.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: OurnegoSpacingTokens.xs),
          Text(
            ownedBusiness.description.isEmpty
                ? 'Sin descripcion.'
                : ownedBusiness.description,
            style: OurnegoTextStyles.body.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
