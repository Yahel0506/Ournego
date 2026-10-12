import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:ournego/core/app_env.dart';

/// Thin LocationIQ client shared by every feature that needs to turn text
/// into coordinates (autocomplete) or coordinates into a place (reverse).
class LocationIqGeocodingDatasource {
  LocationIqGeocodingDatasource({
    http.Client? client,
    String Function()? apiKeyProvider,
  }) : _client = client ?? http.Client(),
       _apiKeyProvider =
           apiKeyProvider ?? (() => AppEnv.getString('LOCATIONIQ_API_KEY'));

  final http.Client _client;
  final String Function() _apiKeyProvider;

  String _requireApiKey() {
    final apiKey = _apiKeyProvider();
    if (apiKey.isEmpty) {
      throw Exception('Missing LOCATIONIQ_API_KEY');
    }
    return apiKey;
  }

  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    final url = Uri.https('api.locationiq.com', '/v1/autocomplete.php', {
      'key': _requireApiKey(),
      'q': query,
      'countrycodes': 'mx',
      'limit': '5',
      'accept-language': 'es',
      'format': 'json',
    });

    final response = await _client.get(
      url,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode != 200) {
      throw Exception('Error en el http');
    }

    final data = json.decode(response.body);
    final features = data as List<dynamic>? ?? [];

    return features.map((feature) {
      final properties = feature['address'] as Map<String, dynamic>? ?? {};
      return {
        'name': properties['name'] ?? '',
        'city': properties['city'] ?? '',
        'state': properties['state'] ?? '',
        'country': properties['country'] ?? '',
        'lat': double.parse(feature['lat']),
        'lon': double.parse(feature['lon']),
      };
    }).toList();
  }

  /// Returns the `address` block of the place at the given point, or an empty
  /// map when LocationIQ knows nothing about it.
  Future<Map<String, dynamic>> reverse({
    required double latitude,
    required double longitude,
  }) async {
    final url = Uri.https('api.locationiq.com', '/v1/reverse', {
      'key': _requireApiKey(),
      'lat': '$latitude',
      'lon': '$longitude',
      'zoom': '16',
      'accept-language': 'es',
      'format': 'json',
    });

    final response = await _client.get(
      url,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode == 404) {
      return const {};
    }
    if (response.statusCode != 200) {
      throw Exception('Error en el http');
    }

    final data = json.decode(response.body);
    if (data is! Map<String, dynamic>) {
      return const {};
    }
    return data['address'] as Map<String, dynamic>? ?? const {};
  }
}
