import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/debugging/presentation/pages/debug_panel_screen.dart';
import 'package:ournego/core/motion/ournego_motion_level.dart';

void main() {
  tearDown(() => OurnegoMotion.containerTransformEnabled.value = true);

  testWidgets('the switch turns the container transform off and on', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: DebugPanel())),
    );
    final tile = find.byKey(const ValueKey('debugContainerTransformSwitch'));
    expect(tester.widget<SwitchListTile>(tile).value, isTrue);

    await tester.tap(tile);
    await tester.pump();
    expect(OurnegoMotion.containerTransformEnabled.value, isFalse);
    expect(tester.widget<SwitchListTile>(tile).value, isFalse);

    await tester.tap(tile);
    await tester.pump();
    expect(OurnegoMotion.containerTransformEnabled.value, isTrue);
  });
}
