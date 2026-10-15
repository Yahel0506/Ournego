import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/core/network/connectivity_providers.dart';

/// Replaces `connectivityStatusProvider` in debug: the device stream, forced
/// to `false` while the network is simulated as offline.
Stream<bool> simulatedConnectivityStream(
  Ref ref, {
  void Function(NetworkMode mode)? onModeChanged,
}) {
  final controller = ref.watch(debugSimulationControllerProvider);
  final device = deviceConnectivityStream(ref.watch(connectivityProvider));
  return combineConnectivity(
    device,
    controller,
    onModeChanged: onModeChanged ?? _syncRealtime,
    registerDispose: ref.onDispose,
  );
}

@visibleForTesting
Stream<bool> combineConnectivity(
  Stream<bool> device,
  DebugSimulationController controller, {
  required void Function(NetworkMode mode) onModeChanged,
  required void Function(void Function()) registerDispose,
}) {
  final out = StreamController<bool>();
  var deviceOnline = true;
  bool? last;
  var mode = controller.value.networkMode;

  void emit() {
    final online = mode == NetworkMode.offline ? false : deviceOnline;
    if (online == last) return;
    last = online;
    out.add(online);
  }

  void onController() {
    final next = controller.value.networkMode;
    if (next == mode) return;
    mode = next;
    onModeChanged(mode);
    emit();
  }

  final subscription = device.listen((online) {
    deviceOnline = online;
    emit();
  });
  controller.addListener(onController);
  registerDispose(() {
    subscription.cancel();
    controller.removeListener(onController);
    out.close();
  });
  return out.stream;
}

/// The realtime socket does not use the HTTP client, so it is cut by hand.
/// Restoring needs no call: the SDK reconnects when a channel subscribes
/// again, which the reconnect refresh triggers after an offline period.
void _syncRealtime(NetworkMode mode) {
  if (mode == NetworkMode.real || mode == NetworkMode.slow) return;
  try {
    Supabase.instance.client.realtime.disconnect();
  } catch (_) {
    // Supabase is not initialized yet (startup error screen).
  }
}
