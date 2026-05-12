import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/widgets/nego/nego_avatar.dart';

void main() {
  testWidgets('renders and reacts to tap', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: NegoAvatar(
              size: 256,
              interactive: true,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(CustomPaint).first);
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('builds as decorative content when interaction is disabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: NegoAvatar(
              size: 220,
              interactive: false,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(NegoAvatar), findsOneWidget);
  });
}
