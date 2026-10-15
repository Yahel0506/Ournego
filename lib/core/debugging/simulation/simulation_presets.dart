import 'package:ournego/core/debugging/simulation/debug_simulation.dart';

/// One scenario of the OUR-140 validation matrix, ready to apply.
class SimulationPreset {
  const SimulationPreset({
    required this.id,
    required this.title,
    required this.expected,
    this.simulation = const DebugSimulation(),
    this.restartsStartup = false,
    this.expiresSession = false,
  });

  final String id;
  final String title;

  /// What the app should do, taken from the manual checklists.
  final String expected;

  /// Applied on top of a clean state, so presets never stack.
  final DebugSimulation simulation;

  /// The scenario starts at app launch, so startup has to run again.
  final bool restartsStartup;

  /// The scenario is an action (revoking the session), not a state.
  final bool expiresSession;
}

const simulationPresets = <SimulationPreset>[
  SimulationPreset(
    id: 'config',
    title: '1 · Fallo de configuración / Supabase',
    expected:
        'Pantalla "Ournego no puede iniciar" con "Ver ayuda" y sin '
        '"Reintentar". Nunca entra a un flujo roto.',
    simulation: DebugSimulation(startupFault: StartupFault.configuration),
    restartsStartup: true,
  ),
  SimulationPreset(
    id: 'session',
    title: '2 · Sesión vencida',
    expected:
        'Diálogo "Tu sesión venció". "Iniciar sesión" vuelve a la ruta previa; '
        '"Seguir como invitado" deja la app usable. Requiere sesión y red '
        'reales.',
    expiresSession: true,
  ),
  SimulationPreset(
    id: 'offline-open',
    title: '3 · Sin red al abrir',
    expected:
        'Se ve el mapa con el banner "Sin conexión" y sin cargas infinitas. '
        'Al restablecer la red aparece "Conexión restablecida".',
    simulation: DebugSimulation(networkMode: NetworkMode.offline),
    restartsStartup: true,
  ),
  SimulationPreset(
    id: 'offline-use',
    title: '4 · Red perdida durante el uso',
    expected:
        'Aparece el banner "Sin conexión" al instante. Al volver a "Real" '
        'desaparece y los datos se recargan solos.',
    simulation: DebugSimulation(networkMode: NetworkMode.offline),
  ),
  SimulationPreset(
    id: 'no-location',
    title: '5 · Sin ubicación',
    expected:
        'Sheet de Nego sin pantalla en blanco; "Continuar sin ubicación" deja '
        'el banner y el chip de zona (OUR-133).',
    simulation: DebugSimulation(locationMode: LocationMode.denied),
  ),
  SimulationPreset(
    id: 'google',
    title: '6 · Login con Google',
    expected:
        'Mensaje claro con acción de reintento, sin quedar en carga ni en '
        'un estado roto (OUR-129).',
    simulation: DebugSimulation(googleOutcome: GoogleOutcome.unavailable),
  ),
];
