# OUR-110 — Simulador de escenarios en el panel de debug

Estado: entregas A, B, C y D implementadas. Falta validar el simulador en un dispositivo y empezar los escenarios de OUR-110 con él.

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
| C | Ubicación (`LocationDatasource` simulado, sin diálogos reales) + Google (resultados vía `SupabaseAuthDatasource` simulado) | Hecha |
| D | Presets alineados con OUR-140, tarjeta de señales reales, badge global, docs | Hecha |

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

## Piezas (entrega C)

| Pieza | Función |
|---|---|
| `LocationMode` | `real`, `granted`, `denied`, `allowOnPrompt`, `deniedForever`, `serviceDisabled`, `enableOnPrompt`, `unavailable`. |
| `SimulatedLocationDatasource` | Implementa `LocationDatasource` (provider `geolocationDatasourceProvider`). Los diálogos del sistema no se dibujan: la respuesta del usuario va dentro del modo. Con `denied` y `serviceDisabled` el usuario rechaza; con `allowOnPrompt` y `enableOnPrompt` acepta cuando la app lo pide y el modo pasa a `granted`. `serviceStatusStream` sigue los cambios de modo. |
| `GoogleOutcome` | `real`, `canceled`, `unavailable`, `network`, `serverError`. |
| `SimulatedAuthDatasource` | Lanza las excepciones reales del flujo de Google (`GoogleSignInException`, `ClientException`, `AuthException`), así que corre `googleSignInFailureFor` y las pantallas de producción. |
| Secciones del panel | `LocationSimulationSection` y `GoogleSimulationSection`. |

## Piezas (entrega D)

| Pieza | Función |
|---|---|
| `simulationPresets` | Los 6 escenarios de OUR-140 con el resultado esperado de los checklists. Cada preset parte de un estado limpio; los que empiezan al abrir (configuración, sin red al abrir) reinician el arranque; "Sesión vencida" ejecuta la acción. |
| `SimulationPresetsSection` | Un toque por escenario y "Restablecer todo". |
| `RealSignalsCard` | Muestra lo que el dispositivo y el backend reportan de verdad (Supabase, sesión, red, permiso) y marca con "≠ simulado" lo que la simulación sobrescribe. Botón "Actualizar". |
| `DebugSimulationBadge` | Pastilla "SIMULACIÓN" sobre todas las pantallas mientras algo esté activo; al tocarla abre el panel. Solo en debug (envuelve el contenido en `MyApp.builder`). |
| `lib/core/debugging/simulation/README.md` | Guía para añadir una variable simulada. |

## Riesgos y límites

- `initialization` falla antes de entrar en `Supabase.initialize`: no reproduce el singleton parcial del SDK, pero la pantalla que ve el usuario es idéntica.
- En debug, `main` lee SharedPreferences antes del arranque para cargar la simulación; ese acceso adelanta la primera lectura real.
- Red (B): los `.stream()` de Supabase usan websocket y no `httpClient`; al pasar a `offline` o `serverUnreachable` se desconecta realtime. No se reconecta a mano (`connect()` es interno del SDK): se reconecta cuando un canal vuelve a suscribirse, lo que dispara el refresco tras un periodo `offline`. Al salir de `serverUnreachable` no hay transición de conectividad, así que conviene reabrir la pantalla.
- Sesión (B): "Vencer sesión ahora" es destructiva (hay que volver a iniciar sesión) y necesita red real.

- Ubicación (C): no se muestran los diálogos nativos de permiso ni de "Location Accuracy"; el flujo visual del diálogo sigue exigiendo emulador o dispositivo. El formulario de negocio usa un provider de ubicación privado y no pasa por el simulador.
- Google (C): el éxito no se puede simular (necesita un token real); el flujo nativo del selector de cuentas solo se valida en dispositivo.

## Verificación de las entregas A, B y C

- Pruebas: `test/core/debugging/simulation/startup_simulation_test.dart` (interceptores contra el `StartupController` real, store, un solo uso, franja con y sin simulación, panel) y `network_session_simulation_test.dart` (cliente HTTP, conectividad combinada, simulador de sesión, secciones del panel) y `location_google_simulation_test.dart` (cada modo de ubicación, prompts que conceden, stream del GPS, mapeo de Google a los fallos de producción) y `presets_signals_badge_test.dart` (presets, reinicio selectivo, reset, tarjeta de señales y badge).
- `flutter analyze` y `flutter test` limpios.

## Pendiente tras la entrega D

- Ninguna de las cuatro entregas se ha probado todavía en un emulador o dispositivo (sin dispositivo disponible al implementarlas). Primera tarea: recorrer los 6 presets en Android y anotar diferencias con el comportamiento real.
- La posición del badge (arriba a la derecha bajo la barra de estado) puede solaparse con controles del mapa; ajustar tras verlo.
- Con el simulador validado, abordar los criterios de OUR-110 que faltan (sesión, red y ubicación) y dejar la evidencia física para OUR-140.
