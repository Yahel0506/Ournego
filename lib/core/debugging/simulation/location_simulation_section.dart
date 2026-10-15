import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';

/// Debug panel section: picks the simulated location state. Applies live.
class LocationSimulationSection extends ConsumerWidget {
  const LocationSimulationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(debugSimulationControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.value.locationMode;
        return Column(
          key: const ValueKey('debugLocationSimulation'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Simulación de ubicación',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Sustituye el permiso, el GPS y sus diálogos del sistema. '
                'Los modos "acepta" pasan a Concedida cuando la app lo pide.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (final mode in LocationMode.values)
              ListTile(
                key: ValueKey('debugLocationMode-${mode.name}'),
                title: Text(mode.label),
                subtitle: Text(mode.description),
                trailing: mode == selected
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                selected: mode == selected,
                onTap: () => controller.update(
                  controller.value.copyWith(locationMode: mode),
                ),
              ),
          ],
        );
      },
    );
  }
}
