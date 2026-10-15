import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';

// LAYER 1: Datasources
/// Overridden in `main` with the controller loaded from storage. The default
/// is an in-memory controller so widgets and tests work without an override.
final debugSimulationControllerProvider = Provider<DebugSimulationController>((
  ref,
) {
  final controller = DebugSimulationController();
  ref.onDispose(controller.dispose);
  return controller;
});
