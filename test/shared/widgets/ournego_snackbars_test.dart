import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  for (final entry in {
    'light': OurnegoTheme.light,
    'dark': OurnegoTheme.dark,
  }.entries) {
    testWidgets('snackbar text is themed and readable in ${entry.key} mode', (
      tester,
    ) async {
      final theme = entry.value;
      final snackbars = <SnackBar Function(BuildContext)>[
        (c) => OurnegoSnackbars.error(c, 'error msg'),
        (c) => OurnegoSnackbars.info(c, 'info msg'),
        (c) => OurnegoSnackbars.success(c, 'success msg'),
        (c) => OurnegoSnackbars.warning(c, 'warning msg'),
      ];
      final messages = ['error msg', 'info msg', 'success msg', 'warning msg'];

      late BuildContext ctx;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (c) {
                ctx = c;
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      for (var i = 0; i < snackbars.length; i++) {
        ScaffoldMessenger.of(ctx).showSnackBar(snackbars[i](ctx));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));
        final text = tester.widget<Text>(find.text(messages[i]));
        final color = text.style!.color!;
        expect(color, theme.colorScheme.onSurface);
        expect(
          _contrast(color, theme.scaffoldBackgroundColor),
          greaterThanOrEqualTo(4.5),
        );
        ScaffoldMessenger.of(ctx).hideCurrentSnackBar();
        await tester.pumpAndSettle();
      }
    });
  }
}
