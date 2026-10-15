import 'package:flutter/foundation.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_store.dart';

/// Holds the active simulation. Changes are saved for the next cold start.
class DebugSimulationController extends ValueNotifier<DebugSimulation> {
  DebugSimulationController({
    DebugSimulation initial = const DebugSimulation(),
    DebugSimulationStore? store,
  }) : _store = store,
       super(initial);

  /// Loads the saved simulation and clears the saved startup fault, so a
  /// startup fault applies to one cold start only and can never trap the
  /// developer in an unusable app. The in-memory value keeps it for restarts.
  static Future<DebugSimulationController> bootstrap({
    DebugSimulationStore? store,
  }) async {
    final effectiveStore = store ?? DebugSimulationStore();
    final saved = await effectiveStore.load();
    if (saved.isActive) {
      await effectiveStore.save(const DebugSimulation());
    }
    return DebugSimulationController(initial: saved, store: effectiveStore);
  }

  final DebugSimulationStore? _store;

  void update(DebugSimulation simulation) {
    value = simulation;
    _store?.save(simulation);
  }
}
