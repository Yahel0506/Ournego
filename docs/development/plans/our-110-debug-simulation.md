# OUR-110 — Simulador de escenarios en el panel de debug

Estado: entrega A (infraestructura + arranque) implementada; B, C y D pendientes.

Issue: OUR-110. Validación en dispositivo real: OUR-140 (matriz de 6 escenarios).

## Objetivo

Probar los recorridos de falla de OUR-110 sin prepararlos físicamente en el dispositivo. El panel de debug permite inyectar la **señal de entrada** (configuración, red, sesión, ubicación, Google) y la app reacciona con el código de producción. Las pantallas, diálogos y el mapeo de fallos son los reales; solo la causa es simulada y se señala como tal.

La simulación no sustituye la evidencia de OUR-140, que exige un Android físico.

## Principios

- Todo vive en `lib/core/debugging/simulation/` y detrás de `kDebugMode`.
- Se falsea la entrada, nunca la reacción.
- Lo simulado nunca se confunde con lo real: una franja de debug solo aparece cuando el fallo es inyectado (`StartupFailure.simulated`).
- Un fallo de arranque guardado se aplica a **un solo** arranque en frío, así que no puede dejar la app inservible.

## Piezas (entrega A)

| Pieza | Función |
|---|---|
| `DebugSimulation` | Entidad inmutable con las variables simuladas (hoy `startupFault`). |
| `DebugSimulationStore` | Persiste en SharedPreferences para el próximo arranque en frío. |
| `DebugSimulationController` | `ValueNotifier` con la simulación activa; `bootstrap()` consume el fallo guardado. |
| `debugSimulationControllerProvider` | Provider (sobrescrito en `main` en debug). |
| `StartupInterceptors` (en `core/startup`) | Costura que envuelve `resolveConfig`, `prepare` e `initializeSdk` y reporta `wasSimulated`. |
| `startupInterceptorsFor(fault)` | Fallos: configuración, preparación (1 reintento ok), preparación persistente, inicialización, timeout (5 s). |
| `DebugRestartScope` | Reconstruye `ProviderScope` + `StartupGate` para repetir el arranque sin matar el proceso. |
| `SimulatedStartupFailureBanner` | Franja en la pantalla de error real, con "Desactivar simulación y reiniciar". |
| `StartupSimulationSection` | Sección del `DebugPanel` para elegir el fallo y reiniciar el arranque. |

## Entregas

| PR | Contenido | Estado |
|---|---|---|
| A | Infraestructura + arranque + franja en la pantalla de error | Hecha |
| B | Red (sin conexión, servidor inalcanzable, lenta) + sesión vencida real vía `setSession` con refresh inválido | Pendiente |
| C | Ubicación (decorador de `LocationDatasource`, diálogos simulados) + Google (resultados vía `SupabaseAuthDatasource` simulado) | Pendiente |
| D | Presets alineados con OUR-140, tarjeta de señales reales, badge global, docs | Pendiente |

## Riesgos y límites

- `initialization` falla antes de entrar en `Supabase.initialize`: no reproduce el singleton parcial del SDK, pero la pantalla que ve el usuario es idéntica.
- En debug, `main` lee SharedPreferences antes del arranque para cargar la simulación; ese acceso adelanta la primera lectura real.
- Red (B): los `.stream()` de Supabase usan websocket y no `httpClient`; habrá que reconectar realtime y comprobar que los streams se recuperan.
- Sesión (B): "Vencer sesión ahora" es destructiva (hay que volver a iniciar sesión) y necesita red real.

## Verificación de la entrega A

- Pruebas: `test/core/debugging/simulation/startup_simulation_test.dart` (interceptores contra el `StartupController` real, store, un solo uso, franja con y sin simulación, panel).
- `flutter analyze` y `flutter test` limpios.
