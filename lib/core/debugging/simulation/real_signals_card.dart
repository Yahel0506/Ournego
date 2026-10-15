import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/core/debugging/simulation/real_signals.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

String locationStatusLabel(LocationAccessStatus status) => switch (status) {
  LocationAccessStatus.granted => 'concedida',
  LocationAccessStatus.permissionDenied => 'denegada',
  LocationAccessStatus.permissionDeniedForever => 'denegada para siempre',
  LocationAccessStatus.serviceDisabled => 'GPS apagado',
  LocationAccessStatus.unavailable => 'no disponible',
};

/// What is really happening, next to which values the simulation overrides.
class RealSignalsCard extends ConsumerStatefulWidget {
  const RealSignalsCard({super.key});

  @override
  ConsumerState<RealSignalsCard> createState() => _RealSignalsCardState();
}

class _RealSignalsCardState extends ConsumerState<RealSignalsCard> {
  late Future<RealSignals> _signals = ref.read(realSignalsReaderProvider)();

  void _refresh() {
    final next = ref.read(realSignalsReaderProvider)();
    setState(() {
      _signals = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(debugSimulationControllerProvider);
    final theme = Theme.of(context);
    return Card(
      key: const ValueKey('debugRealSignals'),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<RealSignals>(
          future: _signals,
          builder: (context, snapshot) {
            final signals = snapshot.data;
            return ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final sim = controller.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Señales reales',
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        OurnegoButton.text(
                          key: const ValueKey('debugRefreshSignals'),
                          size: OurnegoButtonSize.compact,
                          label: 'Actualizar',
                          icon: Icons.refresh_rounded,
                          onPressed: _refresh,
                        ),
                      ],
                    ),
                    if (signals == null)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    else ...[
                      _row(
                        'Supabase',
                        signals.supabaseReady ? 'inicializado' : 'sin iniciar',
                        sim.startupFault != StartupFault.none
                            ? sim.startupFault.label
                            : null,
                      ),
                      _row(
                        'Sesión',
                        signals.hasSession ? 'activa' : 'sin sesión',
                        null,
                      ),
                      _row(
                        'Red del dispositivo',
                        switch (signals.deviceOnline) {
                          true => 'con red',
                          false => 'sin red',
                          null => 'desconocida',
                        },
                        sim.networkMode != NetworkMode.real
                            ? sim.networkMode.label
                            : null,
                      ),
                      _row(
                        'Ubicación',
                        locationStatusLabel(signals.location),
                        sim.locationMode != LocationMode.real
                            ? sim.locationMode.label
                            : null,
                      ),
                      _row(
                        'Google',
                        'sin señal propia',
                        sim.googleOutcome != GoogleOutcome.real
                            ? sim.googleOutcome.label
                            : null,
                      ),
                    ],
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _row(String name, String real, String? simulated) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 4, child: Text(name)),
          Expanded(
            flex: 6,
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: real),
                  if (simulated != null)
                    TextSpan(
                      text: '  ≠ simulado: $simulated',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
