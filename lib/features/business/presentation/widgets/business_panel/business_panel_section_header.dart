import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

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
        OurnegoIconButton(
          size: OurnegoIconButtonSize.s28,
          icon: actionIcon,
          semanticLabel: actionIcon == Icons.add_rounded
              ? 'Agregar en $title'
              : 'Editar $title',
          onPressed: onEdit,
        ),
      ],
    );
  }
}
