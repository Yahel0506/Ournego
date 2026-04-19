import 'package:flutter/material.dart';

class OurnegoInputStyles {
  OurnegoInputStyles._();

  static InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surface,
      border: const OutlineInputBorder(),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
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
