import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_restart_scope.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

/// Debug panel section: pick a startup fault and restart the startup flow.
class StartupSimulationSection extends ConsumerWidget {
  const StartupSimulationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(debugSimulationControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.value.startupFault;
        return Column(
          key: const ValueKey('debugStartupSimulation'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Simulación de arranque',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'El fallo se aplica al reiniciar el arranque y una vez en el '
                'próximo arranque en frío.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (final fault in StartupFault.values)
              ListTile(
                key: ValueKey('debugStartupFault-${fault.name}'),
                title: Text(fault.label),
                subtitle: Text(fault.description),
                trailing: fault == selected
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                selected: fault == selected,
                onTap: () => controller.update(
                  controller.value.copyWith(startupFault: fault),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: OurnegoButton.primary(
                key: const ValueKey('debugRestartStartup'),
                label: 'Reiniciar arranque ahora',
                icon: Icons.restart_alt_rounded,
                onPressed: () => DebugRestartScope.restart(context),
              ),
            ),
          ],
        );
      },
    );
  }
}
