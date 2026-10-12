import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/entities/map_location_state.dart';
import 'package:ournego/features/map/domain/entities/reference_location.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';

import '../../../../fakes/fake_map_repository.dart';

const _gps = AppPosition(latitude: 19.4, longitude: -99.1);
const _zone = ManualZone(
  position: AppPosition(latitude: 19.71, longitude: -103.47),
  label: 'Col. Centro',
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeMapRepository repository;
  late ProviderContainer container;

  ProviderContainer createContainer() {
    final created = ProviderContainer(
      overrides: [mapRepositoryProvider.overrideWith((ref) => repository)],
    );
    addTearDown(created.dispose);
    return created;
  }

  MapLocationState current() => container.read(mapProvider).requireValue;

  setUp(() {
    repository = FakeMapRepository(locationResult: const Right(_gps));
  });

  test('granted access exposes the GPS position as reference', () async {
    container = createContainer();
    final state = await container.read(mapProvider.future);

    expect(state.status, LocationAccessStatus.granted);
    expect(state.gpsPosition, _gps);
    expect(state.reference.source, ReferenceLocationSource.gps);
  });

  test('startup never prompts for permission when it is missing', () async {
    repository.setAccessStatus(LocationAccessStatus.permissionDenied);
    container = createContainer();
    final state = await container.read(mapProvider.future);

    expect(repository.permissionRequestCount, 0);
    expect(state.status, LocationAccessStatus.permissionDenied);
    expect(state.gpsPosition, isNull);
    expect(state.reference.source, ReferenceLocationSource.defaultZone);
  });

  test('startup with unexpected failures stays usable, not in error', () async {
    repository.setLocationResult(Left(ServerFailure()));
    container = createContainer();
    final state = await container.read(mapProvider.future);

    expect(container.read(mapProvider).hasError, isFalse);
    expect(state.status, LocationAccessStatus.unavailable);
    expect(state.reference.source, ReferenceLocationSource.defaultZone);
  });

  test('requestPermission grants access and picks up the position', () async {
    repository.setAccessStatus(
      LocationAccessStatus.permissionDenied,
      afterPermissionRequest: LocationAccessStatus.granted,
    );
    container = createContainer();
    await container.read(mapProvider.future);

    await container.read(mapProvider.notifier).requestPermission();

    expect(repository.permissionRequestCount, 1);
    expect(current().status, LocationAccessStatus.granted);
    expect(current().gpsPosition, _gps);
  });

  test('requestPermission can end in a permanent denial', () async {
    repository.setAccessStatus(
      LocationAccessStatus.permissionDenied,
      afterPermissionRequest: LocationAccessStatus.permissionDeniedForever,
    );
    container = createContainer();
    await container.read(mapProvider.future);

    await container.read(mapProvider.notifier).requestPermission();

    expect(current().status, LocationAccessStatus.permissionDeniedForever);
    expect(current().gpsPosition, isNull);
  });

  test('enableLocationService recovers when the user accepts', () async {
    repository.setAccessStatus(LocationAccessStatus.serviceDisabled);
    container = createContainer();
    await container.read(mapProvider.future);
    expect(current().status, LocationAccessStatus.serviceDisabled);

    await container.read(mapProvider.notifier).enableLocationService();

    expect(repository.lastResolveServiceIfDisabled, isTrue);
    expect(current().status, LocationAccessStatus.granted);
    expect(current().gpsPosition, _gps);
  });

  test('enableLocationService keeps the state when the user cancels', () async {
    repository.setAccessStatus(LocationAccessStatus.serviceDisabled);
    repository.setLocationResult(Left(LocationServiceDisabledFailure()));
    container = createContainer();
    await container.read(mapProvider.future);

    await container.read(mapProvider.notifier).enableLocationService();

    expect(current().status, LocationAccessStatus.serviceDisabled);
    expect(current().reference.source, ReferenceLocationSource.defaultZone);
  });

  test('recheck drops the position when permission was revoked', () async {
    container = createContainer();
    await container.read(mapProvider.future);
    expect(current().gpsPosition, _gps);

    repository.setAccessStatus(LocationAccessStatus.permissionDenied);
    await container.read(mapProvider.notifier).recheck();

    expect(current().status, LocationAccessStatus.permissionDenied);
    expect(current().gpsPosition, isNull);
  });

  test('recheck recovers after the user grants access in settings', () async {
    repository.setAccessStatus(LocationAccessStatus.permissionDeniedForever);
    container = createContainer();
    await container.read(mapProvider.future);

    repository.setAccessStatus(LocationAccessStatus.granted);
    await container.read(mapProvider.notifier).recheck();

    expect(current().status, LocationAccessStatus.granted);
    expect(current().gpsPosition, _gps);
  });

  test('a timed out fix keeps the previous position', () async {
    container = createContainer();
    await container.read(mapProvider.future);

    repository.setLocationResult(Left(LocationUnavailableFailure()));
    await container.read(mapProvider.notifier).recheck();

    expect(current().status, LocationAccessStatus.unavailable);
    expect(current().gpsPosition, _gps);
  });

  test('GPS switched off while open is detected and recovered', () async {
    container = createContainer();
    await container.read(mapProvider.future);

    repository.emitServiceStatus(enabled: false);
    await _settle();
    expect(current().status, LocationAccessStatus.serviceDisabled);
    expect(current().gpsPosition, isNull);

    repository.emitServiceStatus(enabled: true);
    await _settle();
    await _settle();
    expect(current().status, LocationAccessStatus.granted);
    expect(current().gpsPosition, _gps);
  });

  test('service changes do not override a permission problem', () async {
    repository.setAccessStatus(LocationAccessStatus.permissionDenied);
    container = createContainer();
    await container.read(mapProvider.future);

    repository.emitServiceStatus(enabled: false);
    await _settle();

    expect(current().status, LocationAccessStatus.permissionDenied);
  });

  test(
    'reference falls back from GPS to manual zone to default zone',
    () async {
      repository.setAccessStatus(LocationAccessStatus.permissionDeniedForever);
      container = createContainer();
      await container.read(mapProvider.future);
      final notifier = container.read(mapProvider.notifier);

      expect(current().reference.source, ReferenceLocationSource.defaultZone);

      notifier.setManualZone(_zone);
      expect(current().reference.source, ReferenceLocationSource.manualZone);
      expect(current().reference.label, 'Col. Centro');

      notifier.clearManualZone();
      expect(current().reference.source, ReferenceLocationSource.defaultZone);
    },
  );

  test(
    'GPS wins over the manual zone and the zone survives rechecks',
    () async {
      container = createContainer();
      await container.read(mapProvider.future);
      final notifier = container.read(mapProvider.notifier);

      notifier.setManualZone(_zone);
      expect(current().reference.source, ReferenceLocationSource.gps);

      repository.setAccessStatus(LocationAccessStatus.permissionDenied);
      await notifier.recheck();
      expect(current().manualZone, _zone);
      expect(current().reference.source, ReferenceLocationSource.manualZone);
    },
  );
}
