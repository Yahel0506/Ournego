import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';

class OurnegoPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Key? buttonKey;
  final Size minimumSize;

  const OurnegoPrimaryButton({
    super.key,
    this.onPressed,
    required this.child,
    this.buttonKey,
    this.minimumSize = const Size(double.infinity, 50),
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      key: buttonKey,
      onPressed: onPressed,
      style: ButtonStyle(
        minimumSize: WidgetStatePropertyAll(minimumSize),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return OurnegoColors.actionPrimaryPressed;
          }

          return Theme.of(context).colorScheme.primary;
        }),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.onPrimary,
        ),
        elevation: WidgetStateProperty.all(0),
        textStyle: const WidgetStatePropertyAll(OurnegoTextStyles.button),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
          ),
        ),
      ),
      child: child,
    );
  }
}

class OurnegoNeutralPrimaryButton extends StatelessWidget {
  const OurnegoNeutralPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.minimumSize = const Size(double.infinity, 56),
    this.radius = OurnegoRadiusTokens.button,
    this.elevation = 6,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Size minimumSize;
  final double radius;
  final double elevation;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;
    final background = isDark ? OurnegoColors.blanco : OurnegoColors.noche;
    final foreground = isDark ? OurnegoColors.noche : OurnegoColors.blanco;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        minimumSize: minimumSize,
        backgroundColor: background,
        foregroundColor: foreground,
        elevation: elevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        textStyle: OurnegoTextStyles.button,
      ),
      child: child,
    );
  }
}

class OurnegoButtonStyles {
  OurnegoButtonStyles._();

  static ButtonStyle authOutlinedOnSurface(BuildContext context) {
    return OutlinedButton.styleFrom(
      side: BorderSide(
        width: 1,
        color: OurnegoSemanticTokens.borderSubtle(
          Theme.of(context).colorScheme,
        ),
      ),
      foregroundColor: Theme.of(
        context,
      ).colorScheme.onSurface.withValues(alpha: 0.9),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.7),
      textStyle: OurnegoTextStyles.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
      ),
    );
  }

  static ButtonStyle authFilledOnSurface(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: OurnegoColors.blanco,
      foregroundColor: OurnegoColors.noche,
      elevation: 2,
      textStyle: OurnegoTextStyles.button,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
      ),
    );
  }

  static ButtonStyle circularSurface({
    required BuildContext context,
    Size minimumSize = const Size(52, 52),
    double alpha = 0.6,
  }) {
    return ElevatedButton.styleFrom(
      shape: const CircleBorder(),
      minimumSize: minimumSize,
      padding: EdgeInsets.zero,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: alpha),
      elevation: 0,
    );
  }

  static ButtonStyle tonalCardButton({
    required BuildContext context,
    required double radius,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ElevatedButton.styleFrom(
      elevation: 0,
      backgroundColor: colorScheme.inverseSurface.withValues(alpha: 0.12),
      foregroundColor: colorScheme.onSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      textStyle: OurnegoTextStyles.button,
    );
  }
}
