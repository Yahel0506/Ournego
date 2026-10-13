import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';

/// Theme-level safety nets for buttons that Flutter builds internally
/// (pickers, dialogs). App code uses `lib/shared/widgets/buttons/` instead.
class OurnegoButtonThemes {
  OurnegoButtonThemes._();

  static ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colorScheme) {
    return ElevatedButtonThemeData(
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(double.infinity, 50)),
        backgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return OurnegoColorTokens.actionPrimaryPressed;
          }

          return OurnegoColorTokens.actionPrimary;
        }),
        foregroundColor: WidgetStatePropertyAll(colorScheme.onPrimary),
        textStyle: const WidgetStatePropertyAll(OurnegoTextStyles.button),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
          ),
        ),
      ),
    );
  }

  static OutlinedButtonThemeData outlinedButtonTheme(ColorScheme colorScheme) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        side: BorderSide(
          width: 1,
          color: OurnegoSemanticTokens.borderSubtle(colorScheme),
        ),
        foregroundColor: colorScheme.onSurface,
        textStyle: OurnegoTextStyles.button,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(OurnegoRadiusTokens.button),
        ),
      ),
    );
  }
}
