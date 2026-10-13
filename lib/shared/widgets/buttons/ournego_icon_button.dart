import 'package:flutter/material.dart';

import 'package:ournego/shared/widgets/buttons/ournego_burst.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';

/// Icon-only lip button (spec §6.5). [semanticLabel] is mandatory.
///
/// Never use it for voice or profile in the map top bar: those are
/// `OurnegoGlassIconButton`.
class OurnegoIconButton extends StatelessWidget {
  const OurnegoIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.tone = OurnegoButtonTone.glass,
    this.size = OurnegoIconButtonSize.s52,
    this.radius,
    this.outlined,
    this.child,
    this.iconMotion = OurnegoIconMotion.none,
    this.tooltip,
    this.forcePressed = false,
  }) : selected = null,
       selectedIcon = null,
       onChanged = null,
       celebrate = false;

  /// Transparent, no lip; overlay on hover and press.
  const OurnegoIconButton.ghost({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.size = OurnegoIconButtonSize.s48,
    this.radius,
    this.iconMotion = OurnegoIconMotion.none,
    this.tooltip,
    this.forcePressed = false,
  }) : tone = OurnegoButtonTone.ghost,
       outlined = null,
       child = null,
       selected = null,
       selectedIcon = null,
       onChanged = null,
       celebrate = false;

  /// Two-state button: pops on every change and exposes `toggled`.
  const OurnegoIconButton.toggle({
    super.key,
    required bool this.selected,
    required this.icon,
    required IconData this.selectedIcon,
    required this.semanticLabel,
    required this.onChanged,
    this.tone = OurnegoButtonTone.tonal,
    this.size = OurnegoIconButtonSize.s32,
    this.radius,
    this.outlined,
    this.celebrate = false,
    this.tooltip,
    this.forcePressed = false,
  }) : onPressed = null,
       child = null,
       iconMotion = OurnegoIconMotion.none;

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;
  final OurnegoButtonTone tone;
  final OurnegoIconButtonSize size;

  /// Null means a circle. 16 for map controls, 14 for sheet controls.
  final double? radius;

  /// Adds the 1 px contour and the contour lip. Only for `tonal` sheet
  /// controls; `glass`, `secondary` and `white` already have it.
  final bool? outlined;

  /// Replaces the icon (e.g. an avatar), clipped to a circle.
  final Widget? child;
  final OurnegoIconMotion iconMotion;
  final String? tooltip;

  /// Toggle state; null for plain buttons.
  final bool? selected;
  final IconData? selectedIcon;
  final ValueChanged<bool>? onChanged;

  /// Burst of 10 dots when the toggle turns on.
  final bool celebrate;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  bool get _isToggle => selected != null;

  @override
  Widget build(BuildContext context) => _OurnegoIconButtonBody(button: this);
}

class _OurnegoIconButtonBody extends StatefulWidget {
  const _OurnegoIconButtonBody({required this.button});

  final OurnegoIconButton button;

  @override
  State<_OurnegoIconButtonBody> createState() => _OurnegoIconButtonBodyState();
}

class _OurnegoIconButtonBodyState extends State<_OurnegoIconButtonBody> {
  bool _hovered = false;
  int? _burstTrigger;

  OurnegoIconButton get _b => widget.button;

  @override
  void didUpdateWidget(covariant _OurnegoIconButtonBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_b.celebrate &&
        oldWidget.button.selected == false &&
        _b.selected == true) {
      _burstTrigger = (_burstTrigger ?? 0) + 1;
    }
  }

  VoidCallback? get _onPressed {
    if (!_b._isToggle) return _b.onPressed;
    final onChanged = _b.onChanged;
    if (onChanged == null) return null;
    return () => onChanged(!_b.selected!);
  }

  @override
  Widget build(BuildContext context) {
    final metrics = OurnegoIconButtonMetrics.of(_b.size);
    final isGhost = _b.tone == OurnegoButtonTone.ghost;
    final radius = _b.radius ?? metrics.side / 2;

    Widget content;
    if (_b.child != null) {
      content = Padding(
        padding: EdgeInsets.all(metrics.childInset),
        child: ClipOval(child: SizedBox.expand(child: _b.child)),
      );
    } else {
      final iconData = _b.selected == true ? _b.selectedIcon! : _b.icon;
      content = AnimatedSwitcher(
        duration: Duration.zero,
        child: Icon(
          iconData,
          key: ValueKey<IconData>(iconData),
          size: metrics.iconSize,
        ),
      );
      if (_b._isToggle) {
        content = OurnegoIconPop(value: _b.selected, child: content);
      } else {
        content = OurnegoIconMotionBox(
          motion: _b.iconMotion,
          active: _hovered,
          child: content,
        );
      }
    }

    final pressable = OurnegoPressable(
      onPressed: _onPressed,
      colors: ournegoToneColors(context, _b.tone, outlined: _b.outlined),
      faceHeight: metrics.side,
      lipDepth: isGhost ? 0 : metrics.lipDepth,
      borderRadius: BorderRadius.circular(radius),
      width: metrics.side,
      isGhost: isGhost,
      semanticLabel: _b.semanticLabel,
      tooltip: _b.tooltip,
      toggled: _b.selected,
      forcePressed: _b.forcePressed,
      onHoverChanged: (value) => setState(() => _hovered = value),
      child: SizedBox.square(dimension: metrics.side, child: content),
    );

    if (!_b._isToggle) return pressable;
    return OurnegoMinTapTarget(
      child: OurnegoBurst(trigger: _burstTrigger, count: 10, child: pressable),
    );
  }
}
