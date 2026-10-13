import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/location/location_datasource.dart';
import 'package:ournego/core/location/location_exceptions.dart';
import 'package:ournego/features/map/data/datasources/supabase_map_datasource.dart';
import 'package:ournego/features/map/data/repositories/map_repository_impl.dart';

class _StubLocationDatasource implements LocationDatasource {
  Object? error;
  bool? lastResolve;
  bool? lastRequest;

  @override
  Future<LocationAccessStatus> checkAccessStatus() async =>
      LocationAccessStatus.serviceDisabled;

  @override
  Future<LocationAccessStatus> requestPermission() async =>
      LocationAccessStatus.permissionDeniedForever;

  @override
  Stream<bool> serviceStatusStream() => Stream.fromIterable([false, true]);

  @override
  Future<AppPosition> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
    bool resolveServiceIfDisabled = false,
  }) async {
    lastResolve = resolveServiceIfDisabled;
    lastRequest = requestPermissionIfNeeded;
    final e = error;
    if (e != null) throw e;
    return const AppPosition(latitude: 1, longitude: 2);
  }
}

// Location tests never touch businesses; avoids initializing Supabase.
class _FakeBusinessesDatasource extends Fake implements SupabaseMapDatasource {}

void main() {
  late _StubLocationDatasource datasource;
  late MapRepositoryImpl repository;

  setUp(() {
    datasource = _StubLocationDatasource();
    repository = MapRepositoryImpl(
      geolocationDatasource: datasource,
      businessesDatasource: _FakeBusinessesDatasource(),
    );
  });

  test('passes status, permission and service stream through', () async {
    expect(
      await repository.checkLocationAccessStatus(),
      LocationAccessStatus.serviceDisabled,
    );
    expect(
      await repository.requestLocationPermission(),
      LocationAccessStatus.permissionDeniedForever,
    );
    expect(await repository.watchLocationService().toList(), [false, true]);
  });

  test('forwards the resolve and request flags', () async {
    await repository.getCurrentLocation(
      requestPermissionIfNeeded: false,
      resolveServiceIfDisabled: true,
    );
    expect(datasource.lastRequest, isFalse);
    expect(datasource.lastResolve, isTrue);
  });

  const cases = <(Object, Type)>[
    (LocationPermissionDeniedException(), LocationPermissionDeniedFailure),
    (
      LocationPermissionDeniedForeverException(),
      LocationPermissionDeniedForeverFailure,
    ),
    (LocationServiceDisabledException(), LocationServiceDisabledFailure),
    (LocationUnavailableException(), LocationUnavailableFailure),
  ];

  for (final (exception, failureType) in cases) {
    test('maps ${exception.runtimeType} to $failureType', () async {
      datasource.error = exception;
      final result = await repository.getCurrentLocation();
      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure.runtimeType, failureType),
        (_) => fail('expected failure'),
      );
    });
  }

  test('returns the position on success', () async {
    final result = await repository.getCurrentLocation();
    expect(result, isA<Right<Failure, AppPosition>>());
  });
}
