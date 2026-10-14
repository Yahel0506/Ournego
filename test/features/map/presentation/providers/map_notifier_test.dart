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

import '../../../../fakes/fake_manual_zone_repository.dart';
import '../../../../fakes/fake_map_repository.dart';

const _gps = AppPosition(latitude: 19.4, longitude: -99.1);
const _zone = ManualZone(
  position: AppPosition(latitude: 19.71, longitude: -103.47),
  label: 'Col. Centro',
);

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeMapRepository repository;
  late FakeManualZoneRepository zoneRepository;
  late ProviderContainer container;

  ProviderContainer createContainer() {
    final created = ProviderContainer(
      overrides: [
        mapRepositoryProvider.overrideWith((ref) => repository),
        manualZoneRepositoryProvider.overrideWith((ref) => zoneRepository),
      ],
    );
    addTearDown(created.dispose);
    return created;
  }

  MapLocationState current() => container.read(mapProvider).requireValue;

  setUp(() {
    repository = FakeMapRepository(locationResult: const Right(_gps));
    zoneRepository = FakeManualZoneRepository();
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

      await notifier.clearManualZone();
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

  test('a saved manual zone is restored on startup', () async {
    zoneRepository.savedZone = _zone;
    repository.setAccessStatus(LocationAccessStatus.permissionDeniedForever);
    container = createContainer();
    final state = await container.read(mapProvider.future);

    expect(state.manualZone, _zone);
    expect(state.reference.source, ReferenceLocationSource.manualZone);
  });

  test('setting and clearing the zone is persisted', () async {
    container = createContainer();
    await container.read(mapProvider.future);
    final notifier = container.read(mapProvider.notifier);

    await notifier.setManualZone(_zone);
    expect(zoneRepository.savedZone, _zone);

    await notifier.clearManualZone();
    expect(zoneRepository.savedZone, isNull);
  });

  group('declined native GPS dialog', () {
    test('is remembered so coming back does not reopen it', () async {
      repository.setLocationResult(Left(LocationServiceDisabledFailure()));
      container = createContainer();
      await container.read(mapProvider.future);

      expect(current().status, LocationAccessStatus.serviceDisabled);
      expect(current().serviceDialogOffered, isTrue);
      final requests = repository.locationRequestCount;

      // Returning from the dialog counts as resuming the app.
      await container.read(mapProvider.notifier).recheck();
      expect(repository.locationRequestCount, requests);
    });

    test('a forced recheck still looks again', () async {
      repository.setLocationResult(Left(LocationServiceDisabledFailure()));
      container = createContainer();
      await container.read(mapProvider.future);
      final requests = repository.locationRequestCount;

      await container.read(mapProvider.notifier).recheck(force: true);
      expect(repository.locationRequestCount, requests + 1);
    });

    test('is not assumed when the service was off before asking', () async {
      repository.setAccessStatus(LocationAccessStatus.serviceDisabled);
      container = createContainer();
      await container.read(mapProvider.future);

      expect(current().status, LocationAccessStatus.serviceDisabled);
      expect(current().serviceDialogOffered, isFalse);
    });

    test(
      'declining the dialog from enableLocationService is remembered',
      () async {
        repository.setAccessStatus(LocationAccessStatus.serviceDisabled);
        repository.setLocationResult(Left(LocationServiceDisabledFailure()));
        container = createContainer();
        await container.read(mapProvider.future);

        await container.read(mapProvider.notifier).enableLocationService();
        expect(current().serviceDialogOffered, isTrue);
      },
    );

    test('a new outage offers the dialog again', () async {
      repository.setLocationResult(Left(LocationServiceDisabledFailure()));
      container = createContainer();
      await container.read(mapProvider.future);
      expect(current().serviceDialogOffered, isTrue);

      repository.setLocationResult(const Right(_gps));
      repository.emitServiceStatus(enabled: true);
      await _settle();
      await _settle();
      expect(current().status, LocationAccessStatus.granted);
      expect(current().serviceDialogOffered, isFalse);

      repository.emitServiceStatus(enabled: false);
      await _settle();
      expect(current().status, LocationAccessStatus.serviceDisabled);
      expect(current().serviceDialogOffered, isFalse);
    });
  });

  test(
    'a platform that cannot watch the GPS service still loads the map',
    () async {
      repository = _NoServiceUpdatesRepository();
      container = createContainer();
      final state = await container.read(mapProvider.future);

      expect(container.read(mapProvider).hasError, isFalse);
      expect(state.status, LocationAccessStatus.granted);
      expect(state.gpsPosition, _gps);
    },
  );
}

/// Mimics the web, where watching the location service throws.
class _NoServiceUpdatesRepository extends FakeMapRepository {
  _NoServiceUpdatesRepository() : super(locationResult: const Right(_gps));

  @override
  Stream<bool> watchLocationService() {
    throw UnsupportedError('getServiceStatusStream is not supported');
  }
}
