import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';

class OurnegoTheme {
  OurnegoTheme._();

  static ThemeData get light {
    const scheme = ColorScheme.light(
      primary: OurnegoColorTokens.azulCielo,
      onPrimary: Colors.white,
      primaryContainer: OurnegoColorTokens.cianClaro,
      onPrimaryContainer: OurnegoColorTokens.azulVerde,
      secondary: OurnegoColorTokens.aguamarina,
      onSecondary: OurnegoColorTokens.verdeCastleton,
      secondaryContainer: OurnegoColorTokens.verdeMenta,
      tertiary: OurnegoColorTokens.verdeCastleton,
      surface: Color(0xFFF4FBF9),
      onSurface: OurnegoColorTokens.noche,
      error: Color(0xFFBA1A1A),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: OurnegoColorTokens.blanco,
      colorScheme: scheme,
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
      surface: Color(0xFF1E2625),
      onSurface: Color(0xFFE1E3E1),
      outline: Color(0xFF89938F),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: OurnegoColorTokens.noche,
      colorScheme: scheme,
    );
  }
}
