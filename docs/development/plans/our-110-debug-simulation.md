# OUR-110 — Simulador de escenarios en el panel de debug

Estado: entregas A (infraestructura + arranque) y B (red + sesión) implementadas; C y D pendientes.

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
| B | Red (sin conexión, servidor inalcanzable, lenta) + sesión vencida real vía `refreshSession` con un refresh token desconocido | Hecha |
| C | Ubicación (decorador de `LocationDatasource`, diálogos simulados) + Google (resultados vía `SupabaseAuthDatasource` simulado) | Pendiente |
| D | Presets alineados con OUR-140, tarjeta de señales reales, badge global, docs | Pendiente |

## Piezas (entrega B)

| Pieza | Función |
|---|---|
| `NetworkMode` | `real`, `offline`, `serverUnreachable`, `slow`; se aplica al instante y, guardado, a un arranque en frío. |
| `SimulatedHttpClient` | Cliente HTTP que lanza `ClientException` (lo que ve la app ante una red caída) o añade 4 s. Lo usan el SDK de Supabase (`Supabase.initialize(httpClient:)`) y LocationIQ. Lee el modo en cada petición. |
| `simulatedConnectivityStream` | Sustituye `connectivityStatusProvider` en debug: fuerza `false` en `offline`; en `serverUnreachable` el dispositivo "cree" tener red, algo que hoy la app no detecta. |
| `SessionExpirySimulator` | `auth.refreshSession(<token desconocido>)`: el SDK elimina la sesión y emite el `signedOut` real que abre "Tu sesión venció". |
| `debugSimulationOverrides` | Overrides de providers aplicados solo en debug desde `main`. |
| Secciones del panel | `NetworkSimulationSection` y `SessionSimulationSection`. |

Cambios mínimos en producción: `StartupInterceptors.httpClient` y la extracción de `deviceConnectivityStream` (sin cambio de comportamiento).

## Riesgos y límites

- `initialization` falla antes de entrar en `Supabase.initialize`: no reproduce el singleton parcial del SDK, pero la pantalla que ve el usuario es idéntica.
- En debug, `main` lee SharedPreferences antes del arranque para cargar la simulación; ese acceso adelanta la primera lectura real.
- Red (B): los `.stream()` de Supabase usan websocket y no `httpClient`; al pasar a `offline` o `serverUnreachable` se desconecta realtime. No se reconecta a mano (`connect()` es interno del SDK): se reconecta cuando un canal vuelve a suscribirse, lo que dispara el refresco tras un periodo `offline`. Al salir de `serverUnreachable` no hay transición de conectividad, así que conviene reabrir la pantalla.
- Sesión (B): "Vencer sesión ahora" es destructiva (hay que volver a iniciar sesión) y necesita red real.

## Verificación de las entregas A y B

- Pruebas: `test/core/debugging/simulation/startup_simulation_test.dart` (interceptores contra el `StartupController` real, store, un solo uso, franja con y sin simulación, panel) y `network_session_simulation_test.dart` (cliente HTTP, conectividad combinada, simulador de sesión, secciones del panel).
- `flutter analyze` y `flutter test` limpios.
