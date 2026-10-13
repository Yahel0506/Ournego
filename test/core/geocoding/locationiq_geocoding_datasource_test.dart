import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ournego/core/geocoding/locationiq_geocoding_datasource.dart';

LocationIqGeocodingDatasource _datasource(
  Future<http.Response> Function(http.Request request) handler, {
  String apiKey = 'test-key',
}) {
  return LocationIqGeocodingDatasource(
    client: MockClient(handler),
    apiKeyProvider: () => apiKey,
  );
}

void main() {
  group('getAddressSuggestions', () {
    test('parses suggestions and sends the expected query', () async {
      late Uri requested;
      final datasource = _datasource((request) async {
        requested = request.url;
        return http.Response(
          json.encode([
            {
              'lat': '19.70',
              'lon': '-103.46',
              'address': {
                'name': 'Centro',
                'city': 'Ciudad Guzmán',
                'state': 'Jalisco',
                'country': 'México',
              },
            },
          ]),
          200,
        );
      });

      final result = await datasource.getAddressSuggestions('centro');

      expect(requested.host, 'api.locationiq.com');
      expect(requested.path, '/v1/autocomplete.php');
      expect(requested.queryParameters['key'], 'test-key');
      expect(requested.queryParameters['q'], 'centro');
      expect(requested.queryParameters['countrycodes'], 'mx');
      expect(result.single['name'], 'Centro');
      expect(result.single['lat'], 19.70);
      expect(result.single['lon'], -103.46);
    });

    test('throws when the API answers with an error', () async {
      final datasource = _datasource((_) async => http.Response('', 500));
      await expectLater(
        datasource.getAddressSuggestions('centro'),
        throwsException,
      );
    });

    test('throws without sending a request when the key is missing', () async {
      var called = false;
      final datasource = _datasource((_) async {
        called = true;
        return http.Response('[]', 200);
      }, apiKey: '');

      await expectLater(
        datasource.getAddressSuggestions('centro'),
        throwsException,
      );
      expect(called, isFalse);
    });
  });

  group('reverse', () {
    test('returns the address block of the place', () async {
      late Uri requested;
      final datasource = _datasource((request) async {
        requested = request.url;
        return http.Response(
          json.encode({
            'display_name': 'x',
            'address': {'suburb': 'Centro', 'city': 'Ciudad Guzmán'},
          }),
          200,
        );
      });

      final address = await datasource.reverse(
        latitude: 19.7,
        longitude: -103.46,
      );

      expect(requested.path, '/v1/reverse');
      expect(requested.queryParameters['lat'], '19.7');
      expect(requested.queryParameters['lon'], '-103.46');
      expect(address['suburb'], 'Centro');
    });

    test('returns an empty address when nothing is found', () async {
      final datasource = _datasource((_) async => http.Response('{}', 404));
      expect(await datasource.reverse(latitude: 0, longitude: 0), isEmpty);
    });

    test('throws on server errors', () async {
      final datasource = _datasource((_) async => http.Response('', 500));
      await expectLater(
        datasource.reverse(latitude: 0, longitude: 0),
        throwsException,
      );
    });
  });
}
