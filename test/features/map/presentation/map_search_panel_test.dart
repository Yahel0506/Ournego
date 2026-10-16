import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/widgets/search_morph_surface.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_map_repository.dart';
import '../../../helpers/app_helper.dart';

// The panel stays mounted while hidden, so "open" means "reachable by touch".
Finder _panel() => find.byTooltip('Cerrar búsqueda').hitTestable();

Business _business() => Business(
  id: 'biz-1',
  name: 'Panaderia Sol',
  description: 'Pan fresco todo el dia.',
  ownerId: 'owner-1',
  address: 'Av. Principal 123',
  phoneNumber: '521234567890',
  latitude: 19.4326,
  longitude: -99.1332,
  type: BusinessType.drinkAndEat,
  images: const [],
  visitCount: 0,
  hours: const [],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pumpMap(WidgetTester tester) async {
  final repository = FakeMapRepository();
  final overrides = <Override>[
    ...mapOverrides(repository, mapTilesEnabled: false),
    ...authOverrides(
      FakeAuthRepository(state: FakeAuthState.unauthenticated),
      initialSessionStatus: false,
    ),
  ];
  await tester.pumpWidget(buildTestApp(overrides, startOnMap: true));
  await _settle(tester);
  // The fake's broadcast stream only reaches listeners that already exist.
  repository.setBusinesses([_business()]);
  await _settle(tester);
}

String _barText(WidgetTester tester) =>
    tester.widget<SearchBar>(find.byType(SearchBar)).controller!.text;

Future<void> _openPanel(WidgetTester tester) async {
  await tester.tap(find.byType(SearchBar));
  await _settle(tester);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(SearchBar), text);
  await _settle(tester);
}

/// A point of the map that no panel, control or bar covers.
const _mapSpot = Offset(4, 400);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('search panel', () {
    testWidgets('focusing the bar opens the panel', (tester) async {
      await _pumpMap(tester);
      expect(_panel(), findsNothing);

      await _openPanel(tester);
      expect(_panel(), findsOneWidget);
    });

    testWidgets('typing shows results for the query', (tester) async {
      await _pumpMap(tester);
      await _openPanel(tester);
      await _type(tester, 'pan');

      expect(find.text('Panaderia Sol'), findsWidgets);
    });

    testWidgets('Esc closes the panel and keeps the text', (tester) async {
      await _pumpMap(tester);
      await _openPanel(tester);
      await _type(tester, 'pan');

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);

      expect(_barText(tester), 'pan');
      expect(_panel(), findsNothing);
    });

    testWidgets('tapping the bar again brings the panel back', (tester) async {
      await _pumpMap(tester);
      await _openPanel(tester);
      await _type(tester, 'pan');
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);

      await tester.tap(find.byType(SearchBar));
      await _settle(tester);

      expect(_panel(), findsOneWidget);
      expect(_barText(tester), 'pan');
    });

    testWidgets('system back closes the panel and keeps the text', (
      tester,
    ) async {
      await _pumpMap(tester);
      await _openPanel(tester);
      await _type(tester, 'pan');

      await tester.binding.handlePopRoute();
      await _settle(tester);

      expect(_panel(), findsNothing);
      expect(_barText(tester), 'pan');
    });

    testWidgets('tapping the map closes the panel and keeps the text', (
      tester,
    ) async {
      await _pumpMap(tester);
      await _openPanel(tester);
      await _type(tester, 'pan');

      await tester.tapAt(_mapSpot);
      await _settle(tester);

      expect(_panel(), findsNothing);
      expect(_barText(tester), 'pan');
    });

    testWidgets('the close button hides the panel and clears the text', (
      tester,
    ) async {
      await _pumpMap(tester);
      await _openPanel(tester);
      await _type(tester, 'pan');

      await tester.tap(_panel());
      await _settle(tester);

      expect(_panel(), findsNothing);
      expect(_barText(tester), isEmpty);
    });

    testWidgets('the panel grows out of the bar and settles on its frame', (
      tester,
    ) async {
      await _pumpMap(tester);
      final bar = tester.getRect(find.byType(SearchBar));
      await _openPanel(tester);

      final panel = tester.getRect(find.byKey(SearchMorphSurface.frameKey));
      expect(panel.height, greaterThan(bar.height));
      expect(panel.top, greaterThan(bar.bottom));
      expect(panel.width, greaterThan(bar.width));
    });

    testWidgets(
      'the bar keeps keyboard focus while the panel opens and closes',
      (tester) async {
        await _pumpMap(tester);
        await tester.tap(find.byType(SearchBar));
        await tester.pump(const Duration(milliseconds: 16));
        expect(_barHasFocus(tester), isTrue);

        await tester.pump(const Duration(milliseconds: 200));
        expect(_barHasFocus(tester), isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump(const Duration(milliseconds: 16));
        expect(_barHasFocus(tester), isFalse);
        await _settle(tester);
      },
    );

    testWidgets('the close button keeps the query until the panel has closed', (
      tester,
    ) async {
      await _pumpMap(tester);
      await _openPanel(tester);
      await _type(tester, 'pan');

      await tester.tap(_panel());
      await tester.pump(const Duration(milliseconds: 16));
      expect(_barText(tester), 'pan');

      await _settle(tester);
      expect(_barText(tester), isEmpty);
    });

    testWidgets('choosing a result keeps the query in the bar', (tester) async {
      await _pumpMap(tester);
      await _openPanel(tester);
      await _type(tester, 'pan');

      await tester.tap(find.widgetWithText(ListTile, 'Panaderia Sol'));
      await _settle(tester);

      expect(_panel(), findsNothing);
      expect(_barText(tester), 'pan');
    });
  });
}

bool _barHasFocus(WidgetTester tester) =>
    tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus;
