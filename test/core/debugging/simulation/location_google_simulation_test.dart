import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/debugging/presentation/pages/debug_panel_screen.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/core/debugging/simulation/simulated_auth_datasource.dart';
import 'package:ournego/core/debugging/simulation/simulated_location_datasource.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/location/location_exceptions.dart';
import 'package:ournego/features/auth/data/repositories/supabase_auth_repository_impl.dart';

class _RealLocation implements LocationDatasource {
  final events = <bool>[];
  @override
  Future<LocationAccessStatus> checkAccessStatus() async =>
      LocationAccessStatus.serviceDisabled;
  @override
  Future<LocationAccessStatus> requestPermission() async =>
      LocationAccessStatus.permissionDenied;
  @override
  Stream<bool> serviceStatusStream() => const Stream.empty();
  @override
  Future<AppPosition> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
    bool resolveServiceIfDisabled = false,
  }) async => const AppPosition(latitude: 1, longitude: 2);
}

DebugSimulationController _with(LocationMode mode) =>
    DebugSimulationController(initial: DebugSimulation(locationMode: mode));

SimulatedLocationDatasource _datasource(DebugSimulationController c) =>
    SimulatedLocationDatasource(controller: c, real: _RealLocation());

void main() {
  group('SimulatedLocationDatasource', () {
    test('real delegates to the device datasource', () async {
      final ds = _datasource(_with(LocationMode.real));
      expect(
        await ds.checkAccessStatus(),
        LocationAccessStatus.serviceDisabled,
      );
      expect((await ds.getCurrentLocation()).latitude, 1);
    });

    test('granted reports granted and a fixed position', () async {
      final ds = _datasource(_with(LocationMode.granted));
      expect(await ds.checkAccessStatus(), LocationAccessStatus.granted);
      expect(await ds.getCurrentLocation(), same(simulatedPosition));
    });

    const statuses = {
      LocationMode.denied: LocationAccessStatus.permissionDenied,
      LocationMode.allowOnPrompt: LocationAccessStatus.permissionDenied,
      LocationMode.deniedForever: LocationAccessStatus.permissionDeniedForever,
      LocationMode.serviceDisabled: LocationAccessStatus.serviceDisabled,
      LocationMode.enableOnPrompt: LocationAccessStatus.serviceDisabled,
      LocationMode.unavailable: LocationAccessStatus.unavailable,
    };
    statuses.forEach((mode, status) {
      test('${mode.name} reports $status without prompting', () async {
        final c = _with(mode);
        expect(await _datasource(c).checkAccessStatus(), status);
        expect(c.value.locationMode, mode);
      });
    });

    test('denied rejects every request and the position throws', () async {
      final c = _with(LocationMode.denied);
      final ds = _datasource(c);
      expect(
        await ds.requestPermission(),
        LocationAccessStatus.permissionDenied,
      );
      expect(
        ds.getCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
      expect(c.value.locationMode, LocationMode.denied);
    });

    test('deniedForever and unavailable throw their own exceptions', () {
      expect(
        _datasource(_with(LocationMode.deniedForever)).getCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedForeverException>()),
      );
      expect(
        _datasource(_with(LocationMode.unavailable)).getCurrentLocation(),
        throwsA(isA<LocationUnavailableException>()),
      );
    });

    test('allowOnPrompt grants when the app asks', () async {
      final c = _with(LocationMode.allowOnPrompt);
      final ds = _datasource(c);
      expect(
        ds.getCurrentLocation(requestPermissionIfNeeded: false),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
      expect(c.value.locationMode, LocationMode.allowOnPrompt);

      expect(await ds.requestPermission(), LocationAccessStatus.granted);
      expect(c.value.locationMode, LocationMode.granted);
    });

    test('serviceDisabled rejects the native dialog', () {
      final c = _with(LocationMode.serviceDisabled);
      expect(
        _datasource(c).getCurrentLocation(resolveServiceIfDisabled: true),
        throwsA(isA<LocationServiceDisabledException>()),
      );
      expect(c.value.locationMode, LocationMode.serviceDisabled);
    });

    test(
      'enableOnPrompt turns the GPS on only when the app resolves',
      () async {
        final c = _with(LocationMode.enableOnPrompt);
        final ds = _datasource(c);
        await expectLater(
          ds.getCurrentLocation(),
          throwsA(isA<LocationServiceDisabledException>()),
        );
        expect(
          await ds.getCurrentLocation(resolveServiceIfDisabled: true),
          same(simulatedPosition),
        );
        expect(c.value.locationMode, LocationMode.granted);
      },
    );

    test('the service stream follows the simulated GPS', () async {
      final c = _with(LocationMode.granted);
      final events = <bool>[];
      final sub = _datasource(c).serviceStatusStream().listen(events.add);
      c.update(
        const DebugSimulation(locationMode: LocationMode.serviceDisabled),
      );
      c.update(const DebugSimulation(locationMode: LocationMode.granted));
      await pumpEventQueue();
      expect(events, [false, true]);
      await sub.cancel();
    });
  });

  group('Google outcomes map to the production failures', () {
    Failure failureFor(GoogleOutcome outcome) =>
        googleSignInFailureFor(simulatedGoogleErrorFor(outcome)!);

    test('real raises nothing', () {
      expect(simulatedGoogleErrorFor(GoogleOutcome.real), isNull);
    });

    test('each outcome lands on its failure', () {
      expect(
        failureFor(GoogleOutcome.canceled),
        isA<GoogleSignInCancelledFailure>(),
      );
      expect(
        failureFor(GoogleOutcome.unavailable),
        isA<GoogleSignInUnavailableFailure>(),
      );
      expect(failureFor(GoogleOutcome.network), isA<NetworkFailure>());
      expect(failureFor(GoogleOutcome.serverError), isA<ServerFailure>());
    });
  });

  test('location and Google survive a JSON round trip', () {
    const simulation = DebugSimulation(
      locationMode: LocationMode.deniedForever,
      googleOutcome: GoogleOutcome.network,
    );
    final restored = DebugSimulation.fromJson(simulation.toJson());
    expect(restored.locationMode, LocationMode.deniedForever);
    expect(restored.googleOutcome, GoogleOutcome.network);
    expect(const DebugSimulation().isActive, isFalse);
    expect(simulation.isActive, isTrue);
  });

  testWidgets('the panel picks a location mode and a Google outcome', (
    tester,
  ) async {
    final controller = DebugSimulationController();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          debugSimulationControllerProvider.overrideWithValue(controller),
        ],
        child: const MaterialApp(home: DebugPanel()),
      ),
    );
    for (final key in const [
      'debugLocationMode-deniedForever',
      'debugGoogleOutcome-canceled',
    ]) {
      final tile = find.byKey(ValueKey(key));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pump();
    }
    expect(controller.value.locationMode, LocationMode.deniedForever);
    expect(controller.value.googleOutcome, GoogleOutcome.canceled);
  });
}
