import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_hours.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_manual_zone_repository.dart';
import '../../../fakes/fake_map_repository.dart';
import '../../../helpers/app_helper.dart';

const _chip = Key('zone-chip');
const _sheetPrimary = Key('location-access-primary');
const _sheetSecondary = Key('location-access-secondary');
const _pickerField = Key('zone-picker-field');
const _useCenter = Key('zone-picker-use-map-center');
const _clearZone = Key('zone-picker-clear');

const _centro = ManualZone(
  position: AppPosition(latitude: 19.71, longitude: -103.47),
  label: 'Col. Centro',
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pumpMap(
  WidgetTester tester, {
  required FakeMapRepository repository,
  required FakeManualZoneRepository zones,
}) async {
  final overrides = <Override>[
    ...mapOverrides(repository, mapTilesEnabled: false, zoneRepository: zones),
    ...authOverrides(
      FakeAuthRepository(state: FakeAuthState.unauthenticated),
      initialSessionStatus: false,
    ),
  ];
  await tester.pumpWidget(buildTestApp(overrides, startOnMap: true));
  await _settle(tester);
}

FakeMapRepository _blockedForGood() =>
    FakeMapRepository()
      ..setAccessStatus(LocationAccessStatus.permissionDeniedForever);

Future<void> _openPickerFromSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(_sheetPrimary));
  await _settle(tester);
  expect(find.byKey(_pickerField), findsOneWidget);
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byKey(_pickerField), text);
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('blocked permission offers a zone or the settings', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      repository: _blockedForGood(),
      zones: FakeManualZoneRepository(),
    );

    expect(find.text('Elegir mi zona'), findsOneWidget);
    expect(find.text('Abrir ajustes'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('choosing a zone turns the same sheet into the picker', (
    tester,
  ) async {
    await _pumpMap(
      tester,
      repository: _blockedForGood(),
      zones: FakeManualZoneRepository(),
    );
    const handle = Key('sheet-drag-handle');
    expect(find.byKey(handle), findsOneWidget);

    await tester.tap(find.text('Elegir mi zona'));
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.byKey(handle), findsOneWidget, reason: 'not a second sheet');

    await _settle(tester);
    expect(find.byKey(handle), findsOneWidget);
    expect(find.byKey(_pickerField), findsOneWidget);
    expect(find.byKey(const Key('location-access-primary')), findsNothing);
  });

  testWidgets('choosing a searched zone sets it, saves it and shows the chip', (
    tester,
  ) async {
    final zones = FakeManualZoneRepository()..searchResults = const [_centro];
    await _pumpMap(tester, repository: _blockedForGood(), zones: zones);
    await _openPickerFromSheet(tester);

    await _type(tester, 'centro');
    expect(find.byKey(const ValueKey('zone-suggestion-0')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('zone-suggestion-0')));
    await _settle(tester);

    expect(find.byKey(_pickerField), findsNothing);
    expect(find.text('Zona: Col. Centro'), findsOneWidget);
    expect(zones.savedZone?.label, 'Col. Centro');
  });

  testWidgets('using the map center names the zone after that point', (
    tester,
  ) async {
    final zones = FakeManualZoneRepository();
    await _pumpMap(tester, repository: _blockedForGood(), zones: zones);
    await _openPickerFromSheet(tester);

    await tester.tap(find.byKey(_useCenter));
    await _settle(tester);

    expect(find.text('Zona: Zona seleccionada en el mapa'), findsOneWidget);
    expect(zones.savedZone, isNotNull);
  });

  testWidgets('short queries do not search and offline explains itself', (
    tester,
  ) async {
    final zones = FakeManualZoneRepository()..searchFailure = NetworkFailure();
    await _pumpMap(tester, repository: _blockedForGood(), zones: zones);
    await _openPickerFromSheet(tester);

    await _type(tester, 'ce');
    expect(zones.searchedQueries, isEmpty);
    expect(find.text('Escribe al menos 3 letras para buscar.'), findsOneWidget);

    await _type(tester, 'centro');
    expect(zones.searchedQueries, ['centro']);
    expect(find.byKey(const Key('zone-picker-offline')), findsOneWidget);
    // The alternative that needs no network is still there.
    expect(find.byKey(_useCenter), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('an unknown zone says so', (tester) async {
    final zones = FakeManualZoneRepository();
    await _pumpMap(tester, repository: _blockedForGood(), zones: zones);
    await _openPickerFromSheet(tester);

    await _type(tester, 'zzzzz');

    expect(find.byKey(const Key('zone-picker-empty')), findsOneWidget);
  });

  testWidgets('a server error says so', (tester) async {
    final zones = FakeManualZoneRepository()..searchFailure = ServerFailure();
    await _pumpMap(tester, repository: _blockedForGood(), zones: zones);
    await _openPickerFromSheet(tester);

    await _type(tester, 'centro');

    expect(find.byKey(const Key('zone-picker-failed')), findsOneWidget);
  });

  testWidgets('typing quickly only searches the last text', (tester) async {
    final zones = FakeManualZoneRepository()..searchResults = const [_centro];
    await _pumpMap(tester, repository: _blockedForGood(), zones: zones);
    await _openPickerFromSheet(tester);

    await tester.enterText(find.byKey(_pickerField), 'cen');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byKey(_pickerField), 'centro');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 100));

    expect(zones.searchedQueries, ['centro']);
  });

  testWidgets('a saved zone shows in the chip and can be removed', (
    tester,
  ) async {
    final zones = FakeManualZoneRepository(savedZone: _centro);
    await _pumpMap(tester, repository: _blockedForGood(), zones: zones);
    // Dismiss the sheet shown on startup by tapping outside of it.
    await tester.tapAt(const Offset(10, 10));
    await _settle(tester);

    expect(find.text('Zona: Col. Centro'), findsOneWidget);

    await tester.tap(find.byKey(_chip));
    await _settle(tester);
    await tester.tap(find.byKey(_clearZone));
    await _settle(tester);

    expect(find.text('Zona: Ciudad Guzmán'), findsOneWidget);
    expect(zones.savedZone, isNull);
  });

  testWidgets('continuing without location falls back to the default zone', (
    tester,
  ) async {
    final repository = FakeMapRepository()
      ..setAccessStatus(LocationAccessStatus.permissionDenied);
    await _pumpMap(
      tester,
      repository: repository,
      zones: FakeManualZoneRepository(),
    );

    await tester.tap(find.byKey(_sheetSecondary));
    await _settle(tester);

    expect(find.text('Zona: Ciudad Guzmán'), findsOneWidget);
    expect(find.text('Registra tu negocio y crece.'), findsNothing);
  });

  testWidgets('the chip is hidden while the GPS works', (tester) async {
    await _pumpMap(
      tester,
      repository: FakeMapRepository(),
      zones: FakeManualZoneRepository(savedZone: _centro),
    );

    expect(find.byKey(_chip), findsNothing);
  });

  testWidgets('search results say which zone distances come from', (
    tester,
  ) async {
    final business = Business(
      id: 'biz-1',
      name: 'Panaderia Sol',
      description: 'Pan fresco todo el dia.',
      ownerId: 'owner-1',
      address: 'Av. Principal 123',
      phoneNumber: '521234567890',
      latitude: 19.7,
      longitude: -103.46,
      type: BusinessType.drinkAndEat,
      images: const [],
      visitCount: 0,
      hours: const <BusinessHours>[],
    );
    final repository = FakeMapRepository()
      ..setAccessStatus(LocationAccessStatus.permissionDenied);
    await _pumpMap(
      tester,
      repository: repository,
      zones: FakeManualZoneRepository(),
    );
    // The fake's broadcast stream drops values emitted before listening.
    repository.setBusinesses([business]);
    await tester.tap(find.byKey(_sheetSecondary));
    await _settle(tester);

    await tester.tap(find.byType(SearchBar));
    await _settle(tester);
    await tester.enterText(find.byType(SearchBar), 'Panaderia');
    await _settle(tester);

    expect(find.text('Distancias desde: Ciudad Guzmán'), findsOneWidget);
  });
}
