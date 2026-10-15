import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// LAYER 1: Datasources
final connectivityProvider = Provider<Connectivity>((ref) => Connectivity());

// LAYER 4: State
bool _hasConnection(List<ConnectivityResult> results) =>
    results.any((result) => result != ConnectivityResult.none);

/// Emits `true` while [connectivity] reports any network interface.
Stream<bool> deviceConnectivityStream(Connectivity connectivity) async* {
  try {
    yield _hasConnection(await connectivity.checkConnectivity());
  } catch (_) {
    yield true;
  }
  yield* connectivity.onConnectivityChanged.map(_hasConnection).distinct();
}

/// Emits `true` while the device reports any network interface.
final connectivityStatusProvider = StreamProvider<bool>((ref) {
  return deviceConnectivityStream(ref.watch(connectivityProvider));
});

/// Optimistic synchronous view: assumes online until proven otherwise.
final isOnlineProvider = Provider<bool>((ref) {
  return ref.watch(connectivityStatusProvider).value ?? true;
});
