import 'package:flutter/material.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';

class OurnegoColors {
  // --- Códigos Base del PDF ---
  static const Color azulCielo = OurnegoColorTokens.azulCielo;
  static const Color cianClaro = OurnegoColorTokens.cianClaro;
  static const Color azulVerde = OurnegoColorTokens.azulVerde;
  static const Color actionPrimary = OurnegoColorTokens.actionPrimary;
  static const Color actionPrimaryPressed =
      OurnegoColorTokens.actionPrimaryPressed;

  static const Color aguamarina = OurnegoColorTokens.aguamarina;
  static const Color verdeMenta = OurnegoColorTokens.verdeMenta;
  static const Color mentaOscuro = OurnegoColorTokens.mentaOscuro;

  static const Color verdeCastleton = OurnegoColorTokens.verdeCastleton;
  static const Color verdeBrunswick = OurnegoColorTokens.verdeBrunswick;
  static const Color brandPrimary = OurnegoColorTokens.brandPrimary;

  static const Color noche = OurnegoColorTokens.noche;
  static const Color blanco = OurnegoColorTokens.blanco;
  static const Color success = OurnegoColorTokens.success;
  static const Color warning = OurnegoColorTokens.warning;
  static const Color info = OurnegoColorTokens.info;
  static const Color error = OurnegoColorTokens.error;

  // TODO: Extract semantic color tokens (e.g. `background`, `surface`,
  // `accent`) and provide accessibility helpers (contrast checks).
  // Perspective: Add unit tests for color contrast and a `fromHex`
  // helper to allow theming from design tokens.

  //* --- TEMA CLARO ---
  static final ThemeData lightTheme = OurnegoTheme.light;

  // --- TEMA OSCURO ---
  static final ThemeData darkTheme = OurnegoTheme.dark; //*/
}
