import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Conditional import for web-specific environment configuration
import 'package:ournego/core/env_config_stub.dart'
    if (dart.library.js_interop) 'package:ournego/core/env_config_web.dart';

class AppEnv {
  AppEnv._();

  static String getString(String key) {
    if (kIsWeb) {
      return getWebEnvVariable(key);
    }

    return dotenv.env[key] ?? '';
  }
}
