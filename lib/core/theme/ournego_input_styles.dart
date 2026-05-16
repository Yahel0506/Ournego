import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';

class OurnegoInputStyles {
  OurnegoInputStyles._();

  static InputDecorationTheme inputDecorationTheme(ColorScheme colorScheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: OurnegoSemanticTokens.surfaceSoft(colorScheme),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.input),
        borderSide: BorderSide(
          color: OurnegoSemanticTokens.borderSubtle(colorScheme),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: OurnegoSemanticTokens.borderSubtle(colorScheme),
        ),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.input),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outline, width: 1.2),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.input),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.input),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.input),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: OurnegoSemanticTokens.borderMuted(colorScheme),
        ),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.input),
      ),
      hintStyle: TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.6)),
      labelStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      floatingLabelStyle: TextStyle(color: colorScheme.onSurface),
      prefixIconColor: colorScheme.onSurface.withValues(alpha: 0.8),
      suffixIconColor: colorScheme.onSurface.withValues(alpha: 0.8),
      helperStyle: TextStyle(
        color: colorScheme.onSurface.withValues(alpha: 0.65),
      ),
    );
  }
}
