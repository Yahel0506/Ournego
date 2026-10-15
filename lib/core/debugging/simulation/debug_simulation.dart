/// Fault injected into the app startup (debug builds only).
enum StartupFault {
  none('Sin simulación', 'El arranque usa la configuración real.'),
  configuration(
    'Configuración ausente',
    'La URL o la clave de Supabase no son válidas. Sin reintento.',
  ),
  preparationRetryable(
    'Preparación local falla una vez',
    'channel-error al preparar SharedPreferences; el único reintento funciona.',
  ),
  preparationPersistent(
    'Preparación local falla siempre',
    'channel-error repetido; tras el único reintento pide reabrir la app.',
  ),
  initialization(
    'Supabase no inicializa',
    'Falla la inicialización del SDK. Sin reintento.',
  ),
  timeout(
    'Arranque que no termina',
    'La preparación nunca responde; vence a los 5 segundos.',
  );

  const StartupFault(this.label, this.description);

  final String label;
  final String description;
}

/// Everything the debug panel can simulate. Immutable; extend with one field
/// per simulated variable.
class DebugSimulation {
  const DebugSimulation({this.startupFault = StartupFault.none});

  final StartupFault startupFault;

  bool get isActive => startupFault != StartupFault.none;

  DebugSimulation copyWith({StartupFault? startupFault}) =>
      DebugSimulation(startupFault: startupFault ?? this.startupFault);

  Map<String, Object?> toJson() => {'startupFault': startupFault.name};

  factory DebugSimulation.fromJson(Map<String, Object?> json) {
    final name = json['startupFault'];
    return DebugSimulation(
      startupFault: StartupFault.values.firstWhere(
        (fault) => fault.name == name,
        orElse: () => StartupFault.none,
      ),
    );
  }
}
