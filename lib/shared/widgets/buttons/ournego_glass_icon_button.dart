import 'package:flutter/material.dart';

import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_glass_pressable.dart';

/// Round flat glass button that floats over the map: voice and profile
/// (spec §6.12). No lip. While [active] the contour and ink turn accent; the
/// face never fills with aqua.
class OurnegoGlassIconButton extends StatelessWidget {
  const OurnegoGlassIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.onPressed,
    this.activeIcon,
    this.active = false,
    this.showHalo = false,
    this.child,
    this.tooltip,
    this.forcePressed = false,
  });

  static const Duration _iconFade = Duration(milliseconds: 150);

  final IconData icon;
  final String semanticLabel;
  final VoidCallback? onPressed;

  /// Icon while [active], e.g. `mic_rounded`.
  final IconData? activeIcon;
  final bool active;

  /// Animated halo while [active] (microphone).
  final bool showHalo;

  /// Replaces the icon (profile avatar), clipped to a circle.
  final Widget? child;
  final String? tooltip;

  /// Only for the QA gallery: draws the pressed state permanently.
  final bool forcePressed;

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (child != null) {
      content = Padding(
        padding: const EdgeInsets.all(OurnegoComponentMetrics.glassChildInset),
        child: ClipOval(child: SizedBox.expand(child: child)),
      );
    } else {
      final iconData = active && activeIcon != null ? activeIcon! : icon;
      content = AnimatedSwitcher(
        duration: _iconFade,
        child: Icon(iconData, key: ValueKey<IconData>(iconData)),
      );
    }

    return OurnegoGlassPressable(
      onPressed: onPressed,
      height: OurnegoComponentMetrics.glassIconSide,
      width: OurnegoComponentMetrics.glassIconSide,
      active: active,
      showHalo: showHalo,
      semanticLabel: semanticLabel,
      tooltip: tooltip,
      toggled: showHalo ? active : null,
      forcePressed: forcePressed,
      child: content,
    );
  }
}
