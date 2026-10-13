import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';

/// Visual tone of a lip button. Features pick a tone, never a color.
enum OurnegoButtonTone {
  primary,
  neutral,
  secondary,
  tonal,
  success,
  destructive,
  glass,
  white,
  ghost,
}

enum OurnegoButtonSize { large, regular, compact, small }

enum OurnegoButtonStatus { idle, loading, success }

enum OurnegoIconMotion { none, nudge, wiggle }

enum OurnegoIconButtonSize { s52, s48, s44, s40, s32, s28 }

@immutable
class OurnegoButtonColors {
  const OurnegoButtonColors({
    required this.face,
    required this.lip,
    required this.ink,
    this.border = const Color(0x00000000),
  });

  final Color face;
  final Color lip;
  final Color ink;
  final Color border;

  static OurnegoButtonColors lerp(
    OurnegoButtonColors a,
    OurnegoButtonColors b,
    double t,
  ) {
    return OurnegoButtonColors(
      face: Color.lerp(a.face, b.face, t)!,
      lip: Color.lerp(a.lip, b.lip, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      border: Color.lerp(a.border, b.border, t)!,
    );
  }

  OurnegoButtonColors copyWith({
    Color? face,
    Color? lip,
    Color? ink,
    Color? border,
  }) {
    return OurnegoButtonColors(
      face: face ?? this.face,
      lip: lip ?? this.lip,
      ink: ink ?? this.ink,
      border: border ?? this.border,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is OurnegoButtonColors &&
        other.face == face &&
        other.lip == lip &&
        other.ink == ink &&
        other.border == border;
  }

  @override
  int get hashCode => Object.hash(face, lip, ink, border);
}

/// Colors of the lip button family (spec §3.1). These values never leave
/// `lib/shared/widgets/buttons/`.
class OurnegoButtonPalette {
  OurnegoButtonPalette._();

  static Color borderSubtle(ColorScheme s) =>
      OurnegoSemanticTokens.borderSubtle(s);

  /// Contour composited over the page background: 0xFFB3B3B3 light,
  /// 0xFF3E4745 dark.
  static Color outlineLip(ColorScheme s) => Color.alphaBlend(
    borderSubtle(s),
    s.brightness == Brightness.dark
        ? OurnegoColorTokens.surfaceDark
        : OurnegoColorTokens.blanco,
  );

  static OurnegoButtonColors of(
    OurnegoButtonTone tone,
    ColorScheme s, {
    bool? outlined,
  }) {
    final dark = s.brightness == Brightness.dark;
    final border = borderSubtle(s);
    final lipOutline = outlineLip(s);

    OurnegoButtonColors base;
    switch (tone) {
      case OurnegoButtonTone.primary:
        base = OurnegoButtonColors(
          face: OurnegoColorTokens.azulCielo,
          lip: dark ? const Color(0xFF0A86A6) : OurnegoColorTokens.azulVerde,
          ink: OurnegoColorTokens.noche,
        );
      case OurnegoButtonTone.neutral:
        base = dark
            ? const OurnegoButtonColors(
                face: OurnegoColorTokens.blanco,
                lip: Color(0xFFAEBDB8),
                ink: OurnegoColorTokens.noche,
              )
            : const OurnegoButtonColors(
                face: OurnegoColorTokens.noche,
                lip: Color(0xFF000000),
                ink: OurnegoColorTokens.blanco,
              );
      case OurnegoButtonTone.secondary:
        base = OurnegoButtonColors(
          face: dark
              ? OurnegoColorTokens.surfaceDark
              : OurnegoColorTokens.blanco,
          lip: lipOutline,
          ink: s.onSurface,
          border: border,
        );
      case OurnegoButtonTone.tonal:
        base = dark
            ? const OurnegoButtonColors(
                face: OurnegoColorTokens.verdeBrunswick,
                lip: Color(0xFF012A1F),
                ink: OurnegoColorTokens.cianClaro,
              )
            : const OurnegoButtonColors(
                face: OurnegoColorTokens.cianClaro,
                lip: Color(0xFFA4E4F2),
                ink: OurnegoColorTokens.verdeCastleton,
              );
      case OurnegoButtonTone.success:
        base = dark
            ? const OurnegoButtonColors(
                face: OurnegoColorTokens.mentaOscuro,
                lip: Color(0xFF25845C),
                ink: OurnegoColorTokens.noche,
              )
            : const OurnegoButtonColors(
                face: OurnegoColorTokens.aguamarina,
                lip: OurnegoColorTokens.mentaOscuro,
                ink: OurnegoColorTokens.verdeCastleton,
              );
      case OurnegoButtonTone.destructive:
        base = OurnegoButtonColors(
          face: OurnegoColorTokens.error,
          lip: dark ? const Color(0xFF5C0909) : const Color(0xFF7A0F0F),
          ink: OurnegoColorTokens.blanco,
        );
      case OurnegoButtonTone.glass:
        base = OurnegoButtonColors(
          face: dark
              ? OurnegoColorTokens.surfaceDark
              : OurnegoColorTokens.blanco,
          lip: lipOutline,
          ink: s.onSurface,
          border: border,
        );
      case OurnegoButtonTone.white:
        base = const OurnegoButtonColors(
          face: OurnegoColorTokens.blanco,
          lip: Color(0xFFB3B3B3),
          ink: OurnegoColorTokens.noche,
          border: Color(0x4D000000),
        );
      case OurnegoButtonTone.ghost:
        base = OurnegoButtonColors(
          face: const Color(0x00000000),
          lip: const Color(0x00000000),
          ink: s.onSurface,
        );
    }

    if (outlined == true) {
      base = OurnegoButtonColors(
        face: base.face,
        lip: lipOutline,
        ink: base.ink,
        border: border,
      );
    }
    return base;
  }

  static OurnegoButtonColors disabled(ColorScheme s, {bool ghost = false}) {
    final dark = s.brightness == Brightness.dark;
    return OurnegoButtonColors(
      face: ghost
          ? const Color(0x00000000)
          : (dark ? const Color(0x14E1E3E1) : const Color(0x12161616)),
      lip: ghost
          ? const Color(0x00000000)
          : (dark ? const Color(0x0DE1E3E1) : const Color(0x17161616)),
      ink: dark ? const Color(0x61E1E3E1) : const Color(0x61161616),
    );
  }

  static Color ghostOverlay(ColorScheme s) => s.brightness == Brightness.dark
      ? const Color(0x14E1E3E1)
      : const Color(0x12055F46);

  static Color focusRing(ColorScheme s) => s.brightness == Brightness.dark
      ? OurnegoColorTokens.azulCielo
      : OurnegoColorTokens.azulVerde;

  static Color accentInk(ColorScheme s) => s.brightness == Brightness.dark
      ? OurnegoColorTokens.azulCielo
      : OurnegoColorTokens.azulVerde;

  static const List<Color> burstColors = [
    OurnegoColorTokens.aguamarina,
    OurnegoColorTokens.azulCielo,
    OurnegoColorTokens.mentaOscuro,
    OurnegoColorTokens.azulVerde,
  ];
}

/// Colors of the flat glass line (spec §3.1.1). No lip, no overshoot.
class OurnegoGlassPalette {
  OurnegoGlassPalette._();

  // 0xE0F4FBF9 light / 0xE01E2625 dark.
  static Color face(ColorScheme s) => s.surface.withValues(alpha: 0.88);
  static Color navFace(ColorScheme s) => s.surface;
  static Color border(ColorScheme s) => OurnegoSemanticTokens.borderSubtle(s);
  static Color borderHover(ColorScheme s) => s.brightness == Brightness.dark
      ? s.outline.withValues(alpha: 0.6)
      : s.outline.withValues(alpha: 0.5);
  static Color active(ColorScheme s) => OurnegoButtonPalette.accentInk(s);
  static Color focusGlow(ColorScheme s) => OurnegoColorTokens.azulCielo
      .withValues(alpha: s.brightness == Brightness.dark ? 0.30 : 0.28);
  static const Color halo = OurnegoColorTokens.azulCielo;
  static const Color navIndicator = OurnegoColorTokens.azulCielo;
  static const Color navIndicatorInk = OurnegoColorTokens.noche;
  static const Color navShadow = OurnegoColorTokens.shadow;
  static const double blurSigma = 10;
}

/// Metrics of [OurnegoButtonSize] (spec §3.3).
@immutable
class OurnegoButtonMetrics {
  const OurnegoButtonMetrics({
    required this.faceHeight,
    required this.lipDepth,
    required this.horizontalPadding,
    required this.textStyle,
    required this.iconSize,
    required this.gap,
    required this.negoSize,
  });

  final double faceHeight;
  final double lipDepth;
  final double horizontalPadding;
  final TextStyle textStyle;
  final double iconSize;
  final double gap;

  /// Null when Nego mini is not allowed for the size.
  final double? negoSize;

  static const OurnegoButtonMetrics large = OurnegoButtonMetrics(
    faceHeight: 56,
    lipDepth: 5,
    horizontalPadding: 24,
    textStyle: OurnegoTextStyles.buttonLarge,
    iconSize: 22,
    gap: 10,
    negoSize: 30,
  );
  static const OurnegoButtonMetrics regular = OurnegoButtonMetrics(
    faceHeight: 50,
    lipDepth: 4,
    horizontalPadding: 24,
    textStyle: OurnegoTextStyles.button,
    iconSize: 22,
    gap: 10,
    negoSize: 30,
  );
  static const OurnegoButtonMetrics compact = OurnegoButtonMetrics(
    faceHeight: 44,
    lipDepth: 3,
    horizontalPadding: 18,
    textStyle: OurnegoTextStyles.buttonCompact,
    iconSize: 22,
    gap: 10,
    negoSize: 26,
  );
  static const OurnegoButtonMetrics small = OurnegoButtonMetrics(
    faceHeight: 36,
    lipDepth: 2,
    horizontalPadding: 14,
    textStyle: OurnegoTextStyles.buttonSmall,
    iconSize: 18,
    gap: 6,
    negoSize: null,
  );

  static OurnegoButtonMetrics of(OurnegoButtonSize size) {
    return switch (size) {
      OurnegoButtonSize.large => large,
      OurnegoButtonSize.regular => regular,
      OurnegoButtonSize.compact => compact,
      OurnegoButtonSize.small => small,
    };
  }
}

/// Metrics of [OurnegoIconButtonSize] (spec §3.4).
@immutable
class OurnegoIconButtonMetrics {
  const OurnegoIconButtonMetrics({
    required this.side,
    required this.lipDepth,
    required this.iconSize,
    required this.childInset,
  });

  final double side;

  /// Lip of the filled tones. `ghost` never has a lip.
  final double lipDepth;
  final double iconSize;

  /// Inner margin around a `child` (e.g. an avatar).
  final double childInset;

  static OurnegoIconButtonMetrics of(OurnegoIconButtonSize size) {
    return switch (size) {
      OurnegoIconButtonSize.s52 => const OurnegoIconButtonMetrics(
        side: 52,
        lipDepth: 4,
        iconSize: 22,
        childInset: 6,
      ),
      OurnegoIconButtonSize.s48 => const OurnegoIconButtonMetrics(
        side: 48,
        lipDepth: 4,
        iconSize: 22,
        childInset: 5,
      ),
      OurnegoIconButtonSize.s44 => const OurnegoIconButtonMetrics(
        side: 44,
        lipDepth: 3,
        iconSize: 22,
        childInset: 5,
      ),
      OurnegoIconButtonSize.s40 => const OurnegoIconButtonMetrics(
        side: 40,
        lipDepth: 3,
        iconSize: 20,
        childInset: 5,
      ),
      OurnegoIconButtonSize.s32 => const OurnegoIconButtonMetrics(
        side: 32,
        lipDepth: 3,
        iconSize: 18,
        childInset: 4,
      ),
      OurnegoIconButtonSize.s28 => const OurnegoIconButtonMetrics(
        side: 28,
        lipDepth: 2,
        iconSize: 16,
        childInset: 4,
      ),
    };
  }
}

/// Other component metrics (spec §3.5).
class OurnegoComponentMetrics {
  OurnegoComponentMetrics._();

  static const double minTapTarget = 48;
  static const double borderWidth = 1;
  static const double focusRingWidth = 3;
  static const double focusRingGap = 3;

  static const double chipHeight = 40;
  static const double chipLip = 3;
  static const double chipRadius = OurnegoRadiusTokens.pill;
  static const double chipHorizontalPadding = 16;
  static const double chipGap = 6;
  static const double chipIconSize = 18;
  static const double chipTrailingIconSize = 22;

  static const double rowHeight = 58;
  static const double rowRadius = OurnegoRadiusTokens.xl;
  static const double rowLip = 4;
  static const double rowPaddingLeft = 10;
  static const double rowPaddingRight = 12;
  static const double rowAccentSize = 36;
  static const double rowAccentIconSize = 20;
  static const double rowChevronSize = 26;

  static const double actionHeight = 42;
  static const double actionRadius = OurnegoRadiusTokens.md;
  static const double actionLip = 3;
  static const double actionIconSize = 22;

  static const double tileMinHeight = 76;
  static const double tileRadius = OurnegoRadiusTokens.md;
  static const double tileLip = 3;
  static const double tileIconSize = 22;
  static const double tileGap = 6;
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(
    vertical: 10,
    horizontal: 4,
  );

  static const double socialHeight = 50;
  static const double socialRadius = OurnegoRadiusTokens.button;
  static const double socialLip = 4;
  static const double socialSide = 26;
  static const double socialSideWithBadge = 56;
  static const double socialIconSize = 22;

  static const double glassIconSide = 52;
  static const double glassIconSize = 22;
  static const double glassChildInset = 6;
  static const double glassSurfaceHeight = 52;
  static const double glassChipHeight = 40;
  static const double glassChipPadding = 16;
  static const double glassChipGap = 6;
  static const double glassChipPinSize = 19;
  static const double focusGlowWidth = 3;

  static const double navPadding = 8;
  static const double navItemSize = 56;
  static const double navIconSize = 30;
}
