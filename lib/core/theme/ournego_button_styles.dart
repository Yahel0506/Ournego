import 'package:flutter/material.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';

class OurnegoButtonStyles {
  OurnegoButtonStyles._();

  static ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return OurnegoColorTokens.azulVerde;
          }

          return OurnegoColorTokens.azulCielo;
        }),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
      ),
    );
  }

  static OutlinedButtonThemeData outlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(width: 1, color: colorScheme.onSurface),
        foregroundColor: colorScheme.onSurface,
      ),
    );
  }
}
