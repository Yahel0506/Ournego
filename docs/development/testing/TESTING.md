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
