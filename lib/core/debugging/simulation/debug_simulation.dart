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

/// Network condition seen by the app (debug builds only).
enum NetworkMode {
  real('Real', 'La app usa la red del dispositivo.'),
  offline(
    'Sin conexión',
    'El dispositivo no reporta red y toda petición HTTP falla.',
  ),
  serverUnreachable(
    'Servidor inalcanzable',
    'El dispositivo cree tener red, pero ninguna petición llega al servidor.',
  ),
  slow('Red lenta', 'Cada petición HTTP tarda 4 segundos extra.');

  const NetworkMode(this.label, this.description);

  final String label;
  final String description;
}

/// Everything the debug panel can simulate. Immutable; extend with one field
/// per simulated variable.
class DebugSimulation {
  const DebugSimulation({
    this.startupFault = StartupFault.none,
    this.networkMode = NetworkMode.real,
  });

  final StartupFault startupFault;
  final NetworkMode networkMode;

  bool get isActive =>
      startupFault != StartupFault.none || networkMode != NetworkMode.real;

  DebugSimulation copyWith({
    StartupFault? startupFault,
    NetworkMode? networkMode,
  }) => DebugSimulation(
    startupFault: startupFault ?? this.startupFault,
    networkMode: networkMode ?? this.networkMode,
  );

  Map<String, Object?> toJson() => {
    'startupFault': startupFault.name,
    'networkMode': networkMode.name,
  };

  factory DebugSimulation.fromJson(Map<String, Object?> json) {
    return DebugSimulation(
      startupFault: StartupFault.values.firstWhere(
        (fault) => fault.name == json['startupFault'],
        orElse: () => StartupFault.none,
      ),
      networkMode: NetworkMode.values.firstWhere(
        (mode) => mode.name == json['networkMode'],
        orElse: () => NetworkMode.real,
      ),
    );
  }
}
