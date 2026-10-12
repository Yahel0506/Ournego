import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart'
    hide LocationServiceDisabledException;
import 'package:geolocator/geolocator.dart'
    as geo
    show LocationServiceDisabledException;
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:ournego/core/location/geolocator_location_datasource.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/location/location_exceptions.dart';

class _FakeGeolocator extends GeolocatorPlatform
    with MockPlatformInterfaceMixin {
  LocationPermission permission = LocationPermission.whileInUse;
  LocationPermission permissionAfterRequest = LocationPermission.whileInUse;
  bool serviceEnabled = true;
  Object? positionError;
  int requestCount = 0;
  int positionCalls = 0;
  Duration? positionDelay;
  bool neverCompletes = false;
  final serviceController = StreamController<ServiceStatus>.broadcast();

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestCount++;
    permission = permissionAfterRequest;
    return permission;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Stream<ServiceStatus> getServiceStatusStream() => serviceController.stream;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async {
    positionCalls++;
    if (neverCompletes) return Completer<Position>().future;
    final delay = positionDelay;
    if (delay != null) await Future<void>.delayed(delay);
    final error = positionError;
    if (error != null) throw error;
    return Position(
      latitude: 19.7,
      longitude: -103.46,
      timestamp: DateTime(2026),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );
  }
}

