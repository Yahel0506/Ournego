import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_restart_scope.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/core/debugging/simulation/session_expiry_simulator.dart';
import 'package:ournego/core/debugging/simulation/session_simulation_section.dart';
import 'package:ournego/core/debugging/simulation/simulation_presets.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

/// The six OUR-140 scenarios, one tap each, plus a full reset.
class SimulationPresetsSection extends ConsumerWidget {
  SimulationPresetsSection({super.key, SessionExpirySimulator? simulator})
    : simulator = simulator ?? SessionExpirySimulator.supabase();

  final SessionExpirySimulator simulator;

  Future<void> _apply(
    BuildContext context,
    WidgetRef ref,
    SimulationPreset preset,
  ) async {
    final controller = ref.read(debugSimulationControllerProvider);
    final messenger = ScaffoldMessenger.of(context);
    controller.update(preset.simulation);
    if (preset.restartsStartup) DebugRestartScope.restart(context);
    if (preset.expiresSession) {
      final outcome = await simulator.expireNow();
      messenger.showSnackBar(
        SnackBar(content: Text(SessionSimulationSection.messageFor(outcome))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(debugSimulationControllerProvider);
    return Column(
      key: const ValueKey('debugPresets'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Escenarios de OUR-140',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Cada escenario parte de un estado limpio. Los que empiezan al '
            'abrir la app reinician el arranque.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        for (final preset in simulationPresets)
          ListTile(
            key: ValueKey('debugPreset-${preset.id}'),
            title: Text(preset.title),
            subtitle: Text(preset.expected),
            isThreeLine: true,
            onTap: () => _apply(context, ref, preset),
          ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: OurnegoButton.secondary(
              key: const ValueKey('debugResetAll'),
              label: 'Restablecer todo',
              icon: Icons.layers_clear_rounded,
              onPressed: controller.value.isActive
                  ? () {
                      final needsRestart =
                          controller.value.startupFault != StartupFault.none;
                      controller.update(const DebugSimulation());
                      if (needsRestart) DebugRestartScope.restart(context);
                    }
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}
