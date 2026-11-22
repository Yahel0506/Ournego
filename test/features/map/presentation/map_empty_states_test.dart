import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/map/presentation/models/map_search_models.dart';
import 'package:ournego/features/map/presentation/widgets/map_search_overlay_widget.dart';

void main() {
  Widget panel({
    required bool hasData,
    required bool loadFailed,
    required VoidCallback onClear,
    required VoidCallback onRetry,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: MapSearchOverlayWidget(
          results: const [],
          query: 'café',
          hasData: hasData,
          loadFailed: loadFailed,
          onRetry: onRetry,
          location: null,
          filters: const MapSearchFilters(),
          categoryOptions: const [],
          distanceOptionsMeters: const [],
          onClear: onClear,
          onClose: () {},
          onOpenNowChanged: (_) {},
          onCategoryChanged: (_) {},
          onDistanceChanged: (_) {},
          onBusinessSelected: (_, _) {},
        ),
      ),
    );
  }

  testWidgets('empty search explains the result and clears the search', (
    tester,
  ) async {
    var cleared = false;
    await tester.pumpWidget(
      panel(
        hasData: true,
        loadFailed: false,
        onClear: () => cleared = true,
        onRetry: () {},
      ),
    );
    expect(find.textContaining('No encontramos coincidencias'), findsOneWidget);
    await tester.tap(find.text('Limpiar búsqueda'));
    expect(cleared, isTrue);
  });

  testWidgets('failed search offers a retry instead of a loading indicator', (
    tester,
  ) async {
    var retried = false;
    await tester.pumpWidget(
      panel(
        hasData: false,
        loadFailed: true,
        onClear: () {},
        onRetry: () => retried = true,
      ),
    );
    expect(
      find.textContaining('No pudimos cargar los negocios'),
      findsOneWidget,
    );
    await tester.tap(find.text('Reintentar'));
    expect(retried, isTrue);
  });
}