void main() {
  late _FakeGeolocator fake;
  late GeolocatorLocationDatasource datasource;

  setUp(() {
    fake = _FakeGeolocator();
    GeolocatorPlatform.instance = fake;
    datasource = GeolocatorLocationDatasource();
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('checkAccessStatus', () {
    test('granted when permission and service are available', () async {
      expect(
        await datasource.checkAccessStatus(),
        LocationAccessStatus.granted,
      );
    });

    test('permissionDenied when denied, without prompting', () async {
      fake.permission = LocationPermission.denied;
      expect(
        await datasource.checkAccessStatus(),
        LocationAccessStatus.permissionDenied,
      );
      expect(fake.requestCount, 0);
    });

    test('permissionDeniedForever when permanently denied', () async {
      fake.permission = LocationPermission.deniedForever;
      expect(
        await datasource.checkAccessStatus(),
        LocationAccessStatus.permissionDeniedForever,
      );
    });

    test('serviceDisabled when permitted but GPS is off', () async {
      fake.serviceEnabled = false;
      expect(
        await datasource.checkAccessStatus(),
        LocationAccessStatus.serviceDisabled,
      );
    });

    test(
      'permission problems take precedence over a disabled service',
      () async {
        fake.serviceEnabled = false;
        fake.permission = LocationPermission.denied;
        expect(
          await datasource.checkAccessStatus(),
          LocationAccessStatus.permissionDenied,
        );
      },
    );

    test('unavailable when the platform fails', () async {
      fake.permission = LocationPermission.unableToDetermine;
      expect(
        await datasource.checkAccessStatus(),
        LocationAccessStatus.unavailable,
      );
    });
  });

  group('requestPermission', () {
    test('returns granted once the user accepts', () async {
      fake.permission = LocationPermission.denied;
      fake.permissionAfterRequest = LocationPermission.whileInUse;
      expect(
        await datasource.requestPermission(),
        LocationAccessStatus.granted,
      );
      expect(fake.requestCount, 1);
    });

    test('returns permissionDenied when the user rejects', () async {
      fake.permission = LocationPermission.denied;
      fake.permissionAfterRequest = LocationPermission.denied;
      expect(
        await datasource.requestPermission(),
        LocationAccessStatus.permissionDenied,
      );
    });

    test('returns permissionDeniedForever after the last rejection', () async {
      fake.permission = LocationPermission.denied;
      fake.permissionAfterRequest = LocationPermission.deniedForever;
      expect(
        await datasource.requestPermission(),
        LocationAccessStatus.permissionDeniedForever,
      );
    });

    test('does not show the dialog when permanently denied', () async {
      fake.permission = LocationPermission.deniedForever;
      await datasource.requestPermission();
      expect(fake.requestCount, 0);
    });
  });

  group('getCurrentLocation', () {
    test('returns the position when everything is available', () async {
      final position = await datasource.getCurrentLocation();
      expect(position.latitude, 19.7);
      expect(position.longitude, -103.46);
    });

    test('requests the permission when allowed and missing', () async {
      fake.permission = LocationPermission.denied;
      await datasource.getCurrentLocation(requestPermissionIfNeeded: true);
      expect(fake.requestCount, 1);
    });

    test('does not request the permission when told not to', () async {
      fake.permission = LocationPermission.denied;
      await expectLater(
        datasource.getCurrentLocation(requestPermissionIfNeeded: false),
        throwsA(isA<LocationPermissionDeniedException>()),
      );
      expect(fake.requestCount, 0);
    });

    test('throws deniedForever when permanently denied', () async {
      fake.permission = LocationPermission.deniedForever;
      await expectLater(
        datasource.getCurrentLocation(),
        throwsA(isA<LocationPermissionDeniedForeverException>()),
      );
    });

    test('throws serviceDisabled when GPS is off and not resolvable', () async {
      fake.serviceEnabled = false;
      await expectLater(
        datasource.getCurrentLocation(),
        throwsA(isA<LocationServiceDisabledException>()),
      );
      expect(fake.positionCalls, 0);
    });

    test(
      'on Android resolves a disabled service through the native dialog',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        fake.serviceEnabled = false;
        final position = await datasource.getCurrentLocation(
          resolveServiceIfDisabled: true,
        );
        expect(position.latitude, 19.7);
        expect(fake.positionCalls, 1);
      },
    );

    test('maps a cancelled native dialog to serviceDisabled', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      fake.serviceEnabled = false;
      fake.positionError = const geo.LocationServiceDisabledException();
      await expectLater(
        datasource.getCurrentLocation(resolveServiceIfDisabled: true),
        throwsA(isA<LocationServiceDisabledException>()),
      );
    });

    test('off Android a disabled service is not resolved in-app', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      fake.serviceEnabled = false;
      await expectLater(
        datasource.getCurrentLocation(resolveServiceIfDisabled: true),
        throwsA(isA<LocationServiceDisabledException>()),
      );
      expect(fake.positionCalls, 0);
    });

    test(
      'times out when no fix arrives while the app is in the foreground',
      () async {
        fake.neverCompletes = true;
        final quick = GeolocatorLocationDatasource(
          isAppActive: () => true,
          positionTimeout: const Duration(milliseconds: 60),
          timeoutTick: const Duration(milliseconds: 10),
        );
        await expectLater(
          quick.getCurrentLocation(),
          throwsA(isA<LocationUnavailableException>()),
        );
      },
    );

    test('does not count the time spent answering a system dialog', () async {
      // The app stays inactive (system dialog on top) longer than the budget.
      fake.positionDelay = const Duration(milliseconds: 200);
      final patient = GeolocatorLocationDatasource(
        isAppActive: () => false,
        positionTimeout: const Duration(milliseconds: 60),
        timeoutTick: const Duration(milliseconds: 10),
      );
      final position = await patient.getCurrentLocation();
      expect(position.latitude, 19.7);
    });

    test('maps timeouts to unavailable', () async {
      fake.positionError = TimeoutException('slow');
      await expectLater(
        datasource.getCurrentLocation(),
        throwsA(isA<LocationUnavailableException>()),
      );
    });
  });

  test('serviceStatusStream maps ServiceStatus to booleans', () async {
    final events = <bool>[];
    final sub = datasource.serviceStatusStream().listen(events.add);
    fake.serviceController
      ..add(ServiceStatus.disabled)
      ..add(ServiceStatus.enabled);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    expect(events, [false, true]);
  });
}
