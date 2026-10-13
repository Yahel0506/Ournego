import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_glass_pressable.dart';

/// Flat glass pill over the map, e.g. the zone chip (spec §6.12). No lip.
class OurnegoGlassChip extends StatelessWidget {
  const OurnegoGlassChip({
    super.key,
    required this.label,
    required this.actionLabel,
    required this.onPressed,
    this.leadingIcon = Icons.place_rounded,
    this.semanticLabel,
    this.forcePressed = false,
  });

  /// e.g. 'Zona: Centro'.
  final String label;

  /// e.g. 'Cambiar'.
  final String actionLabel;
  final VoidCallback? onPressed;
  final IconData leadingIcon;
  final String? semanticLabel;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return OurnegoGlassPressable(
      onPressed: onPressed,
      height: OurnegoComponentMetrics.glassChipHeight,
      borderRadius: BorderRadius.circular(OurnegoComponentMetrics.chipRadius),
      padding: const EdgeInsets.symmetric(
        horizontal: OurnegoComponentMetrics.glassChipPadding,
      ),
      semanticLabel: semanticLabel,
      forcePressed: forcePressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            leadingIcon,
            size: OurnegoComponentMetrics.glassChipPinSize,
            color: OurnegoButtonPalette.accentInk(scheme),
          ),
          const SizedBox(width: OurnegoComponentMetrics.glassChipGap),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: OurnegoTextStyles.bodyCompact.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: OurnegoComponentMetrics.glassChipGap),
          Text(
            actionLabel,
            maxLines: 1,
            style: OurnegoTextStyles.bodyCompact.copyWith(
              fontWeight: FontWeight.w800,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
