import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_section_header.dart';

class BusinessPanelInfoGrid extends StatelessWidget {
  const BusinessPanelInfoGrid({
    super.key,
    required this.ownedBusiness,
    required this.onEditLocation,
    required this.onEditPhone,
    required this.onEditHours,
  });

  final OwnedBusinessProfile ownedBusiness;
  final VoidCallback onEditLocation;
  final ValueChanged<ContainerTransformOriginController> onEditPhone;
  final ValueChanged<ContainerTransformOriginController> onEditHours;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoItem(
          icon: Icons.location_on_outlined,
          title: 'Direccion',
          value: ownedBusiness.address,
          onEdit: (_) => onEditLocation(),
        ),
        const SizedBox(height: OurnegoSpacingTokens.xs),
        _InfoItem(
          icon: Icons.phone_outlined,
          title: 'Telefono',
          value: ownedBusiness.phoneNumber ?? 'No configurado',
          onEdit: onEditPhone,
        ),
        const SizedBox(height: OurnegoSpacingTokens.xs),
        _HoursItem(onEdit: onEditHours),
      ],
    );
  }
}

class _HoursItem extends StatelessWidget {
  const _HoursItem({required this.onEdit});

  final ValueChanged<ContainerTransformOriginController> onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The hours editor grows out of this tile.
    return ContainerTransformTrigger(
      radius: OurnegoRadiusTokens.md,
      color: colorScheme.surface,
      builder: (context, origin) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(OurnegoSpacingTokens.sm),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
        ),
        child: BusinessPanelSectionHeader(
          title: 'Horarios',
          onEdit: () => onEdit(origin),
        ),
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onEdit,
  });

  final IconData icon;
  final String title;
  final String value;
  final ValueChanged<ContainerTransformOriginController> onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // The editor of this tile grows out of it.
    return ContainerTransformTrigger(
      radius: OurnegoRadiusTokens.md,
      color: colorScheme.surface,
      builder: (context, origin) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(OurnegoSpacingTokens.sm),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: OurnegoSpacingTokens.xs),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: OurnegoTextStyles.body.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: OurnegoTextStyles.body.copyWith(fontSize: 13),
                  ),
                ],
              ),
            ),
            OurnegoIconButton(
              size: OurnegoIconButtonSize.s28,
              icon: Icons.edit_rounded,
              semanticLabel: 'Editar $title',
              onPressed: () => onEdit(origin),
            ),
          ],
        ),
      ),
    );
  }
}
