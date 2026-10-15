import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';

/// Debug panel section: picks the simulated network. Applies immediately.
class NetworkSimulationSection extends ConsumerWidget {
  const NetworkSimulationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(debugSimulationControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.value.networkMode;
        return Column(
          key: const ValueKey('debugNetworkSimulation'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Simulación de red',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Se aplica al instante y también en el próximo arranque en '
                'frío (una vez).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (final mode in NetworkMode.values)
              ListTile(
                key: ValueKey('debugNetworkMode-${mode.name}'),
                title: Text(mode.label),
                subtitle: Text(mode.description),
                trailing: mode == selected
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                selected: mode == selected,
                onTap: () => controller.update(
                  controller.value.copyWith(networkMode: mode),
                ),
              ),
          ],
        );
      },
    );
  }
}
