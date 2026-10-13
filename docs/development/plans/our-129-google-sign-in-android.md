# OUR-129 — Inicio de sesión con Google en Android: causa raíz y configuración por modo

Estado: firma corregida (PR #100) y mensajes de error con reintento implementados; pendiente validar en dispositivo físico (ver [Pendiente](#pendiente-y-no-verificado)).

Issue: [OUR-129](https://linear.app/yaheldev/issue/OUR-129/android-corregir-problema-de-autenticacion-con-google-serverfailure-en).
Rama: `yahel0506/our-129-android-corregir-problema-de-autenticacion-con-google`.

## Síntoma

En Android el botón de Google termina en `ServerFailure`. En `SupabaseAuthRepositoryImpl.signInWithGoogle` cualquier excepción, incluida la `GoogleSignInException` de la librería, se traduce a ese fallo genérico y el motivo real solo queda en `debugPrint`.

## Causa raíz

El login con Google en Android (`google_sign_in` 7.x con Credential Manager) valida en los servidores de Google que el **paquete + la huella SHA-1 del certificado con el que se firmó el APK** coincidan con alguno de los clientes OAuth de tipo Android del proyecto. Si no coinciden, Google no entrega el ID token y el flujo falla antes de llegar a Supabase.

La configuración de firma de Gradle solo aplicaba la clave propia a `release`:

| Modo | Firma antes del cambio | SHA-1 | ¿Registrada como cliente Android? |
|---|---|---|---|
| debug | `~/.android/debug.keystore` | `3B:51:AF:FA:08:B9:92:A9:DA:4D:C1:00:D7:D7:F5:68:AF:2C:1B:0C` | No |
| profile | `~/.android/debug.keystore` (no heredaba la de release) | `3B:51:AF:FA:…:1B:0C` | No |
| release | `upload-keystore.jks` | `1D:B6:BD:C7:09:4E:B3:6A:22:98:F7:07:B0:E5:CA:EA:51:EA:58:93` | Sí |

Debug y profile se firmaban con una clave que Google no conocía, de modo que solo release podía iniciar sesión. La huella de debug además es distinta en cada equipo, así que no se puede asumir que esté registrada.

Los SHA-1 de la tabla se midieron leyendo el certificado de cada APK compilado con `apksigner verify --print-certs`. La relación causa-efecto con el `ServerFailure` es el diagnóstico del equipo; no se reprodujo el error en esta sesión.

## Qué cambió

1. `android/app/build.gradle.kts`: el build type `profile` usa la misma firma que `release`. Sin `android/key.properties` ambos siguen cayendo a la clave de debug, de modo que los clones sin credenciales compilan igual.
2. Debug se queda con su clave de debug (firmar debug con la clave de subida no es buena práctica). Esa huella se registra como cliente Android en la consola.

Comprobación posterior al cambio (`apksigner`, mismos APK tras recompilar):

| Modo | Firma | SHA-1 |
|---|---|---|
| debug | debug | `3B:51:AF:FA:…:1B:0C` |
| profile | upload-keystore | `1D:B6:BD:C7:…:58:93` |
| release | upload-keystore | `1D:B6:BD:C7:…:58:93` |

## Mensajes de error y reintento

Antes, `GoogleLoginButton` mostraba `'Error: ${failure.toString()}'` (por ejemplo `Instance of 'ServerFailure'`). Además, `SupabaseAuthDatasource` declara su propia `GoogleSignInException`, que tapa a la de `google_sign_in`, así que los códigos reales (`canceled`, `clientConfigurationError`…) nunca se distinguían y todo terminaba en `ServerFailure`.

Ahora `googleSignInFailureFor` (repositorio) importa la librería con prefijo y traduce el código a un fallo de dominio, y `LocalErrorMessagesDatasource.getGoogleSignInErrorMessage` lo convierte en texto:

| Origen | Fallo de dominio | Mensaje |
|---|---|---|
| `canceled` | `GoogleSignInCancelledFailure` | Cancelaste el inicio de sesión con Google. Puedes volver a intentarlo. |
| `clientConfigurationError`, `providerConfigurationError`, `uiUnavailable` | `GoogleSignInUnavailableFailure` | No pudimos abrir el inicio de sesión de Google en este dispositivo. Inténtalo de nuevo. |
| Sin red | `NetworkFailure` | Sin conexión. Revisa tu internet e inténtalo de nuevo. |
| Cualquier otro (`interrupted`, `userMismatch`, `unknownError`, fallo de Supabase) | `ServerFailure` | No pudimos iniciar sesión con Google. Inténtalo de nuevo. |

El snackbar (`OurnegoSnackbars.error`) acepta `actionLabel`/`onAction` y muestra un botón **Reintentar** dentro del contenedor de cristal; al pulsarlo vuelve a ejecutar el mismo flujo. El motivo técnico queda en `debugPrint`, nunca en pantalla.

Si la huella de firma de un build no está registrada, lo esperable es que se vea el mensaje de "no pudimos abrir el inicio de sesión" o el de cancelación según el código que devuelva Android; hay que contrastarlo en dispositivo.

## Configuración que exige cada modo

### Clientes OAuth (proyecto `ournego`, Google Cloud / Firebase)

Un cliente Android admite **una sola huella SHA-1**, pero puede haber varios clientes con el mismo paquete (`com.ournego.app`) y huellas distintas. Google acepta la app si su huella coincide con **cualquiera** de ellos. En Firebase → Configuración del proyecto → app Android → *Agregar huella digital* se crea el cliente por ti.

| Para | Huella a registrar | Estado |
|---|---|---|
| profile y release local y del CI (clave de subida) | `1D:B6:BD:C7:09:4E:B3:6A:22:98:F7:07:B0:E5:CA:EA:51:EA:58:93` | Registrada (cliente `…kjvg…`) |
| debug, una por cada equipo de desarrollo | la de `keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android` | Registrar. En el equipo de referencia: `3B:51:AF:FA:08:B9:92:A9:DA:4D:C1:00:D7:D7:F5:68:AF:2C:1B:0C` |
| Instalación desde Google Play | SHA-1 de la firma de app de Play (Play Console → Integridad de la app) | Pendiente de cuenta de Play, ver OUR-123 |

Existe otro cliente Android (`…b7b1…`) con la huella `BB:B7:1F:6A:…`, que no corresponde a la clave de subida ni a la de debug del equipo de referencia. No se borró; conviene identificar de quién es antes de eliminarlo.

### Cliente web y Supabase

- El código inicializa `GoogleSignIn` con `serverClientId` = cliente **web** `Supabase Web` (`544311850300-ajutqk3e1djlccqiqs0o7a1qsuck5arl…`). Es el valor correcto y no cambia entre modos. Está en `SupabaseAuthDatasource.signInWithGoogle`.
- El ID token se intercambia con `signInWithIdToken`; el proveedor Google de Supabase debe tener ese mismo ID de cliente web.
- `android/app/google-services.json` es de Firebase y no interviene en este login, pero conviene regenerarlo tras añadir huellas para que refleje los clientes.

### Firma local

`android/key.properties` (ignorado por git) alimenta la firma de release y profile. `storeFile` se resuelve **relativo a `android/`**:

```properties
storeFile=app/upload-keystore.jks
storePassword=…
keyAlias=upload
keyPassword=…
```

El CI de release escribe el mismo archivo desde secrets de GitHub, con el keystore en `android/upload-keystore.jks` (`storeFile=upload-keystore.jks`). Como usa la misma clave, no hay que registrar otra huella para él.

### Diagnóstico rápido

Si el login falla, comprobar primero con qué huella se firmó lo instalado y compararla con la tabla:

```bash
$ANDROID_HOME/build-tools/<versión>/apksigner verify --print-certs build/app/outputs/flutter-apk/app-<modo>.apk
```

Un fallo de huella suele llegar como *developer error* (código 10) o "no credentials available". Los cambios de clientes en la consola pueden tardar de minutos a un par de horas en propagarse.

## Pendiente y no verificado

Esta entrega corrige la causa de la firma, pero **no cierra por sí sola los criterios de OUR-129**:

- [ ] Registrar en Firebase/Cloud Console la huella de debug de cada equipo, y confirmarlo.
- [ ] Login con Google en debug, profile y release en un **dispositivo físico**. Solo se comprobó la firma de los APK, no el login en un dispositivo.
- [ ] Cuenta existente inicia sesión y cuenta nueva sigue el flujo de completar perfil.
- [x] Mensaje claro al cancelar o fallar, con reintento y sin exponer el error crudo (tests de widget y de mapeo). Falta verlo en un dispositivo y comprobar el aspecto visual del snackbar con el botón.

Fuera de alcance, con su propia issue: AAB de producción (OUR-120) y validación con la firma de Play (OUR-123).
