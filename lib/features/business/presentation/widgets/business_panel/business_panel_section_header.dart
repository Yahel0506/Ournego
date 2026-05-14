import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_icon_button.dart';

class BusinessPanelSectionHeader extends StatelessWidget {
  const BusinessPanelSectionHeader({
    super.key,
    required this.title,
    required this.onEdit,
    this.actionIcon = Icons.edit_rounded,
  });

  final String title;
  final VoidCallback onEdit;
  final IconData actionIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: OurnegoTextStyles.body)),
        BusinessPanelIconButton(
          small: true,
          onTap: onEdit,
          child: Icon(actionIcon, size: 16),
        ),
      ],
    );
  }
}
