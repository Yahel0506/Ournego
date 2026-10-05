import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum StartupErrorKind { configuration, preparation, initialization, timeout }

class StartupFailure {
  const StartupFailure({required this.kind, required this.canRetry});

  final StartupErrorKind kind;
  final bool canRetry;
}

class StartupState {
  const StartupState._({
    required this.isStarting,
    required this.startOnMap,
    this.failure,
  });

  const StartupState.starting() : this._(isStarting: true, startOnMap: false);
  const StartupState.ready({required bool startOnMap})
    : this._(isStarting: false, startOnMap: startOnMap);
  const StartupState.error(StartupFailure failure)
    : this._(isStarting: false, startOnMap: false, failure: failure);

  final bool isStarting;
  final bool startOnMap;
  final StartupFailure? failure;
  bool get isReady => !isStarting && failure == null;
}

class SupabaseStartupConfig {
  const SupabaseStartupConfig({required this.url, required this.anonKey});

  final String url;
  final String anonKey;
}

typedef StartupConfigResolver = Future<SupabaseStartupConfig> Function();
typedef StartupPreparation = Future<void> Function();
typedef StartupSdkInitializer =
    Future<void> Function(SupabaseStartupConfig config);
typedef StartupOnboardingReader = Future<bool> Function();

class StartupConfigurationException implements Exception {}

Future<SupabaseStartupConfig> resolveStartupConfig({
  required bool isWeb,
  required String urlDefine,
  required String anonKeyDefine,
  required String Function(String key) webValue,
  Future<void> Function()? loadDotenv,
  Map<String, String> Function()? dotenvValues,
}) async {
  var url = isWeb ? webValue('SUPABASE_URL') : urlDefine;
  var anonKey = isWeb ? webValue('SUPABASE_ANON_KEY') : anonKeyDefine;

  if (!isWeb && (url.trim().isEmpty || anonKey.trim().isEmpty)) {
    try {
      await (loadDotenv ?? () => dotenv.load(fileName: '.env'))();
    } catch (_) {
      // Missing .env is a configuration failure only if a field has no define.
    }
    final values = (dotenvValues ?? () => dotenv.env)();
    if (url.trim().isEmpty) url = values['SUPABASE_URL'] ?? '';
    if (anonKey.trim().isEmpty) anonKey = values['SUPABASE_ANON_KEY'] ?? '';
  }

  final normalizedUrl = url.trim();
  final normalizedKey = anonKey.trim();
  final uri = Uri.tryParse(normalizedUrl);
  if (normalizedKey.isEmpty ||
      uri == null ||
      !{'http', 'https'}.contains(uri.scheme.toLowerCase()) ||
      uri.host.isEmpty) {
    throw StartupConfigurationException();
  }
  return SupabaseStartupConfig(url: normalizedUrl, anonKey: normalizedKey);
}

class StartupController {
  StartupController({
    required StartupConfigResolver resolveConfig,
    required StartupPreparation prepare,
    required StartupSdkInitializer initializeSdk,
    required StartupOnboardingReader readOnboarding,
    this.timeout = const Duration(seconds: 20),
  }) : _resolveConfig = resolveConfig,
       _prepare = prepare,
       _initializeSdk = initializeSdk,
       _readOnboarding = readOnboarding;

  factory StartupController.production({
    required bool isWeb,
    required String Function(String key) webValue,
    required StartupOnboardingReader readOnboarding,
  }) {
    return StartupController(
      resolveConfig: () => resolveStartupConfig(
        isWeb: isWeb,
        urlDefine: const String.fromEnvironment('SUPABASE_URL'),
        anonKeyDefine: const String.fromEnvironment('SUPABASE_ANON_KEY'),
        webValue: webValue,
      ),
      prepare: () async {
        await SharedPreferences.getInstance();
      },
      initializeSdk: (config) async {
        await Supabase.initialize(
          url: config.url,
          anonKey: config.anonKey,
          debug: false,
        );
      },
      readOnboarding: readOnboarding,
    );
  }

  final StartupConfigResolver _resolveConfig;
  final StartupPreparation _prepare;
  final StartupSdkInitializer _initializeSdk;
  final StartupOnboardingReader _readOnboarding;
  final Duration timeout;

  final List<void Function()> _listeners = [];
  StartupState _state = const StartupState.starting();
  StartupState get state => _state;

  bool _disposed = false;
  bool _attemptActive = false;
  int _attemptId = 0;
  int _attempts = 0;
  bool _started = false;
  Timer? _timeoutTimer;

  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  void start() {
    if (_started || _disposed) return;
    _started = true;
    _runAttempt();
  }

  void retry() {
    if (_disposed ||
        _attemptActive ||
        _state.failure?.canRetry != true ||
        _attempts >= 2) {
      return;
    }
    _runAttempt();
  }

  bool _isLive(int id) => !_disposed && _attemptActive && id == _attemptId;

  void _runAttempt() {
    if (_disposed || _attemptActive) return;
    _attemptActive = true;
    _attempts++;
    final attemptId = ++_attemptId;
    _setState(const StartupState.starting());
    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(timeout, () {
      if (!_isLive(attemptId)) return;
      _timeoutTimer = null;
      _attemptActive = false;
      _attemptId++;
      _setState(
        const StartupState.error(
          StartupFailure(kind: StartupErrorKind.timeout, canRetry: false),
        ),
      );
    });
    unawaited(_executeAttempt(attemptId));
  }

  Future<void> _executeAttempt(int id) async {
    SupabaseStartupConfig config;
    try {
      config = await _resolveConfig();
    } on StartupConfigurationException {
      if (_isLive(id)) {
        _fail(
          id,
          const StartupFailure(
            kind: StartupErrorKind.configuration,
            canRetry: false,
          ),
        );
      }
      return;
    } catch (_) {
      if (_isLive(id)) {
        _fail(
          id,
          const StartupFailure(
            kind: StartupErrorKind.configuration,
            canRetry: false,
          ),
        );
      }
      return;
    }
    if (!_isLive(id)) return;

    try {
      await _prepare();
    } catch (error) {
      if (!_isLive(id)) return;
      final canRetry =
          error is PlatformException &&
          error.code == 'channel-error' &&
          _attempts == 1;
      _fail(
        id,
        StartupFailure(kind: StartupErrorKind.preparation, canRetry: canRetry),
      );
      return;
    }
    if (!_isLive(id)) return;

    bool startOnMap = false;
    try {
      startOnMap = await _readOnboarding();
    } catch (_) {
      startOnMap = false;
    }
    if (!_isLive(id)) return;

    try {
      await _initializeSdk(config);
    } catch (_) {
      if (_isLive(id)) {
        _fail(
          id,
          const StartupFailure(
            kind: StartupErrorKind.initialization,
            canRetry: false,
          ),
        );
      }
      return;
    }
    if (!_isLive(id)) return;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _attemptActive = false;
    _setState(StartupState.ready(startOnMap: startOnMap));
  }

  void _fail(int id, StartupFailure failure) {
    if (!_isLive(id)) return;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _attemptActive = false;
    _attemptId++;
    _setState(StartupState.error(failure));
  }

  void _setState(StartupState state) {
    if (_disposed) return;
    _state = state;
    for (final listener in List<void Function()>.of(_listeners)) {
      listener();
    }
  }

  void dispose() {
    _disposed = true;
    _attemptActive = false;
    _attemptId++;
    _timeoutTimer?.cancel();
    _timeoutTimer = null;
    _listeners.clear();
  }
}
