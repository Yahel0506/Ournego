import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';

const _storageKey = 'debugSimulation';

/// Persists the simulation so it can be applied on the next cold start.
class DebugSimulationStore {
  Future<DebugSimulation> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw == null) return const DebugSimulation();
      return DebugSimulation.fromJson(
        (jsonDecode(raw) as Map).cast<String, Object?>(),
      );
    } catch (_) {
      return const DebugSimulation();
    }
  }

  Future<void> save(DebugSimulation simulation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(simulation.toJson()));
    } catch (error) {
      debugPrint('No se pudo guardar la simulación: $error');
    }
  }
}
