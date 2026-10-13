import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/widgets/buttons/buttons.dart';

import 'button_test_helpers.dart';

const _key = ValueKey('social');

void main() {
  for (final badge in [null, 'Pronto']) {
    testWidgets('label is centered (badge: $badge)', (tester) async {
      await pumpButton(
        tester,
        OurnegoSocialButton(
          key: _key,
          leading: const Icon(Icons.mail_rounded),
          label: 'Continuar',
          badge: badge,
          onPressed: badge == null ? () {} : null,
        ),
        width: 360,
      );

      final button = tester.getRect(find.byKey(_key));
      final label = tester.getRect(find.text('Continuar'));
      expect(label.center.dx, closeTo(button.center.dx, 1));
      if (badge != null) expect(find.text('PRONTO'), findsOneWidget);
    });
  }

  testWidgets('google uses the google asset', (tester) async {
    await pumpButton(
      tester,
      OurnegoSocialButton.google(key: _key, onPressed: () {}),
      width: 360,
    );

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/images/google.png');
    expect(find.text('Continuar con Google'), findsOneWidget);
  });
}
