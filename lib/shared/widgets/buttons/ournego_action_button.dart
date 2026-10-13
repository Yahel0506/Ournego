import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/shared/widgets/buttons/ournego_burst.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';

/// Icon-only sheet action that fills its parent width (spec §6.8). Use it
/// inside an `Expanded`.
class OurnegoActionButton extends StatefulWidget {
  const OurnegoActionButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.forcePressed = false,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  @override
  State<OurnegoActionButton> createState() => _OurnegoActionButtonState();
}

class _OurnegoActionButtonState extends State<OurnegoActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return OurnegoPressable(
      onPressed: widget.onPressed,
      colors: ournegoToneColors(context, OurnegoButtonTone.glass),
      faceHeight: OurnegoComponentMetrics.actionHeight,
      lipDepth: OurnegoComponentMetrics.actionLip,
      borderRadius: BorderRadius.circular(OurnegoComponentMetrics.actionRadius),
      width: double.infinity,
      semanticLabel: widget.semanticLabel,
      forcePressed: widget.forcePressed,
      onHoverChanged: (value) => setState(() => _hovered = value),
      child: OurnegoIconMotionBox(
        motion: OurnegoIconMotion.wiggle,
        active: _hovered,
        child: Icon(widget.icon, size: OurnegoComponentMetrics.actionIconSize),
      ),
    );
  }
}

/// Sheet tile: icon over a short label (spec §6.8). With [selected] it acts
/// as a toggle: pops on change and bursts when it turns on if [celebrate].
class OurnegoActionTile extends StatefulWidget {
  const OurnegoActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.selectedIcon,
    this.selected,
    this.celebrate = false,
    this.forcePressed = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final IconData? selectedIcon;
  final bool? selected;
  final bool celebrate;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  @override
  State<OurnegoActionTile> createState() => _OurnegoActionTileState();
}

class _OurnegoActionTileState extends State<OurnegoActionTile> {
  int? _burstTrigger;

  @override
  void didUpdateWidget(covariant OurnegoActionTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.celebrate &&
        oldWidget.selected == false &&
        widget.selected == true) {
      _burstTrigger = (_burstTrigger ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToggle = widget.selected != null;
    final iconData = widget.selected == true
        ? (widget.selectedIcon ?? widget.icon)
        : widget.icon;
    Widget icon = Icon(
      iconData,
      key: ValueKey<IconData>(iconData),
      size: OurnegoComponentMetrics.tileIconSize,
    );
    if (isToggle) icon = OurnegoIconPop(value: widget.selected, child: icon);

    final tile = OurnegoPressable(
      onPressed: widget.onPressed,
      colors: ournegoToneColors(context, OurnegoButtonTone.glass),
      faceHeight: null,
      minFaceHeight: OurnegoComponentMetrics.tileMinHeight,
      lipDepth: OurnegoComponentMetrics.tileLip,
      borderRadius: BorderRadius.circular(OurnegoComponentMetrics.tileRadius),
      width: double.infinity,
      padding: OurnegoComponentMetrics.tilePadding,
      toggled: widget.selected,
      forcePressed: widget.forcePressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(height: OurnegoComponentMetrics.tileGap),
          Text(
            widget.label,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            style: OurnegoTextStyles.buttonTile,
          ),
        ],
      ),
    );

    if (!isToggle) return tile;
    return OurnegoBurst(trigger: _burstTrigger, count: 10, child: tile);
  }
}
