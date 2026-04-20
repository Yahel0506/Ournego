import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_colors.dart';

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
            return OurnegoColors.azulVerde;
          }

          return OurnegoColors.azulCielo;
        }),
        foregroundColor: WidgetStatePropertyAll(
          Theme.of(context).colorScheme.onPrimary,
        ),
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
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
      ),
      foregroundColor: Theme.of(context).colorScheme.onSurface,
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surface.withValues(alpha: 0.6),
    );
  }

  static ButtonStyle authFilledOnSurface(BuildContext context) {
    return ElevatedButton.styleFrom(
      backgroundColor: Theme.of(context).colorScheme.onSurface,
      foregroundColor: Theme.of(context).colorScheme.surface,
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
    );
  }
}
