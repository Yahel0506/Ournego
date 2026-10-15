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

/// Device location state seen by the app (debug builds only).
enum LocationMode {
  real('Real', 'La app usa el permiso y el GPS del dispositivo.'),
  granted('Concedida', 'Permiso y GPS activos, con una posición fija.'),
  denied(
    'Permiso denegado',
    'El usuario rechaza el diálogo del sistema cada vez que se pide.',
  ),
  allowOnPrompt(
    'Permiso: acepta al pedirlo',
    'Denegado hasta que la app lo pide; entonces se concede.',
  ),
  deniedForever(
    'Permiso denegado para siempre',
    'Solo los ajustes del sistema pueden cambiarlo.',
  ),
  serviceDisabled(
    'GPS apagado (rechaza activar)',
    'El usuario rechaza el diálogo nativo de activar la ubicación.',
  ),
  enableOnPrompt(
    'GPS apagado (acepta activar)',
    'Apagado hasta que la app pide activarlo; entonces se enciende.',
  ),
  unavailable(
    'No disponible',
    'No se puede determinar el estado ni la posición.',
  );

  const LocationMode(this.label, this.description);

  final String label;
  final String description;

  /// Whether the simulated location service is on.
  bool get serviceEnabled =>
      this != LocationMode.serviceDisabled &&
      this != LocationMode.enableOnPrompt;
}

/// How the Google sign-in attempt ends (debug builds only).
enum GoogleOutcome {
  real('Real', 'Se usa el flujo de Google y Supabase.'),
  canceled('Cancelado', 'El usuario cierra el selector de cuentas.'),
  unavailable(
    'No disponible',
    'Error de configuración del cliente o del proveedor de Google.',
  ),
  network('Sin red', 'La petición falla por falta de conexión.'),
  serverError('Error de servidor', 'Google o Supabase responden con un error.');

  const GoogleOutcome(this.label, this.description);

  final String label;
  final String description;
}

/// Everything the debug panel can simulate. Immutable; extend with one field
/// per simulated variable.
class DebugSimulation {
  const DebugSimulation({
    this.startupFault = StartupFault.none,
    this.networkMode = NetworkMode.real,
    this.locationMode = LocationMode.real,
    this.googleOutcome = GoogleOutcome.real,
  });

  final StartupFault startupFault;
  final NetworkMode networkMode;
  final LocationMode locationMode;
  final GoogleOutcome googleOutcome;

  bool get isActive =>
      startupFault != StartupFault.none ||
      networkMode != NetworkMode.real ||
      locationMode != LocationMode.real ||
      googleOutcome != GoogleOutcome.real;

  DebugSimulation copyWith({
    StartupFault? startupFault,
    NetworkMode? networkMode,
    LocationMode? locationMode,
    GoogleOutcome? googleOutcome,
  }) => DebugSimulation(
    startupFault: startupFault ?? this.startupFault,
    networkMode: networkMode ?? this.networkMode,
    locationMode: locationMode ?? this.locationMode,
    googleOutcome: googleOutcome ?? this.googleOutcome,
  );

  Map<String, Object?> toJson() => {
    'startupFault': startupFault.name,
    'networkMode': networkMode.name,
    'locationMode': locationMode.name,
    'googleOutcome': googleOutcome.name,
  };

  factory DebugSimulation.fromJson(Map<String, Object?> json) {
    T pick<T extends Enum>(List<T> values, String key, T fallback) =>
        values.firstWhere((v) => v.name == json[key], orElse: () => fallback);
    return DebugSimulation(
      startupFault: pick(
        StartupFault.values,
        'startupFault',
        StartupFault.none,
      ),
      networkMode: pick(NetworkMode.values, 'networkMode', NetworkMode.real),
      locationMode: pick(
        LocationMode.values,
        'locationMode',
        LocationMode.real,
      ),
      googleOutcome: pick(
        GoogleOutcome.values,
        'googleOutcome',
        GoogleOutcome.real,
      ),
    );
  }
}
