import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/presentation/widgets/zone_picker_sheet_widget.dart';

void main() {
  testWidgets(
    'with the keyboard up the zone sheet keeps its insets out of the content',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      tester.view.padding = const FakeViewPadding(top: 40, bottom: 20);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: TextButton(
                  key: const Key('open'),
                  onPressed: () => showZonePickerSheet(
                    context,
                    mapCenter: const AppPosition(latitude: 0, longitude: 0),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const Key('open')));
      await tester.pumpAndSettle();

      final handle = tester.getRect(find.byKey(const Key('sheet-drag-handle')));
      final hint = find.text('Escribe al menos 3 letras para buscar.');
      expect(hint, findsOneWidget);
      expect(tester.getSize(hint).height, greaterThan(0));
      expect(tester.takeException(), isNull);
      // Only as tall as its content: the handle is not stuck under the top.
      expect(handle.top, greaterThan(60));
    },
  );
}
