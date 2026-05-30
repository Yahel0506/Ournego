import 'package:flutter/material.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_gallery.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_identity_card.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_info_grid.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_map_preview.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_section_header.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

class BusinessPanelPreviewCard extends StatelessWidget {
  const BusinessPanelPreviewCard({
    super.key,
    required this.ownedBusiness,
    required this.onEditIdentity,
    required this.onAddGalleryImage,
    required this.onDeleteGalleryImage,
    required this.onEditLocation,
    required this.onEditPhone,
    required this.onEditHours,
  });

  final OwnedBusinessProfile ownedBusiness;
  final VoidCallback onEditIdentity;
  final VoidCallback onAddGalleryImage;
  final ValueChanged<String> onDeleteGalleryImage;
  final VoidCallback onEditLocation;
  final VoidCallback onEditPhone;
  final VoidCallback onEditHours;

  @override
  Widget build(BuildContext context) {
    return OurnegoContentContainer(
      borderRadius: OurnegoRadiusTokens.lg,
      customHorizontalPadding: OurnegoSpacingTokens.md,
      customVerticalPadding: OurnegoSpacingTokens.md,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BusinessPanelSectionHeader(
            title: 'Informacion principal',
            onEdit: onEditIdentity,
          ),
          const SizedBox(height: OurnegoSpacingTokens.sm),
          BusinessPanelIdentityCard(ownedBusiness: ownedBusiness),
          const SizedBox(height: OurnegoSpacingTokens.md),
          BusinessPanelSectionHeader(
            title: 'Galeria',
            onEdit: onAddGalleryImage,
            actionIcon: Icons.add_rounded,
          ),
          const SizedBox(height: OurnegoSpacingTokens.sm),
          BusinessPanelGallery(
            images: ownedBusiness.images,
            onDeleteImage: onDeleteGalleryImage,
            onAddImage: onAddGalleryImage,
          ),
          const SizedBox(height: OurnegoSpacingTokens.md),
          BusinessPanelSectionHeader(title: 'Mapa', onEdit: onEditLocation),
          const SizedBox(height: OurnegoSpacingTokens.sm),
          BusinessPanelMapPreview(
            address: ownedBusiness.address,
            latitude: ownedBusiness.latitude,
            longitude: ownedBusiness.longitude,
            onEdit: onEditLocation,
          ),
          const SizedBox(height: OurnegoSpacingTokens.md),
          BusinessPanelInfoGrid(
            ownedBusiness: ownedBusiness,
            onEditLocation: onEditLocation,
            onEditPhone: onEditPhone,
            onEditHours: onEditHours,
          ),
        ],
      ),
    );
  }
}
