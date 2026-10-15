import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';

/// Small tab on top of every screen while any simulation is active, so a
/// simulated case is never mistaken for a real one. It sits on the left edge
/// and never takes touches, so no button or banner is ever covered.
class DebugSimulationBadge extends ConsumerWidget {
  const DebugSimulationBadge({super.key, required this.child});

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
            return Positioned.fill(
              child: IgnorePointer(
                child: Align(
                  alignment: const Alignment(-1, 0.1),
                  child: Container(
                    key: const ValueKey('debugSimulationBadge'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: ShapeDecoration(
                      color: theme.colorScheme.tertiaryContainer.withValues(
                        alpha: 0.9,
                      ),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.horizontal(
                          right: Radius.circular(12),
                        ),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bug_report_rounded,
                          size: 12,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'SIMULACIÓN',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onTertiaryContainer,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.none,
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
