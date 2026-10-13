import 'package:flutter/material.dart';

import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';

/// Full-width access button with three slots so the label stays centered
/// with or without a badge (spec §6.6).
class OurnegoSocialButton extends StatefulWidget {
  const OurnegoSocialButton({
    super.key,
    required this.leading,
    required this.label,
    required this.onPressed,
    this.badge,
    this.tone = OurnegoButtonTone.secondary,
    this.forcePressed = false,
  });

  factory OurnegoSocialButton.google({
    Key? key,
    required VoidCallback? onPressed,
    bool forcePressed = false,
  }) {
    return OurnegoSocialButton(
      key: key,
      leading: Image.asset(
        googleAsset,
        width: OurnegoComponentMetrics.socialIconSize,
      ),
      label: 'Continuar con Google',
      onPressed: onPressed,
      tone: OurnegoButtonTone.white,
      forcePressed: forcePressed,
    );
  }

  static const String googleAsset = 'assets/images/google.png';

  /// An `Icon(…_rounded)` or an `Image.asset`.
  final Widget leading;
  final String label;
  final VoidCallback? onPressed;

  /// Small pill on the right, e.g. 'Pronto'.
  final String? badge;
  final OurnegoButtonTone tone;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  @override
  State<OurnegoSocialButton> createState() => _OurnegoSocialButtonState();
}

class _OurnegoSocialButtonState extends State<OurnegoSocialButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final metrics = OurnegoButtonMetrics.regular;
    final side = widget.badge == null
        ? OurnegoComponentMetrics.socialSide
        : OurnegoComponentMetrics.socialSideWithBadge;
    final badgeColors = ournegoToneColors(context, OurnegoButtonTone.tonal);

    return OurnegoPressable(
      onPressed: widget.onPressed,
      colors: ournegoToneColors(context, widget.tone),
      faceHeight: OurnegoComponentMetrics.socialHeight,
      lipDepth: OurnegoComponentMetrics.socialLip,
      borderRadius: BorderRadius.circular(OurnegoComponentMetrics.socialRadius),
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: metrics.horizontalPadding),
      forcePressed: widget.forcePressed,
      onHoverChanged: (value) => setState(() => _hovered = value),
      child: Row(
        children: [
          SizedBox(
            width: side,
            child: Align(
              alignment: Alignment.centerLeft,
              child: IconTheme.merge(
                data: const IconThemeData(
                  size: OurnegoComponentMetrics.socialIconSize,
                ),
                child: OurnegoIconMotionBox(
                  motion: OurnegoIconMotion.wiggle,
                  active: _hovered,
                  child: widget.leading,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                widget.label,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: metrics.textStyle,
              ),
            ),
          ),
          SizedBox(
            width: side,
            child: widget.badge == null
                ? null
                : Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: ShapeDecoration(
                        shape: const StadiumBorder(),
                        color: badgeColors.face,
                      ),
                      child: Text(
                        widget.badge!.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          height: 1.1,
                          color: badgeColors.ink,
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
