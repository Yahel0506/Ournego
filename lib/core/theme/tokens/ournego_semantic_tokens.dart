import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';

class OurnegoSemanticTokens {
  OurnegoSemanticTokens._();

  static Color surfaceSoft(ColorScheme colorScheme) {
    return colorScheme.surface.withValues(alpha: 0.5);
  }

  static Color surfaceRaised(ColorScheme colorScheme) {
    return colorScheme.surface;
  }

  static Color borderSubtle(ColorScheme colorScheme) {
    return colorScheme.outline.withValues(alpha: 0.3);
  }

  static Color borderMuted(ColorScheme colorScheme) {
    return colorScheme.outline.withValues(alpha: 0.2);
  }

  static Color overlay([double alpha = 0.35]) {
    return Colors.black.withValues(alpha: alpha);
  }

  static Color success(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? OurnegoColorTokens.mentaOscuro
        : OurnegoColorTokens.success;
  }

  static Color warning(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? const Color(0xFFFFB955)
        : OurnegoColorTokens.warning;
  }

  static Color info(ColorScheme colorScheme) {
    return colorScheme.primary;
  }

  static Color error(ColorScheme colorScheme) {
    return colorScheme.error;
  }
}
