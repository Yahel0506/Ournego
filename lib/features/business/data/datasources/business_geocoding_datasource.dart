import 'dart:convert';
import 'package:http/http.dart' as http;

class BusinessGeocodingDatasource {
  Future<List<Map<String, dynamic>>> getAddressSuggestions(String query) async {
    if (query.isEmpty || query.length < 3) {
      return [];
    }
    final url = Uri.https('photon.komoot.io', '/api/', {
      'q': query,
      'limit': '5',
      'lang': 'en',
    });

    final response = await http.get(
      url,
      // ESTO ES CLAVE: Agrega un User-Agent
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
    return [];
  }
}
