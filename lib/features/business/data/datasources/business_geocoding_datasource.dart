import 'dart:convert';
import 'package:http/http.dart' as http;

class BusinessGeocodingDatasource {
  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    /*if (query.isEmpty || query.length < 3) {
      return [];
    }
    final url = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '5',
      'lang': 'en',
    });

    final response = await http.get(
      url,
      headers: {
        'Accept': 'application/json',
        'User-Agent': 'OurnegoApp/1.0 (contact: tu_correo@gmail.com)',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final features = data['features'] as List<dynamic>? ?? [];

      return features.map((feature) {
        final properties = feature['properties'] as Map<String, dynamic>? ?? {};
        final geometry =
            (feature['geometry']?['coordinates'] as List<dynamic>?) ?? [0, 0];
        return {
          'name': properties['name'] ?? '',
          'city': properties['city'] ?? '',
          'state': properties['state'] ?? '',
          'country': properties['country'] ?? '',
          'lat': geometry.length > 1 ? geometry[1] : 0,
          'lon': geometry.isNotEmpty ? geometry[0] : 0,
        };
      }).toList();
    } else {
      throw Exception('Error en el http');
    }
    // ignore: dead_code
    return [];*/

    final String apiKey = 'pk.276923b81a5b05b99adc374e2164b240';
    final url =
        'https://api.locationiq.com/v1/autocomplete.php?key=$apiKey&q=$query&countrycodes=mx&limit=5&accept-language=es&format=json';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
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
    } else {
      throw Exception('Error en el http');
    }
  }
}
