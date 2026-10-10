import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/app_env.dart';

void main() {
  group('AppEnv.resolve', () {
    test('prefers a non-empty compile-time define', () {
      final value = AppEnv.resolve(
        'MAPBOX_ACCESS_TOKEN',
        defines: {'MAPBOX_ACCESS_TOKEN': 'define-token'},
        dotenvValues: {'MAPBOX_ACCESS_TOKEN': 'dotenv-token'},
      );

      expect(value, 'define-token');
    });

    test('falls back to dotenv when the define is empty', () {
      final value = AppEnv.resolve(
        'MAPBOX_ACCESS_TOKEN',
        defines: {'MAPBOX_ACCESS_TOKEN': '  '},
        dotenvValues: {'MAPBOX_ACCESS_TOKEN': 'dotenv-token'},
      );

      expect(value, 'dotenv-token');
    });

    test('returns an empty string when no source provides the key', () {
      final value = AppEnv.resolve(
        'LOCATIONIQ_API_KEY',
        defines: const {},
        dotenvValues: const {},
      );

      expect(value, '');
    });
  });
}
