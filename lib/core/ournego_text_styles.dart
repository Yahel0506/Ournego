import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';

class OurnegoTextStyles {
  static const TextStyle display = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.08,
  );
  static const TextStyle headline = TextStyle(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.12,
  );
  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.15,
  );
  static const TextStyle sheetTitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    height: 1.18,
  );
  static const TextStyle body = TextStyle(fontSize: 16, height: 1.35);
  static const TextStyle bodyCompact = TextStyle(fontSize: 14, height: 1.28);
  static const TextStyle caption = TextStyle(fontSize: 12, height: 1.2);
  static const TextStyle badge = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.1,
  );
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 0.08,
  );
  static const TextStyle buttonLarge = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 0.08,
  );
  static const TextStyle buttonCompact = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 0.08,
  );
  static const TextStyle buttonSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 1.1,
    letterSpacing: 0.08,
  );
  static const TextStyle buttonTile = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.1,
  );
  static const TextStyle error = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: OurnegoColorTokens.error,
    height: 1.2,
  );
  static const TextStyle onboardingHeader = display;
  static const TextStyle header = title;
  static const TextStyle link = TextStyle(
    fontSize: 16,
    decoration: TextDecoration.underline,
    height: 1.2,
  );
  static const TextStyle errorText = error;
}
