import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

import 'button_test_helpers.dart';

void main() {
  final light = OurnegoTheme.light.colorScheme;
  final dark = OurnegoTheme.dark.colorScheme;

  // Page background each tone sits on, used to composite translucent faces.
  Color background(ColorScheme s) => s.brightness == Brightness.dark
      ? OurnegoColorTokens.surfaceDark
      : OurnegoColorTokens.blanco;

  for (final (name, scheme) in [('light', light), ('dark', dark)]) {
    group('$name palette', () {
      for (final tone in OurnegoButtonTone.values) {
        test('$tone ink/face contrast is at least 4.5', () {
          final colors = OurnegoButtonPalette.of(tone, scheme);
          final face = Color.alphaBlend(colors.face, background(scheme));
          expect(
            contrast(colors.ink, face),
            greaterThanOrEqualTo(4.5),
            reason: '$tone in $name',
          );
        });
      }

      test('outlined tonal keeps the tonal face and uses the contour lip', () {
        final tonal = OurnegoButtonPalette.of(OurnegoButtonTone.tonal, scheme);
        final outlined = OurnegoButtonPalette.of(
          OurnegoButtonTone.tonal,
          scheme,
          outlined: true,
        );
        expect(outlined.face, tonal.face);
        expect(outlined.lip, OurnegoButtonPalette.outlineLip(scheme));
        expect(outlined.border, OurnegoSemanticTokens.borderSubtle(scheme));
      });

      test('disabled applies to every tone', () {
        final disabled = OurnegoButtonPalette.disabled(scheme);
        final ghost = OurnegoButtonPalette.disabled(scheme, ghost: true);
        expect(disabled.border.a, 0);
        expect(disabled.face.a, greaterThan(0));
        expect(ghost.face.a, 0);
        expect(ghost.lip.a, 0);
        expect(ghost.ink, disabled.ink);
      });
    });
  }

  test('primary ink is noche in both themes', () {
    expect(
      OurnegoButtonPalette.of(OurnegoButtonTone.primary, light).ink,
      const Color(0xFF161616),
    );
    expect(
      OurnegoButtonPalette.of(OurnegoButtonTone.primary, dark).ink,
      const Color(0xFF161616),
    );
  });

  test('outlineLip composites the contour over the page', () {
    expect(
      OurnegoButtonPalette.outlineLip(light),
      closeToColor(const Color(0xFFB3B3B3)),
    );
    expect(
      OurnegoButtonPalette.outlineLip(dark),
      closeToColor(const Color(0xFF3E4745)),
    );
  });

  test('light borderSubtle is black at 30% (outline must stay undefined)', () {
    expect(
      OurnegoButtonPalette.borderSubtle(light),
      closeToColor(const Color(0x4D000000)),
    );
    expect(
      OurnegoButtonPalette.borderSubtle(dark),
      closeToColor(const Color(0x4D89938F)),
    );
  });

  test('glass palette matches spec values', () {
    expect(
      OurnegoGlassPalette.face(light),
      closeToColor(const Color(0xE0F4FBF9)),
    );
    expect(
      OurnegoGlassPalette.face(dark),
      closeToColor(const Color(0xE01E2625)),
    );
    expect(
      OurnegoGlassPalette.borderHover(light),
      closeToColor(const Color(0x80000000)),
    );
    expect(
      OurnegoGlassPalette.borderHover(dark),
      closeToColor(const Color(0x9989938F)),
    );
    expect(
      OurnegoGlassPalette.focusGlow(light),
      closeToColor(const Color(0x473BCFED)),
    );
    expect(
      OurnegoGlassPalette.focusGlow(dark),
      closeToColor(const Color(0x4D3BCFED)),
    );
  });

  test('button sizes match §3.3', () {
    const expected = {
      OurnegoButtonSize.large: (56.0, 5.0, 24.0, 17.0, 22.0, 10.0, 30.0),
      OurnegoButtonSize.regular: (50.0, 4.0, 24.0, 16.0, 22.0, 10.0, 30.0),
      OurnegoButtonSize.compact: (44.0, 3.0, 18.0, 15.0, 22.0, 10.0, 26.0),
      OurnegoButtonSize.small: (36.0, 2.0, 14.0, 14.0, 18.0, 6.0, null),
    };
    expected.forEach((size, values) {
      final m = OurnegoButtonMetrics.of(size);
      expect(m.faceHeight, values.$1);
      expect(m.lipDepth, values.$2);
      expect(m.horizontalPadding, values.$3);
      expect(m.textStyle.fontSize, values.$4);
      expect(m.textStyle.fontWeight, FontWeight.w800);
      expect(m.iconSize, values.$5);
      expect(m.gap, values.$6);
      expect(m.negoSize, values.$7);
    });
  });

  test('icon button sizes match §3.4', () {
    const expected = {
      OurnegoIconButtonSize.s52: (52.0, 4.0, 22.0),
      OurnegoIconButtonSize.s48: (48.0, 4.0, 22.0),
      OurnegoIconButtonSize.s44: (44.0, 3.0, 22.0),
      OurnegoIconButtonSize.s40: (40.0, 3.0, 20.0),
      OurnegoIconButtonSize.s32: (32.0, 3.0, 18.0),
      OurnegoIconButtonSize.s28: (28.0, 2.0, 16.0),
    };
    expected.forEach((size, values) {
      final m = OurnegoIconButtonMetrics.of(size);
      expect(m.side, values.$1);
      expect(m.lipDepth, values.$2);
      expect(m.iconSize, values.$3);
    });
  });

  test('component metrics match §3.5', () {
    expect(OurnegoComponentMetrics.chipHeight, 40);
    expect(OurnegoComponentMetrics.chipLip, 3);
    expect(OurnegoComponentMetrics.chipHorizontalPadding, 16);
    expect(OurnegoComponentMetrics.rowHeight, 58);
    expect(OurnegoComponentMetrics.rowRadius, 30);
    expect(OurnegoComponentMetrics.rowLip, 4);
    expect(OurnegoComponentMetrics.actionHeight, 42);
    expect(OurnegoComponentMetrics.actionRadius, 12);
    expect(OurnegoComponentMetrics.actionLip, 3);
    expect(OurnegoComponentMetrics.tileMinHeight, 76);
    expect(OurnegoComponentMetrics.socialHeight, 50);
    expect(OurnegoComponentMetrics.socialRadius, 24);
    expect(OurnegoComponentMetrics.socialLip, 4);
    expect(OurnegoComponentMetrics.glassIconSide, 52);
    expect(OurnegoComponentMetrics.glassSurfaceHeight, 52);
    expect(OurnegoComponentMetrics.glassChipHeight, 40);
    expect(OurnegoComponentMetrics.navItemSize, 56);
    expect(OurnegoComponentMetrics.navIconSize, 30);
    expect(OurnegoComponentMetrics.navPadding, 8);
    expect(OurnegoComponentMetrics.minTapTarget, 48);
  });
}
