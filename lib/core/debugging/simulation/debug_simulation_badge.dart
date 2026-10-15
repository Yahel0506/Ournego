import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';

/// Small pill on top of every screen while any simulation is active, so a
/// simulated case is never mistaken for a real one. Tap opens the panel.
class DebugSimulationBadge extends ConsumerWidget {
  const DebugSimulationBadge({
    super.key,
    required this.onTap,
    required this.child,
  });

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(debugSimulationControllerProvider);
    final theme = Theme.of(context);
    return Stack(
      textDirection: TextDirection.ltr,
      children: [
        Positioned.fill(child: child),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            if (!controller.value.isActive) return const SizedBox.shrink();
            return Positioned(
              top: MediaQuery.paddingOf(context).top + 4,
              right: 8,
              child: Material(
                key: const ValueKey('debugSimulationBadge'),
                color: theme.colorScheme.tertiaryContainer,
                shape: const StadiumBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bug_report_rounded,
                          size: 14,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'SIMULACIÓN',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
