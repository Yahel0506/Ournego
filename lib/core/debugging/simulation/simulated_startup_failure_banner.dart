import 'package:flutter/material.dart';

import 'package:ournego/core/debugging/simulation/debug_restart_scope.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

/// Shown on the startup error screen only while the failure is simulated.
class SimulatedStartupFailureBanner extends StatelessWidget {
  const SimulatedStartupFailureBanner({super.key, required this.controller});

  final DebugSimulationController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fault = controller.value.startupFault;
    return Container(
      key: const ValueKey('simulatedStartupFailureBanner'),
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.bug_report_rounded,
                color: theme.colorScheme.onTertiaryContainer,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Fallo simulado (debug)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${fault.label}. Esto no es un error real: la pantalla de abajo '
            'es la que verá el usuario ante este fallo.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onTertiaryContainer,
            ),
          ),
          const SizedBox(height: 12),
          OurnegoButton.secondary(
            label: 'Desactivar simulación y reiniciar',
            icon: Icons.restart_alt_rounded,
            onPressed: () {
              controller.update(
                controller.value.copyWith(startupFault: StartupFault.none),
              );
              DebugRestartScope.restart(context);
            },
          ),
        ],
      ),
    );
  }
}
