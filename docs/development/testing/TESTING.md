# UI Automation Testing (Patrol)

## Requisitos previos

1. Instalar dependencias:

```bash
flutter pub get
```

2. Tener Patrol CLI instalado:

```bash
dart pub global activate patrol_cli
```

## Cómo correr la suite completa

```bash
patrol test
```

## Cómo correr solo tests críticos de auth

```bash
patrol test --tags auth
```

## Qué hacer cuando un test falla

1. Revisa primero el nombre del escenario que falla (Patrol imprime el test exacto y el paso).
2. Busca el primer `expect` fallido o timeout en el stacktrace.
3. Si falla en permisos nativos, valida que el emulador/simulador permita automation del diálogo.
4. Repite solo ese archivo para depuración rápida:

```bash
patrol test integration_test/auth_test.dart
```

5. Si el fallo viene de un TODO documentado, compara con el comportamiento actual de la app y ajusta cuando la feature exista.

## Escenarios cubiertos

### Onboarding / Sesión (`integration_test/onboarding_test.dart`)

- Usuario nuevo completa onboarding y persiste flag en storage.
- Usuario con onboarding completo salta a autenticación.
- Sesión válida entra a app sin login.
- Token expirado redirige a login sin crash/spinner infinito.
- Cierre de app a mitad de onboarding conserva comportamiento actual (TODO funcional documentado).
- Logout manual exige credenciales en próxima apertura.

### Auth por tipo de usuario (`integration_test/auth_test.dart`)

- Login cliente normal navega a mapa.
- Login dueño con negocio navega a dashboard de negocio.
- Login dueño sin negocio navega a registro de negocio.
- Credenciales incorrectas muestran error legible.
- Sin conexión muestra error controlado.
- Cuenta suspendida: caso cubierto con TODO por ausencia de estado explícito en modelo actual.

### Flujo core de mapa (`integration_test/core_flow_test.dart`)

- Permiso de ubicación concedido carga markers de negocios.
- Permiso de ubicación denegado no crashea y mantiene estado estable.
- Sin negocios en radio actual (TODO: falta componente explícito de estado vacío en UI actual).
- Tap en negocio abre detalle y muestra nombre (TODO: distancia aún no renderizada).
- Actualización de nombre de negocio por stream se refleja sin reload manual.

### Mapa sin ubicación (OUR-133, `test/`)

- `test/core/location/geolocator_location_datasource_test.dart`: estado de permiso/GPS sin pedir nada, diálogo nativo en Android, timeout que solo cuenta en primer plano. Usa un `GeolocatorPlatform` falso (`MockPlatformInterfaceMixin`).
- `test/features/map/presentation/providers/map_notifier_test.dart`: cada estado (concedido, denegado, denegado permanente, GPS apagado, no disponible), recuperación al volver a la app, diálogo de GPS rechazado y zona manual. Nunca queda en error ni en carga infinita.
- `test/features/map/presentation/map_location_access_test.dart` y `map_zone_test.dart`: sheet de Nego, banner, selector de zona, chip y búsqueda con distancias.
- `test/core/geocoding` y `test/features/map/data/manual_zone_test.dart`: LocationIQ con `MockClient`, guardado de la zona y errores de red.

## Control de calidad Android en CI

El workflow `.github/workflows/android-ci.yml` ejecuta este gate en pull requests,
pushes a `main` y ejecuciones manuales. Usa Flutter 3.41.4 estable y Java 17,
instala dependencias y ejecuta, en orden:

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

Cada paso falla el job si devuelve un error. El APK se publica como artefacto de
la ejecución; el build actual usa la configuración de firma debug de Flutter,
por lo que valida la compilación Android y no produce un paquete firmado para
Google Play.

### Estado comprobado localmente

En la verificación del 2 de octubre de 2026, `flutter analyze` terminó con
`No issues found!`, `flutter test` pasó las 30 pruebas estándar y
`flutter build apk --release` generó
`build/app/outputs/flutter-apk/app-release.apk` (66.3 MB). El build informó que
no encontró la fuente de iconos de `packages/cupertino_icons/CupertinoIcons`;
registrar su uso real y comprobar los iconos en Android tiene prioridad P2.
El workflow está añadido al repositorio, pero su primera ejecución remota sigue
pendiente de un push y no se considera verificada aquí.

### Diagnósticos pendientes

- **P1 — Patrol en Android:** `flutter test` pasa 30 pruebas Dart estándar; no
  ejecuta los escenarios `integration_test/` con Patrol en un dispositivo o
  emulador Android. Ejecutar esa suite como una validación de dispositivo sigue
  pendiente.
- **P1 — Firma de distribución:** el APK de este gate usa firma debug. La
  configuración y custodia de firma release para Google Play queda pendiente.
- **P2 — Iconos Cupertino:** el build reporta que falta la fuente de iconos
  `packages/cupertino_icons/CupertinoIcons`; verificar qué iconos la requieren
  y su renderizado Android antes de decidir si se necesita un cambio de assets o
  dependencias.

### Recuperación del arranque (OUR-131)

El 5 de octubre de 2026, las pruebas estándar cubrieron la validación de la
configuración, el fallback por campo entre `--dart-define` y dotenv, el único
reintento de `SharedPreferences.getInstance()` después de `channel-error`, los
fallos sin reintento, la expiración con resultados tardíos, el bloqueo del
router hasta completar Supabase, la conservación de onboarding y la ayuda sin
mostrar excepciones. La suite dirigida `flutter test test/core/startup` pasó
18 pruebas; la suite completa `flutter test` pasó 48 pruebas. `flutter analyze`
no reportó problemas y `flutter build apk --release` produjo el APK habitual
(66.5 MB tras la corrección de contraste del reintento). El build conserva el
aviso existente de la fuente de iconos Cupertino.

