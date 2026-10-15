import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';

/// Debug panel section: picks how the next Google sign-in ends.
class GoogleSimulationSection extends ConsumerWidget {
  const GoogleSimulationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(debugSimulationControllerProvider);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final selected = controller.value.googleOutcome;
        return Column(
          key: const ValueKey('debugGoogleSimulation'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                'Simulación de Google',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Afecta al próximo intento de iniciar sesión con Google. El '
                'éxito no se puede simular: necesita un token real.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (final outcome in GoogleOutcome.values)
              ListTile(
                key: ValueKey('debugGoogleOutcome-${outcome.name}'),
                title: Text(outcome.label),
                subtitle: Text(outcome.description),
                trailing: outcome == selected
                    ? const Icon(Icons.check_circle_rounded)
                    : null,
                selected: outcome == selected,
                onTap: () => controller.update(
                  controller.value.copyWith(googleOutcome: outcome),
                ),
              ),
          ],
        );
      },
    );
  }
}
