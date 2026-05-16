import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';

class SheetControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const SheetControlButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(OurnegoRadiusTokens.iconButton),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color:
              backgroundColor ??
              Theme.of(
                context,
              ).colorScheme.inverseSurface.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(OurnegoRadiusTokens.iconButton),
        ),
        child: Icon(
          icon,
          size: 18,
          color: iconColor ?? Theme.of(context).colorScheme.inverseSurface,
        ),
      ),
    );
  }
}
