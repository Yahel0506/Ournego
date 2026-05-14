import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_preview_card.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

class BusinessPanelEditorDropdown extends StatelessWidget {
  const BusinessPanelEditorDropdown({
    super.key,
    required this.isExpanded,
    required this.onChanged,
    required this.ownedBusiness,
    required this.onEditIdentity,
    required this.onAddGalleryImage,
    required this.onDeleteGalleryImage,
    required this.onEditLocation,
    required this.onEditPhone,
    required this.onEditHours,
  });

  final bool isExpanded;
  final ValueChanged<bool> onChanged;
  final OwnedBusinessProfile ownedBusiness;
  final VoidCallback onEditIdentity;
  final VoidCallback onAddGalleryImage;
  final ValueChanged<String> onDeleteGalleryImage;
  final VoidCallback onEditLocation;
  final VoidCallback onEditPhone;
  final VoidCallback onEditHours;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return OurnegoContentContainer(
      borderRadius: OurnegoRadiusTokens.lg,
      customHorizontalPadding: OurnegoSpacingTokens.md,
      customVerticalPadding: OurnegoSpacingTokens.sm,
      backgroundColor: colorScheme.surface,
      borderColor: colorScheme.outline.withValues(alpha: 0.3),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(top: OurnegoSpacingTokens.sm),
          title: const Text('Editar mi negocio', style: OurnegoTextStyles.body),
          trailing: AnimatedRotation(
            turns: isExpanded ? 0.5 : 0,
            duration: const Duration(milliseconds: 180),
            child: const Icon(Icons.expand_more_rounded),
          ),
          onExpansionChanged: onChanged,
          children: [
            BusinessPanelPreviewCard(
              ownedBusiness: ownedBusiness,
              onEditIdentity: onEditIdentity,
              onAddGalleryImage: onAddGalleryImage,
              onDeleteGalleryImage: onDeleteGalleryImage,
              onEditLocation: onEditLocation,
              onEditPhone: onEditPhone,
              onEditHours: onEditHours,
            ),
          ],
        ),
      ),
    );
  }
}
