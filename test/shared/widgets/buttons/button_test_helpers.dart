import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/buttons/ournego_pressable.dart';

/// Pumps [child] centered in a themed app.
Future<void> pumpButton(
  WidgetTester tester,
  Widget child, {
  ThemeData? theme,
  bool disableAnimations = false,
  double width = 400,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OurnegoTheme.light,
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(800, 600),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Transform of the first pressable face under [of] (or anywhere).
Matrix4 faceTransform(WidgetTester tester, {Finder? of}) {
  final finder = find.byKey(ournegoPressableFaceKey);
  final target = of == null
      ? finder.first
      : find.descendant(of: of, matching: finder).first;
  return tester.widget<Transform>(target).transform;
}

double faceDy(WidgetTester tester, {Finder? of}) =>
    faceTransform(tester, of: of).getTranslation().y;

double faceScaleX(WidgetTester tester, {Finder? of}) =>
    faceTransform(tester, of: of).storage[0];

/// WCAG relative luminance.
double luminance(Color c) {
  double channel(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * channel(c.r) + 0.7152 * channel(c.g) + 0.0722 * channel(c.b);
}

double contrast(Color a, Color b) {
  final la = luminance(a);
  final lb = luminance(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

/// Compares two colors with a tolerance of ±[tolerance] per 8-bit channel.
Matcher closeToColor(Color expected, {int tolerance = 1}) {
  return predicate<Color>((actual) {
    final a = actual.toARGB32();
    final e = expected.toARGB32();
    for (var shift = 0; shift <= 24; shift += 8) {
      final da = (a >> shift) & 0xFF;
      final de = (e >> shift) & 0xFF;
      if ((da - de).abs() > tolerance) return false;
    }
    return true;
  }, 'color close to 0x${expected.toARGB32().toRadixString(16)}');
}

/// The BoxDecoration of the first pressable face under [of].
BoxDecoration faceDecoration(WidgetTester tester, {Finder? of}) {
  final faceFinder = of == null
      ? find.byKey(ournegoPressableFaceKey).first
      : find
            .descendant(of: of, matching: find.byKey(ournegoPressableFaceKey))
            .first;
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: faceFinder, matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}
