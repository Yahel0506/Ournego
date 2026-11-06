# OUR-159 — Verificación en dispositivo real: cancelar la eliminación y enlace de Google

Fecha de preparación: 2026-11-05. Origen: "Pendiente de verificación manual" de `docs/development/plans/our-139-account-deletion-e2e.md`.
Estado: **parcial**. Lo automatizable está hecho; los tres criterios de dispositivo siguen **pendientes** y necesitan a la persona con un Android físico y las cuentas reales.

## Qué se pudo verificar sin dispositivo

| Revisión | Resultado |
|---|---|
| `flutter test test/features/auth` (incluye `account_restore_test.dart` y `account_restored_listener_test.dart`) | 36 tests, todos pasan |
| Revisión de `AccountRestoreNotifier` (`lib/features/auth/presentation/providers/account_restore_providers.dart`) | Llama a `cancel_my_deletion()` en `signedIn`, `initialSession` y `tokenRefreshed`; un fallo de red se reintenta en el siguiente evento; `signedOut` limpia el estado. Sin defectos. |
| Revisión del aviso (`account_restored_listener.dart`) | Se muestra con `showOurnegoDialog` ("Restauramos tu cuenta", botón "Entendido") solo en una ruta estable y se reconoce al cerrarlo. Sin defectos. |
| Revisión de la web (`ournego-web`, `origin/main`, PR #9 / OUR-158) | `/delete-account/confirm` ofrece "Cancelar eliminacion programada", que llama a `cancel_my_deletion()` con la sesión del enlace, cierra la sesión local y muestra el mismo mensaje haya o no eliminación programada. Actúa solo con clic explícito (los escáneres de correo no disparan nada). Sin defectos. |
| Emulador Android | No aplica: ambos flujos exigen una cuenta real (Google no se puede iniciar en un emulador de pruebas sin cuenta real, y el correo requiere el buzón real). |

No se encontraron hallazgos nuevos, así que no se abrió ningún issue. Si el dispositivo revela alguno, se registra como issue nuevo (no se arregla en OUR-159).

## Criterios pendientes en dispositivo real

Requisitos: un Android físico con la build de la rama `main` (`flutter run --dart-define-from-file=.env` o el APK de la beta), acceso al buzón de las cuentas de prueba y a Supabase (SQL editor) para acortar el plazo.

Preparación (una vez):

1. En Supabase: `update account_deletion_settings set grace_period = '30 minutes';` (restaurar a `'30 days'` al terminar).
2. Cuenta A (correo) y cuenta B (Google) de prueba, cada una con perfil completo y un negocio.

### Criterio 1 — Enlace real del correo → "Cancelar eliminación"

1. En `https://www.ournego.com/delete-account` escribe el correo de A y envía.
2. Abre el correo en el teléfono y toca el enlace → debe abrir `/delete-account/confirm` con los botones "Confirmar eliminacion" y "Cancelar eliminacion programada".
3. Toca "Confirmar eliminacion" → mensaje "Listo. Tu cuenta se eliminara el …".
4. Pide otro enlace (paso 1–2) y toca "Cancelar eliminacion programada".
5. Comprueba: `select status from account_deletion_requests order by created_at desc limit 1;` → `cancelled`; `businesses.is_active = true` para A; A puede iniciar sesión.
6. Evidencia: capturas `01a_enlace_correo.jpg`, `01b_confirmada.jpg`, `01c_cancelada.jpg` y el resultado de la consulta.

### Criterio 2 — Iniciar sesión en la app cancela y avisa

1. Con A en estado `scheduled` (pasos 1–3 anteriores), abre la app y entra con correo y contraseña antes de `execute_after`.
2. Esperado: diálogo "Restauramos tu cuenta" → "Entendido"; la solicitud pasa a `cancelled` y el negocio vuelve a mostrarse.
3. Variante: programar de nuevo, abrir la app con una sesión previa restaurada (cerrar y abrir) y comprobar el mismo aviso.
4. Evidencia: `02a_aviso_restaurada.jpg`, `02b_solicitud_cancelled.jpg`.

### Criterio 3 — Cuenta de Google: solicitud, confirmación y programación

1. Con B (Google), `https://www.ournego.com/delete-account` con el correo de Google, abrir el enlace del correo en el teléfono.
2. "Confirmar eliminacion" → solicitud `scheduled` con `execute_after` a 30 min.
3. Abre la app, entra con Google → aviso "Restauramos tu cuenta" (también cubre el inicio con Google del criterio 2).
4. Evidencia: `03a_enlace_google.jpg`, `03b_programada.jpg`, `03c_aviso_google.jpg`.

### Cierre

- Restaurar `grace_period = '30 days'`.
- Guardar las capturas (comprimidas a 540×1170) en `docs/development/testing/evidence/our-159/`, como en OUR-140, y completar la tabla siguiente.

| Criterio | Resultado | Evidencia |
|---|---|---|
| 1. Enlace del correo → cancelar | Pendiente | — |
| 2. Inicio de sesión en la app cancela y avisa | Pendiente | — |
| 3. Google: solicitud, confirmación, programación | Pendiente | — |
