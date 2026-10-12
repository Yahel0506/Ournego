import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/geocoding/locationiq_geocoding_datasource.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/data/datasources/local_manual_zone_datasource.dart';
import 'package:ournego/features/map/data/models/manual_zone_model.dart';
import 'package:ournego/features/map/data/repositories/manual_zone_repository_impl.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';

const _zone = ManualZone(
  position: AppPosition(latitude: 19.71, longitude: -103.47),
  label: 'Col. Centro',
);

ManualZoneRepositoryImpl _repository(
  Future<http.Response> Function(http.Request request) handler,
) {
  return ManualZoneRepositoryImpl(
    geocodingDatasource: LocationIqGeocodingDatasource(
      client: MockClient(handler),
      apiKeyProvider: () => 'key',
    ),
    localDatasource: LocalManualZoneDatasource(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('LocalManualZoneDatasource', () {
    final datasource = LocalManualZoneDatasource();

    test('returns null when nothing is saved', () async {
      expect(await datasource.load(), isNull);
    });

    test('saves, loads and clears a zone', () async {
      await datasource.save(ManualZoneModel.fromZone(_zone));

      final loaded = await datasource.load();
      expect(loaded?.label, 'Col. Centro');
      expect(loaded?.position.latitude, 19.71);
      expect(loaded?.position.longitude, -103.47);

      await datasource.clear();
      expect(await datasource.load(), isNull);
    });

    test('discards corrupted data instead of failing', () async {
      SharedPreferences.setMockInitialValues({
        LocalManualZoneDatasource.manualZoneKey: 'not json',
      });
      expect(await datasource.load(), isNull);
      expect(await datasource.load(), isNull);
    });
  });

  group('ManualZoneRepositoryImpl.searchZones', () {
    test('does not hit the network for short queries', () async {
      var called = false;
      final repository = _repository((_) async {
        called = true;
        return http.Response('[]', 200);
      });

      final result = await repository.searchZones(' ab ');

      expect(called, isFalse);
      expect(result.getOrElse(() => [_zone]), isEmpty);
    });

    test('maps suggestions to labelled zones without duplicates', () async {
      final repository = _repository((_) async {
        return http.Response(
          '[{"lat":"19.7","lon":"-103.4","address":{"name":"Centro","city":"Ciudad Guzmán"}},'
          '{"lat":"19.8","lon":"-103.5","address":{"name":"Centro","city":"Ciudad Guzmán"}},'
          '{"lat":"19.9","lon":"-103.6","address":{"name":"Ciudad Guzmán","city":"Ciudad Guzmán"}},'
          '{"lat":"19.95","lon":"-103.65","address":{"name":"Mi Centro Ciudad Guzmán","city":"Ciudad Guzmán"}},'
          '{"lat":"20.0","lon":"-103.7","address":{"state":"Jalisco"}}]',
          200,
        );
      });

      final zones = (await repository.searchZones(
        'centro',
      )).getOrElse(() => []);

      expect(zones.map((zone) => zone.label), [
        'Centro, Ciudad Guzmán',
        'Ciudad Guzmán',
        'Mi Centro Ciudad Guzmán',
        'Jalisco',
      ]);
      expect(zones.first.position.latitude, 19.7);
    });

    test('maps connectivity problems to NetworkFailure', () async {
      final repository = _repository((_) async {
        throw http.ClientException('offline');
      });
      final result = await repository.searchZones('centro');
      expect(
        result.swap().getOrElse(() => ServerFailure()),
        isA<NetworkFailure>(),
      );
    });

    test('maps other errors to ServerFailure', () async {
      final repository = _repository((_) async => http.Response('', 500));
      final result = await repository.searchZones('centro');
      expect(
        result.swap().getOrElse(() => NetworkFailure()),
        isA<ServerFailure>(),
      );
    });
  });

  group('ManualZoneRepositoryImpl.resolveZoneFromPoint', () {
    const point = AppPosition(latitude: 19.7, longitude: -103.4);

    test('names the zone after its suburb and city', () async {
      final repository = _repository((_) async {
        return http.Response(
          '{"address":{"suburb":"Lomas","city":"Ciudad Guzmán"}}',
          200,
        );
      });
      final zone = await repository.resolveZoneFromPoint(point);
      expect(zone.label, 'Lomas, Ciudad Guzmán');
      expect(zone.position.latitude, 19.7);
    });

    test('falls back to the town when there is no suburb', () async {
      final repository = _repository((_) async {
        return http.Response('{"address":{"town":"Zapotlán"}}', 200);
      });
      expect((await repository.resolveZoneFromPoint(point)).label, 'Zapotlán');
    });

    test('keeps the point with a generic label when offline', () async {
      final repository = _repository((_) async {
        throw TimeoutException('offline');
      });
      final zone = await repository.resolveZoneFromPoint(point);
      expect(zone.label, ManualZoneRepositoryImpl.unnamedZoneLabel);
      expect(zone.position.longitude, -103.4);
    });

    test('keeps the point with a generic label for unknown places', () async {
      final repository = _repository((_) async => http.Response('{}', 404));
      final zone = await repository.resolveZoneFromPoint(point);
      expect(zone.label, ManualZoneRepositoryImpl.unnamedZoneLabel);
    });
  });

  group('ManualZoneRepositoryImpl persistence', () {
    test('saves, reads and clears the zone', () async {
      final repository = _repository((_) async => http.Response('', 500));

      expect((await repository.getSavedZone()).getOrElse(() => _zone), isNull);

      await repository.saveZone(_zone);
      final saved = (await repository.getSavedZone()).getOrElse(() => null);
      expect(saved?.label, 'Col. Centro');

      await repository.clearSavedZone();
      expect((await repository.getSavedZone()).getOrElse(() => _zone), isNull);
    });
  });
}
