import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_icon_button.dart';
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
  final VoidCallback onEditPhone;
  final VoidCallback onEditHours;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoItem(
          icon: Icons.location_on_outlined,
          title: 'Direccion',
          value: ownedBusiness.address,
          onEdit: onEditLocation,
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

  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(OurnegoSpacingTokens.sm),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
      ),
      child: BusinessPanelSectionHeader(title: 'Horarios', onEdit: onEdit),
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
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
          BusinessPanelIconButton(
            small: true,
            onTap: onEdit,
            child: const Icon(Icons.edit_rounded, size: 14),
          ),
        ],
      ),
    );
  }
}
