import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/sheet_header.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_map_repository.dart';
import '../../../helpers/app_helper.dart';

final _business = Business(
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

/// Only the expanded content has this row.
final _expandedMarker = find.text('Opinión general');
final _sheet = find.byType(SheetHeader);
const _scrimSpot = Offset(5, 300);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _openSheet(WidgetTester tester) async {
  final repository = FakeMapRepository(
    initialBusinesses: [_business],
    businessById: {_business.id: _business},
  );
  final overrides = <Override>[
    ...mapOverrides(repository, mapTilesEnabled: false),
    ...authOverrides(
      FakeAuthRepository(state: FakeAuthState.unauthenticated),
      initialSessionStatus: false,
    ),
  ];
  await tester.pumpWidget(
    buildTestApp(
      overrides,
      startOnMap: true,
      initialLocation: '/negocio/${_business.id}',
    ),
  );
  await _settle(tester);
  expect(_sheet, findsOneWidget);
  expect(_expandedMarker, findsNothing);
}

Future<void> _expand(WidgetTester tester) async {
  await tester.fling(_sheet, const Offset(0, -300), 1500);
  await _settle(tester);
  expect(_expandedMarker, findsOneWidget);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('floating sheet back', () {
    testWidgets('tapping the scrim collapses an expanded sheet', (
      tester,
    ) async {
      await _openSheet(tester);
      await _expand(tester);

      await tester.tapAt(_scrimSpot);
      await _settle(tester);

      expect(_expandedMarker, findsNothing);
      expect(_sheet, findsOneWidget);
    });

    testWidgets('back collapses first and closes on the second press', (
      tester,
    ) async {
      await _openSheet(tester);
      await _expand(tester);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(_expandedMarker, findsNothing);
      expect(_sheet, findsOneWidget);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(_sheet, findsNothing);
    });

    testWidgets('a collapsed sheet does not react to taps outside it', (
      tester,
    ) async {
      await _openSheet(tester);

      await tester.tapAt(_scrimSpot);
      await _settle(tester);

      expect(_sheet, findsOneWidget);
    });
  });
}
