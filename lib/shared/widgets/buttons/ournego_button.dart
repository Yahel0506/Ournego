import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_burst.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';

/// Text button of the lip family (spec §6.1). Features choose [tone], [size]
/// and icons; colors and text styles come from the component.
class OurnegoButton extends StatelessWidget {
  const OurnegoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = OurnegoButtonTone.primary,
    this.size = OurnegoButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.iconMotion = OurnegoIconMotion.none,
    this.expanded = false,
    this.minWidth,
    this.status = OurnegoButtonStatus.idle,
    this.successLabel = '¡Listo!',
    this.showNego = false,
    this.radius,
    this.semanticLabel,
    this.forcePressed = false,
  }) : assert(
         !showNego ||
             (tone == OurnegoButtonTone.primary &&
                 size != OurnegoButtonSize.small),
         'showNego is only allowed on primary large, regular or compact.',
       );

  const OurnegoButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = OurnegoButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.iconMotion = OurnegoIconMotion.none,
    this.expanded = false,
    this.minWidth,
    this.status = OurnegoButtonStatus.idle,
    this.successLabel = '¡Listo!',
    this.showNego = false,
    this.radius,
    this.semanticLabel,
    this.forcePressed = false,
  }) : tone = OurnegoButtonTone.primary,
       assert(
         !showNego || size != OurnegoButtonSize.small,
         'Nego mini does not fit the small size.',
       );

  const OurnegoButton.neutral({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = OurnegoButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.iconMotion = OurnegoIconMotion.none,
    this.expanded = false,
    this.minWidth,
    this.status = OurnegoButtonStatus.idle,
    this.successLabel = '¡Listo!',
    this.radius,
    this.semanticLabel,
    this.forcePressed = false,
  }) : tone = OurnegoButtonTone.neutral,
       showNego = false;

  const OurnegoButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = OurnegoButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.iconMotion = OurnegoIconMotion.none,
    this.expanded = false,
    this.minWidth,
    this.status = OurnegoButtonStatus.idle,
    this.successLabel = '¡Listo!',
    this.radius,
    this.semanticLabel,
    this.forcePressed = false,
  }) : tone = OurnegoButtonTone.secondary,
       showNego = false;

  const OurnegoButton.tonal({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = OurnegoButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.iconMotion = OurnegoIconMotion.none,
    this.expanded = false,
    this.minWidth,
    this.status = OurnegoButtonStatus.idle,
    this.successLabel = '¡Listo!',
    this.radius,
    this.semanticLabel,
    this.forcePressed = false,
  }) : tone = OurnegoButtonTone.tonal,
       showNego = false;

  const OurnegoButton.destructive({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = OurnegoButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.iconMotion = OurnegoIconMotion.none,
    this.expanded = false,
    this.minWidth,
    this.status = OurnegoButtonStatus.idle,
    this.successLabel = '¡Listo!',
    this.radius,
    this.semanticLabel,
    this.forcePressed = false,
  }) : tone = OurnegoButtonTone.destructive,
       showNego = false;

  /// Ghost tone: no lip, ink on surface, overlay on hover and press.
  const OurnegoButton.text({
    super.key,
    required this.label,
    required this.onPressed,
    this.size = OurnegoButtonSize.regular,
    this.icon,
    this.trailingIcon,
    this.iconMotion = OurnegoIconMotion.none,
    this.expanded = false,
    this.minWidth,
    this.status = OurnegoButtonStatus.idle,
    this.successLabel = '¡Listo!',
    this.radius,
    this.semanticLabel,
    this.forcePressed = false,
  }) : tone = OurnegoButtonTone.ghost,
       showNego = false;

  final String label;
  final VoidCallback? onPressed;
  final OurnegoButtonTone tone;
  final OurnegoButtonSize size;

  /// Leading icon.
  final IconData? icon;
  final IconData? trailingIcon;

  /// `nudge` moves [trailingIcon]; `wiggle` moves [icon]. Mouse hover only.
  final OurnegoIconMotion iconMotion;

  /// Fills the parent width.
  final bool expanded;
  final double? minWidth;
  final OurnegoButtonStatus status;
  final String successLabel;

  /// Nego mini to the left of the label. Primary, non-small only.
  final bool showNego;

  /// Overrides the default radius (24). Only the floating sheet uses 14.
  final double? radius;
  final String? semanticLabel;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  @override
  Widget build(BuildContext context) => _OurnegoButtonBody(button: this);
}

