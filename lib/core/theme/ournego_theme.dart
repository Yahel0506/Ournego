import 'package:flutter/material.dart';

import 'package:ournego/core/theme/ournego_button_styles.dart';
import 'package:ournego/core/theme/ournego_input_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/ournego_text_styles.dart';

class OurnegoTheme {
  OurnegoTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: OurnegoColorTokens.actionPrimary,
      onPrimary: Colors.white,
      primaryContainer: OurnegoColorTokens.cianClaro,
      onPrimaryContainer: OurnegoColorTokens.azulVerde,
      secondary: OurnegoColorTokens.aguamarina,
      onSecondary: OurnegoColorTokens.verdeCastleton,
      secondaryContainer: OurnegoColorTokens.verdeMenta,
      tertiary: OurnegoColorTokens.verdeCastleton,
      surface: OurnegoColorTokens.surfaceLight,
      onSurface: OurnegoColorTokens.noche,
      error: OurnegoColorTokens.error,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: OurnegoColorTokens.blanco,
      colorScheme: scheme,
      inputDecorationTheme: OurnegoInputStyles.inputDecorationTheme(scheme),
      elevatedButtonTheme: OurnegoButtonStyles.elevatedButtonTheme(scheme),
      outlinedButtonTheme: OurnegoButtonStyles.outlinedButtonTheme(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: OurnegoTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          textStyle: OurnegoTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
          ),
        ),
      ),
    );
  }

  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      primary: OurnegoColorTokens.azulCielo,
      onPrimary: OurnegoColorTokens.noche,
      primaryContainer: OurnegoColorTokens.verdeBrunswick,
      onPrimaryContainer: OurnegoColorTokens.cianClaro,
      secondary: OurnegoColorTokens.mentaOscuro,
      onSecondary: OurnegoColorTokens.noche,
      secondaryContainer: OurnegoColorTokens.verdeCastleton,
      surface: OurnegoColorTokens.surfaceDark,
      onSurface: Color(0xFFE1E3E1),
      outline: Color(0xFF89938F),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OurnegoColorTokens.noche,
      colorScheme: scheme,
      inputDecorationTheme: OurnegoInputStyles.inputDecorationTheme(scheme),
      elevatedButtonTheme: OurnegoButtonStyles.elevatedButtonTheme(scheme),
      outlinedButtonTheme: OurnegoButtonStyles.outlinedButtonTheme(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: OurnegoTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: scheme.onSurface,
          textStyle: OurnegoTextStyles.button,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
          ),
        ),
      ),
    );
  }
}
