import 'package:flutter/material.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(OurnegoRadiusTokens.lg),
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.primary.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(OurnegoRadiusTokens.lg),
          border: Border.all(
            color: OurnegoSemanticTokens.borderSubtle(colorScheme),
          ),
        ),
        child: Icon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
