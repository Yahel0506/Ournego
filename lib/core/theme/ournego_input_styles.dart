import 'package:flutter/material.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';

class OurnegoInputStyles {
  OurnegoInputStyles._();

  static InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface.withValues(alpha: 0.5),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(OurnegoRadiusTokens.xl)),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1.2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error, width: 1.2),
      ),
      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
    );
  }
}