Estas pruebas validan la barrera mediante un `StartupGate` inyectable y una
respuesta de canal simulada para SharedPreferences.

También se comprobó en un Samsung S24 (SM-S921B) el mismo controlador y widget
mediante una app de prueba separada, sin el asset `.env`, con fallos inyectados
y preferencias nativas propias. Se verificaron configuración defectuosa sin
reintento, recuperación mediante reintento con una sola llamada al inicializador
y onboarding conservado, doble pulsación, fallo persistente sin tercer intento,
fallo del inicializador, timeout con preparación tardía y ayuda local cuando
falla la apertura del soporte. La revisión visual comprobó el contraste del
reintento y texto ampliado al doble en los temas claro y oscuro. La app temporal
se retiró después; la instalación y los datos de Ournego se conservaron.

La validación nativa usa un inicializador simulado: no prueba una caída real,
la recuperación de sesión ni la conexión de producción a Supabase. Tampoco
equivale a ejecutar la suite Patrol pendiente indicada arriba.

### Simulador de debug: arranque (OUR-110)

En `Debug Panel → Simulación de arranque` se elige un fallo (configuración, preparación local con reintento, preparación persistente, inicialización, timeout) y "Reiniciar arranque ahora" vuelve a pasar por `StartupGate` sin cerrar la app. La pantalla de error es la real, con una franja "Fallo simulado (debug)" que solo aparece si el fallo es inyectado y ofrece "Desactivar simulación y reiniciar". Un fallo guardado se aplica a un único arranque en frío. Solo en builds debug. Además, `Simulación de red` (real, sin conexión, servidor inalcanzable, red lenta) actúa al instante sobre el SDK de Supabase, LocationIQ y el banner "Sin conexión", y `Simulación de sesión` → "Vencer sesión ahora" revoca el refresh token y muestra el diálogo real "Tu sesión venció" (requiere red real e implica volver a iniciar sesión). `Simulación de ubicación` reemplaza permiso, GPS y sus diálogos (concedida, denegada, denegada para siempre, GPS apagado, y variantes que aceptan cuando la app lo pide) y `Simulación de Google` fuerza cancelado, no disponible, sin red o error de servidor en el próximo intento. El panel abre con **Escenarios de OUR-140** (6 presets de un toque con el resultado esperado), la tarjeta **Señales reales** (lo que reporta el dispositivo, marcando con "≠ simulado" lo sobrescrito) y "Restablecer todo"; una pastilla "SIMULACIÓN" aparece sobre todas las pantallas mientras algo esté activo. Plan completo: `docs/development/plans/our-110-debug-simulation.md`. No sustituye la validación en dispositivo físico de OUR-140.

## Validación en Android real (OUR-140)

La matriz de los seis escenarios de OUR-110 (arranque, sesión, red, ubicación y Google), con resultado esperado frente a obtenido, evidencia y dispositivo, está en `docs/development/testing/our-140-android-validation.md`. Punto de partida de OUR-102.

## Checklist manual: sesión vencida y fallos de red (OUR-132)

Ejecutar en Android (emulador o dispositivo), con una cuenta completa:

1. Abrir la app en modo avión con sesión guardada: se ve el mapa y el banner "Sin conexión". Al quitar el modo avión el banner desaparece, aparece "Conexión restablecida" y los marcadores cargan solos.
2. Iniciar sesión sin red: aparece "Sin conexión. Revisa tu internet e inténtalo de nuevo." y no queda un indicador de carga infinito.
3. Con sesión iniciada, cortar la red y abrir una ruta de auth: aparece "No pudimos verificar tu cuenta"; al reconectar continúa sola; "Continuar al mapa" funciona.
4. Revocar la sesión desde Supabase (cerrar sesiones del usuario) y provocar un refresh: aparece "Tu sesión venció". "Iniciar sesión" vuelve a la ruta previa tras entrar; "Seguir como invitado" deja la app usable.
5. Como dueño de negocio, sin red, abrir el panel: error con "Reintentar", nunca "Registrar negocio".
6. Cerrar sesión manualmente: no aparece el diálogo de sesión vencida.

## Checklist manual: mapa sin ubicación (OUR-133)

Ejecutar en Android (emulador o dispositivo con Google Play Services). En un
emulador nuevo el diálogo nativo puede pedir además "Location Accuracy".

1. Revocar el permiso (`adb shell pm revoke com.ournego.app.debug android.permission.ACCESS_FINE_LOCATION`, y COARSE; la build release usa `com.ournego.app`) y abrir la app: aparece el sheet de Nego sin que salga antes el diálogo del sistema. "Continuar sin ubicación" deja el banner "Ournego no puede ver tu ubicación" y el chip "Zona: Ciudad Guzmán".
2. "Permitir" abre el diálogo del sistema. Rechazarlo dos veces abre el sheet "Elegir mi zona / Abrir ajustes".
3. "Elegir mi zona": buscar una colonia o usar el centro del mapa. El chip y las distancias de la búsqueda cambian y la zona sigue al reiniciar la app.
4. "Abrir ajustes", conceder el permiso y volver: el banner y el chip desaparecen y aparece el marcador.
5. Con la app abierta, apagar la ubicación del dispositivo: aparece el diálogo nativo. Aceptar recupera la posición; rechazar deja el banner "Tu GPS está apagado" con "Activar" y el diálogo no se repite al volver a la app.
6. En ningún caso hay pantalla en blanco, carga infinita ni navegación rota. Revisar también en modo oscuro.