class _OurnegoButtonBody extends StatefulWidget {
  const _OurnegoButtonBody({required this.button});

  final OurnegoButton button;

  @override
  State<_OurnegoButtonBody> createState() => _OurnegoButtonBodyState();
}

class _OurnegoButtonBodyState extends State<_OurnegoButtonBody> {
  bool _hovered = false;
  int _pressCount = 0;
  int? _burstTrigger;

  OurnegoButton get _b => widget.button;

  @override
  void didUpdateWidget(covariant _OurnegoButtonBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.button.status != OurnegoButtonStatus.success &&
        _b.status == OurnegoButtonStatus.success) {
      _burstTrigger = (_burstTrigger ?? 0) + 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final metrics = OurnegoButtonMetrics.of(_b.size);
    final isSuccess = _b.status == OurnegoButtonStatus.success;
    final isGhost = _b.tone == OurnegoButtonTone.ghost;
    final tone = isSuccess ? OurnegoButtonTone.success : _b.tone;
    final label = isSuccess ? _b.successLabel : _b.label;
    final showNego = _b.showNego && metrics.negoSize != null;

    final children = <Widget>[
      if (showNego)
        _NegoMini(
          size: metrics.negoSize!,
          mood: isSuccess
              ? NegoMood.winking
              : _hovered
              ? NegoMood.excited
              : NegoMood.idle,
          eyesClosed: _b.onPressed == null,
          happyTrigger: _pressCount == 0 ? null : _pressCount,
        ),
      if (_b.icon != null)
        OurnegoIconMotionBox(
          motion: _b.iconMotion == OurnegoIconMotion.wiggle
              ? OurnegoIconMotion.wiggle
              : OurnegoIconMotion.none,
          active: _hovered,
          child: Icon(_b.icon, size: metrics.iconSize),
        ),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          softWrap: false,
          style: metrics.textStyle,
        ),
      ),
      if (_b.trailingIcon != null)
        OurnegoIconMotionBox(
          motion: _b.iconMotion == OurnegoIconMotion.nudge
              ? OurnegoIconMotion.nudge
              : OurnegoIconMotion.none,
          active: _hovered,
          child: Icon(_b.trailingIcon, size: metrics.iconSize),
        ),
    ];

    final spaced = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) spaced.add(SizedBox(width: metrics.gap));
      spaced.add(children[i]);
    }

    final radius = _b.radius ?? OurnegoRadiusTokens.button;

    return OurnegoMinTapTarget(
      child: OurnegoBurst(
        trigger: _burstTrigger,
        child: OurnegoPressable(
          onPressed: _b.onPressed,
          colors: ournegoToneColors(context, tone),
          faceHeight: metrics.faceHeight,
          lipDepth: isGhost ? 0 : metrics.lipDepth,
          borderRadius: BorderRadius.circular(radius),
          width: _b.expanded ? double.infinity : null,
          minWidth: _b.minWidth ?? 0,
          padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
          isLoading: _b.status == OurnegoButtonStatus.loading,
          isGhost: isGhost,
          locked: isSuccess,
          semanticLabel: _b.semanticLabel,
          forcePressed: _b.forcePressed,
          onHoverChanged: (value) => setState(() => _hovered = value),
          onPressedChanged: (pressed) {
            if (pressed) setState(() => _pressCount++);
          },
          child: Row(mainAxisSize: MainAxisSize.min, children: spaced),
        ),
      ),
    );
  }
}

class _NegoMini extends StatelessWidget {
  const _NegoMini({
    required this.size,
    required this.mood,
    required this.eyesClosed,
    required this.happyTrigger,
  });

  final double size;
  final NegoMood mood;
  final bool eyesClosed;
  final Object? happyTrigger;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(-6, 0),
      child: ExcludeSemantics(
        child: NegoAvatar(
          size: size,
          interactive: false,
          floating: false,
          mood: mood,
          eyesClosed: eyesClosed,
          happyTrigger: happyTrigger,
        ),
      ),
    );
  }
}
