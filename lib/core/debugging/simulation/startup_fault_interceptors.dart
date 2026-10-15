import 'dart:async';

import 'package:flutter/services.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/startup/startup_controller.dart';

const _simulatedTimeout = Duration(seconds: 5);

/// Builds the interceptors that make the real startup flow fail the way the
/// selected [fault] describes. Call once per [StartupController]: attempt
/// state (the single retry) lives in the returned closures.
StartupInterceptors? startupInterceptorsFor(StartupFault fault) {
  if (fault == StartupFault.none) return null;
  var injected = false;
  var prepareCalls = 0;

  return StartupInterceptors(
    wasSimulated: () => injected,
    timeout: fault == StartupFault.timeout ? _simulatedTimeout : null,
    resolveConfig: fault == StartupFault.configuration
        ? (real) => () async {
            injected = true;
            throw StartupConfigurationException();
          }
        : null,
    prepare: switch (fault) {
      StartupFault.preparationRetryable => (real) => () async {
        if (prepareCalls++ == 0) {
          injected = true;
          throw PlatformException(code: 'channel-error');
        }
        await real();
      },
      StartupFault.preparationPersistent => (real) => () async {
        injected = true;
        throw PlatformException(code: 'channel-error');
      },
      StartupFault.timeout => (real) => () {
        injected = true;
        return Completer<void>().future;
      },
      _ => null,
    },
    initializeSdk: fault == StartupFault.initialization
        ? (real) => (config) async {
            injected = true;
            throw StateError('Simulated SDK initialization failure');
          }
        : null,
  );
}
