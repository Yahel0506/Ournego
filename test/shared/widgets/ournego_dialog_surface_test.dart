import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/navigation/presentation/widgets/profile_menu/profile_menu_dialog_widget.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_dialog_surface.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';
import 'package:ournego/shared/widgets/ournego_information_dialog.dart';

Widget _app(Widget child, {Brightness brightness = Brightness.light}) =>
    ProviderScope(
      overrides: [authSessionStatusProvider.overrideWithValue(false)],
      child: MaterialApp(
        theme: brightness == Brightness.light
            ? OurnegoTheme.light
            : OurnegoTheme.dark,
        home: Scaffold(body: child),
      ),
    );

void main() {
  group('OurnegoDialogSurface is flat glass', () {
    for (final brightness in Brightness.values) {
      testWidgets('flat face and visible contour in $brightness', (
        tester,
      ) async {
        await tester.pumpWidget(
          _app(
            const OurnegoDialogSurface(child: Text('hola')),
            brightness: brightness,
          ),
        );
        final scheme = Theme.of(tester.element(find.text('hola'))).colorScheme;
        final container = tester.widget<OurnegoContentContainer>(
          find.byType(OurnegoContentContainer),
        );

        // Same face and contour as the navigation bar.
        expect(container.hasBlur, isFalse);
        expect(container.backgroundColor, OurnegoGlassPalette.navFace(scheme));
        expect(
          container.backgroundColor!.a,
          1,
          reason: 'flat, not translucent',
        );
        expect(container.borderColor, OurnegoGlassPalette.border(scheme));
        expect(container.borderRadius, 24);
        expect(find.byType(BackdropFilter), findsNothing);
      });
    }

    testWidgets('only the content is blurred in transit, not the surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(const OurnegoDialogSurface(child: Text('hola'))),
      );
      // The blur sits inside the surface...
      expect(
        find.descendant(
          of: find.byType(OurnegoContentContainer),
          matching: find.byType(ContainerTransformBlur),
        ),
        findsOneWidget,
      );
      // ...never around it.
      expect(
        find.ancestor(
          of: find.byType(OurnegoContentContainer),
          matching: find.byType(ContainerTransformBlur),
        ),
        findsNothing,
      );
    });
  });

  group('every dialog uses it', () {
    testWidgets('alert dialog', (tester) async {
      await tester.pumpWidget(
        _app(
          OurnegoAlertDialog(
            title: 'Título',
            content: 'Contenido',
            primaryAction: OurnegoDialogAction(label: 'Ok', onPressed: () {}),
          ),
        ),
      );
      expect(find.byType(OurnegoDialogSurface), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('information dialog', (tester) async {
      await tester.pumpWidget(
        _app(
          OurnegoInformationDialog(
            title: 'Título',
            description: 'Descripción',
            imagePath: 'assets/images/generic_error.png',
            actions: const SizedBox(height: 10),
          ),
        ),
      );
      expect(find.byType(OurnegoDialogSurface), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('form dialog', (tester) async {
      await tester.pumpWidget(
        _app(
          OurnegoFormDialog(
            title: 'Título',
            primaryAction: OurnegoDialogAction(label: 'Ok', onPressed: () {}),
            child: const Text('cuerpo'),
          ),
        ),
      );
      expect(find.byType(OurnegoDialogSurface), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('profile menu', (tester) async {
      await tester.pumpWidget(_app(const ProfileMenuDialogWidget()));
      expect(find.byType(OurnegoDialogSurface), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });
  });
}
