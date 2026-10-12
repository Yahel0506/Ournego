import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_map_repository.dart';
import '../../../helpers/app_helper.dart';

const _sheetNego = Key('location-access-nego');
const _sheetPrimary = Key('location-access-primary');
const _sheetContinue = Key('location-access-continue');
const _banner = Key('map-location-banner');
const _bannerAction = Key('map-location-banner-action');

Future<void> _pumpMap(WidgetTester tester, FakeMapRepository repository) async {
  final overrides = <Override>[
    ...mapOverrides(repository, mapTilesEnabled: false),
    ...authOverrides(
      FakeAuthRepository(state: FakeAuthState.unauthenticated),
      initialSessionStatus: false,
    ),
  ];

  await tester.pumpWidget(buildTestApp(overrides, startOnMap: true));
  await _settle(tester);
}

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void _expectNoDeadEnds(WidgetTester tester) {
  expect(find.byType(CircularProgressIndicator), findsNothing);
  expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('granted', () {
    testWidgets('shows neither sheet nor banner', (tester) async {
      final repository = FakeMapRepository();
      await _pumpMap(tester, repository);

      expect(find.byKey(_sheetNego), findsNothing);
      expect(find.byKey(_banner), findsNothing);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      _expectNoDeadEnds(tester);
    });
  });

  group('permission revoked / denied (can ask again)', () {
    FakeMapRepository denied({LocationAccessStatus? afterRequest}) {
      return FakeMapRepository()..setAccessStatus(
        LocationAccessStatus.permissionDenied,
        afterPermissionRequest: afterRequest,
      );
    }

    testWidgets('opens Nego sheet without prompting the system', (
      tester,
    ) async {
      final repository = denied();
      await _pumpMap(tester, repository);

      expect(find.byKey(_sheetNego), findsOneWidget);
      expect(find.text('Permitir'), findsWidgets);
      expect(find.text('Continuar sin ubicación'), findsOneWidget);
      expect(repository.permissionRequestCount, 0);
      _expectNoDeadEnds(tester);
    });

    testWidgets('continuing without location leaves the banner', (
      tester,
    ) async {
      final repository = denied();
      await _pumpMap(tester, repository);

      await tester.tap(find.byKey(_sheetContinue));
      await _settle(tester);

      expect(find.byKey(_sheetNego), findsNothing);
      expect(find.byKey(_banner), findsOneWidget);
      expect(find.text('Ournego no puede ver tu ubicación'), findsOneWidget);
      expect(find.byIcon(Icons.location_disabled_rounded), findsWidgets);
      expect(repository.permissionRequestCount, 0);
      _expectNoDeadEnds(tester);
    });

    testWidgets('allowing grants access and clears the banner', (tester) async {
      final repository = denied(afterRequest: LocationAccessStatus.granted);
      await _pumpMap(tester, repository);

      await tester.tap(find.byKey(_sheetPrimary));
      await _settle(tester);

      expect(repository.permissionRequestCount, 1);
      expect(find.byKey(_sheetNego), findsNothing);
      expect(find.byKey(_banner), findsNothing);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      _expectNoDeadEnds(tester);
    });

    testWidgets('the banner action asks for the permission', (tester) async {
      final repository = denied(afterRequest: LocationAccessStatus.granted);
      await _pumpMap(tester, repository);
      await tester.tap(find.byKey(_sheetContinue));
      await _settle(tester);

      await tester.tap(find.byKey(_bannerAction));
      await _settle(tester);

      expect(repository.permissionRequestCount, 1);
      expect(find.byKey(_banner), findsNothing);
      _expectNoDeadEnds(tester);
    });

    testWidgets('tapping my location reopens the sheet', (tester) async {
      final repository = denied();
      await _pumpMap(tester, repository);
      await tester.tap(find.byKey(_sheetContinue));
      await _settle(tester);

      await tester.tap(find.byIcon(Icons.location_disabled_rounded).last);
      await _settle(tester);

      expect(find.byKey(_sheetNego), findsOneWidget);
      _expectNoDeadEnds(tester);
    });

    testWidgets('rejecting the system dialog for good moves to settings', (
      tester,
    ) async {
      final repository = denied(
        afterRequest: LocationAccessStatus.permissionDeniedForever,
      );
      await _pumpMap(tester, repository);

      await tester.tap(find.byKey(_sheetPrimary));
      await _settle(tester);

      expect(find.byKey(_sheetNego), findsOneWidget);
      expect(find.text('Abrir ajustes'), findsOneWidget);
      expect(find.byKey(_banner), findsOneWidget);
      _expectNoDeadEnds(tester);
    });
  });

  group('permission denied for good', () {
    testWidgets('offers settings or continuing, never a dead end', (
      tester,
    ) async {
      final repository = FakeMapRepository()
        ..setAccessStatus(LocationAccessStatus.permissionDeniedForever);
      await _pumpMap(tester, repository);

      expect(find.byKey(_sheetNego), findsOneWidget);
      expect(find.text('Abrir ajustes'), findsOneWidget);

      await tester.tap(find.byKey(_sheetContinue));
      await _settle(tester);

      expect(find.byKey(_banner), findsOneWidget);
      expect(find.text('Ajustes'), findsOneWidget);
      _expectNoDeadEnds(tester);
    });
  });

  group('GPS off', () {
    testWidgets('accepting the native dialog recovers the position', (
      tester,
    ) async {
      final repository = FakeMapRepository()
        ..setAccessStatus(LocationAccessStatus.serviceDisabled);
      await _pumpMap(tester, repository);

      expect(repository.lastResolveServiceIfDisabled, isTrue);
      expect(find.byKey(_sheetNego), findsNothing);
      expect(find.byKey(_banner), findsNothing);
      _expectNoDeadEnds(tester);
    });

    testWidgets('declining it leaves a banner with an activate action', (
      tester,
    ) async {
      final repository = FakeMapRepository()
        ..setAccessStatus(LocationAccessStatus.serviceDisabled)
        ..setLocationResult(Left(LocationServiceDisabledFailure()));
      await _pumpMap(tester, repository);

      expect(find.byKey(_banner), findsOneWidget);
      expect(find.text('Tu GPS está apagado'), findsOneWidget);

      repository.lastResolveServiceIfDisabled = null;
      await tester.tap(find.byKey(_bannerAction));
      await _settle(tester);

      expect(repository.lastResolveServiceIfDisabled, isTrue);
      expect(find.byKey(_banner), findsOneWidget);
      _expectNoDeadEnds(tester);
    });

    testWidgets('does not ask twice when the system dialog was declined', (
      tester,
    ) async {
      // Location service on, but the position request itself surfaced (and
      // the user declined) the system dialog.
      final repository = FakeMapRepository(
        locationResult: Left(LocationServiceDisabledFailure()),
      );
      await _pumpMap(tester, repository);

      expect(repository.locationRequestCount, 1);
      expect(find.byKey(_banner), findsOneWidget);
      _expectNoDeadEnds(tester);
    });

    testWidgets('switching GPS off while open asks to turn it back on', (
      tester,
    ) async {
      final repository = FakeMapRepository();
      await _pumpMap(tester, repository);
      expect(find.byKey(_banner), findsNothing);

      // The user declines the native dialog this time.
      repository.setLocationResult(Left(LocationServiceDisabledFailure()));
      repository.emitServiceStatus(enabled: false);
      await _settle(tester);

      expect(repository.lastResolveServiceIfDisabled, isTrue);
      expect(find.byKey(_banner), findsOneWidget);
      expect(find.text('Tu GPS está apagado'), findsOneWidget);

      // Turning it on from the quick settings recovers without any action.
      repository.setLocationResult(
        const Right(AppPosition(latitude: 19.7, longitude: -103.46)),
      );
      repository.emitServiceStatus(enabled: true);
      await _settle(tester);

      expect(find.byKey(_banner), findsNothing);
      _expectNoDeadEnds(tester);
    });
  });
}
