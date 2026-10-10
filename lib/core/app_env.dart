import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;

import 'package:flutter_dotenv/flutter_dotenv.dart';

// Conditional import for web-specific environment configuration
import 'package:ournego/core/env_config_stub.dart'
    if (dart.library.js_interop) 'package:ournego/core/env_config_web.dart';

/// Compile-time values passed with `--dart-define` or
/// `--dart-define-from-file=.env`. `String.fromEnvironment` only accepts
/// constant names, so every supported key must be listed here.
const Map<String, String> _compileTimeDefines = {
  'MAPBOX_ACCESS_TOKEN': String.fromEnvironment('MAPBOX_ACCESS_TOKEN'),
  'MAPBOX_USERNAME': String.fromEnvironment('MAPBOX_USERNAME'),
  'MAPBOX_STYLE_ID_DARK': String.fromEnvironment('MAPBOX_STYLE_ID_DARK'),
  'MAPBOX_STYLE_ID_LIGHT': String.fromEnvironment('MAPBOX_STYLE_ID_LIGHT'),
  'LOCATIONIQ_API_KEY': String.fromEnvironment('LOCATIONIQ_API_KEY'),
};

class AppEnv {
  AppEnv._();

  static String getString(String key) {
    if (kIsWeb) {
      return getWebEnvVariable(key);
    }

    return resolve(
      key,
      defines: _compileTimeDefines,
      dotenvValues: dotenv.isInitialized ? dotenv.env : const {},
    );
  }

  /// Prefers a non-empty compile-time define and falls back to dotenv values,
  /// which are only present when a `.env` asset was bundled.
  @visibleForTesting
  static String resolve(
    String key, {
    required Map<String, String> defines,
    required Map<String, String> dotenvValues,
  }) {
    final define = defines[key] ?? '';
    if (define.trim().isNotEmpty) return define;
    return dotenvValues[key] ?? '';
  }
}
