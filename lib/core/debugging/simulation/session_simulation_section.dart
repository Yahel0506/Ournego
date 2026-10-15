import 'package:flutter/material.dart';

import 'package:ournego/core/debugging/simulation/session_expiry_simulator.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

/// Debug panel section: expires the current session on demand.
class SessionSimulationSection extends StatelessWidget {
  SessionSimulationSection({super.key, SessionExpirySimulator? simulator})
    : simulator = simulator ?? SessionExpirySimulator.supabase();

  final SessionExpirySimulator simulator;

  static String messageFor(SessionExpiryOutcome outcome) => switch (outcome) {
    SessionExpiryOutcome.expired => 'Sesión vencida: debería verse el aviso.',
    SessionExpiryOutcome.noSession =>
      'No hay sesión iniciada: no hay nada que vencer.',
    SessionExpiryOutcome.notExpired =>
      'La sesión sigue activa. Hace falta red real para vencerla.',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('debugSessionSimulation'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            'Simulación de sesión',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Revoca el refresh token como lo haría el servidor. Es real: '
            'tendrás que volver a iniciar sesión. Necesita red real.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: OurnegoButton.secondary(
            key: const ValueKey('debugExpireSession'),
            label: 'Vencer sesión ahora',
            icon: Icons.lock_clock_rounded,
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final outcome = await simulator.expireNow();
              messenger.showSnackBar(
                SnackBar(content: Text(messageFor(outcome))),
              );
            },
          ),
        ),
      ],
    );
  }
}
