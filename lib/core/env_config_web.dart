// Web-specific environment configuration
import 'dart:js_interop' as js;

import 'package:flutter/foundation.dart';

@js.JS('window.ENV')
external js.JSObject? get _windowEnv;

extension on js.JSObject {
  external js.JSString? operator [](js.JSString key);
}

String getWebEnvVariable(String key) {
  try {
    final env = _windowEnv;
    if (env != null) {
      final value = env[key.toJS];
      if (value != null) {
        return value.toDart;
      }
    }
  } catch (e) {
    debugPrint('Error reading web environment variable $key: $e');
  }

  return '';
}
