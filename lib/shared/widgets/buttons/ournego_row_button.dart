import 'package:flutter/material.dart';

import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';

/// Full-width row action with an accent circle and a chevron (spec §6.7).
class OurnegoRowButton extends StatefulWidget {
  const OurnegoRowButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.forcePressed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  @override
  State<OurnegoRowButton> createState() => _OurnegoRowButtonState();
}

class _OurnegoRowButtonState extends State<OurnegoRowButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = ournegoToneColors(context, OurnegoButtonTone.tonal);
    final enabled = widget.onPressed != null;

    return OurnegoPressable(
      onPressed: widget.onPressed,
      colors: ournegoToneColors(context, OurnegoButtonTone.glass),
      faceHeight: OurnegoComponentMetrics.rowHeight,
      lipDepth: OurnegoComponentMetrics.rowLip,
      borderRadius: BorderRadius.circular(OurnegoComponentMetrics.rowRadius),
      width: double.infinity,
      padding: const EdgeInsets.only(
        left: OurnegoComponentMetrics.rowPaddingLeft,
        right: OurnegoComponentMetrics.rowPaddingRight,
      ),
      forcePressed: widget.forcePressed,
      onHoverChanged: (value) => setState(() => _hovered = value),
      child: Row(
        children: [
          Container(
            width: OurnegoComponentMetrics.rowAccentSize,
            height: OurnegoComponentMetrics.rowAccentSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled ? accent.face : const Color(0x00000000),
            ),
            child: Icon(
              widget.icon,
              size: OurnegoComponentMetrics.rowAccentIconSize,
              color: enabled ? accent.ink : null,
            ),
          ),
          Expanded(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: OurnegoButtonMetrics.regular.textStyle,
            ),
          ),
          OurnegoIconMotionBox(
            motion: OurnegoIconMotion.nudge,
            active: _hovered,
            child: Icon(
              Icons.chevron_right_rounded,
              size: OurnegoComponentMetrics.rowChevronSize,
              color: enabled ? OurnegoButtonPalette.accentInk(scheme) : null,
            ),
          ),
        ],
      ),
    );
  }
}
