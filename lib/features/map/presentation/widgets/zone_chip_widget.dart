import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

/// Shows which zone stands in for the device location and lets the user
/// change it. Only visible while there is no GPS fix.
class ZoneChip extends StatelessWidget {
  const ZoneChip({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Zona: $label. Cambiar',
      child: GestureDetector(
        key: const Key('zone-chip'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: OurnegoContentContainer(
          hasBlur: true,
          borderRadius: OurnegoRadiusTokens.pill,
          customHorizontalPadding: OurnegoSpacingTokens.md,
          customVerticalPadding: OurnegoSpacingTokens.xs,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place_rounded, size: 18, color: colorScheme.primary),
              const SizedBox(width: OurnegoSpacingTokens.xs),
              Flexible(
                child: Text(
                  'Zona: $label',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: OurnegoTextStyles.bodyCompact.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: OurnegoSpacingTokens.xs),
              Text(
                '· Cambiar',
                style: OurnegoTextStyles.bodyCompact.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
