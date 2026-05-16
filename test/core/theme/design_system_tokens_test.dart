import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/ournego_input_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';

void main() {
  test('brand and action tokens stay separated', () {
    expect(OurnegoColorTokens.actionPrimary, OurnegoColorTokens.azulCielo);
    expect(
      OurnegoColorTokens.actionPrimaryPressed,
      OurnegoColorTokens.azulVerde,
    );
    expect(OurnegoColorTokens.brandPrimary, OurnegoColorTokens.verdeCastleton);
    expect(OurnegoColorTokens.error, const Color(0xFFBA1A1A));
  });

  test('semantic spacing and radius aliases map to current primitives', () {
    expect(OurnegoSpacingTokens.inputGap, 10);
    expect(OurnegoSpacingTokens.formSectionGap, OurnegoSpacingTokens.lg);
    expect(OurnegoSpacingTokens.navHeight, 72);
    expect(OurnegoRadiusTokens.input, OurnegoRadiusTokens.xl);
    expect(OurnegoRadiusTokens.container, OurnegoRadiusTokens.xl);
    expect(OurnegoRadiusTokens.sheet, 18);
    expect(OurnegoRadiusTokens.button, 24);
  });

  test('typography scale exposes the expected shared tokens', () {
    expect(OurnegoTextStyles.display.fontSize, 32);
    expect(OurnegoTextStyles.headline.fontSize, 26);
    expect(OurnegoTextStyles.title.fontSize, 24);
    expect(OurnegoTextStyles.sheetTitle.fontSize, 22);
    expect(OurnegoTextStyles.body.fontSize, 16);
    expect(OurnegoTextStyles.bodyCompact.fontSize, 14);
    expect(OurnegoTextStyles.caption.fontSize, 12);
    expect(OurnegoTextStyles.badge.fontSize, 11);
    expect(OurnegoTextStyles.button.fontSize, 16);
  });

  test('input decoration theme centralizes fill and border semantics', () {
    final colorScheme = ThemeData.light().colorScheme.copyWith(
      primary: OurnegoColorTokens.actionPrimary,
      surface: OurnegoColorTokens.surfaceLight,
      onSurface: OurnegoColorTokens.noche,
      error: OurnegoColorTokens.error,
    );

    final theme = OurnegoInputStyles.inputDecorationTheme(colorScheme);
    final border = theme.border;

    expect(theme.filled, isTrue);
    expect(theme.fillColor, OurnegoSemanticTokens.surfaceSoft(colorScheme));
    expect(border, isA<OutlineInputBorder>());
    expect(
      (border as OutlineInputBorder).borderRadius,
      BorderRadius.circular(OurnegoRadiusTokens.input),
    );
    expect(theme.disabledBorder, isA<OutlineInputBorder>());
    expect(theme.errorBorder, isA<OutlineInputBorder>());
  });
}
