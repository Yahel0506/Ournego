# OUR-139 — Prueba de extremo a extremo de la eliminación de cuenta y retenciones

Fecha de la prueba: 2026-10-30 (UTC). Proyecto Supabase `Ournego`, web `https://www.ournego.com`. Plan: `our-142-account-deletion.md`.

## Método

- Plazo reducido: `account_deletion_settings.grace_period = '5 minutes'` durante la prueba (restaurado a `30 days` al terminar).
- Tres cuentas sembradas con prefijo `13900000-…`:
  - **A** (proveedor correo) y **B** (proveedor Google, sin contraseña), cada una con perfil y avatar, un negocio con imagen, reseña, favorito, vista, interacción, feedback con adjunto y fila de `beta`.
  - **C** (tercero, no se elimina por flujo): dueña de un negocio con reseñas de A y B, para comprobar el recálculo de calificaciones.
- El tramo de correo usó un buzón real (`+our139a`, `+our139b` en la cuenta de pruebas).
- La ejecución se disparó con `select public.dispatch_due_account_deletions();` (la función que llama `pg_cron` cada 15 minutos).

## Resultados por criterio

| Criterio | Resultado | Cómo |
|---|---|---|
| Solicitar, verificar y ejecutar con plazo reducido | **Cumple** (cuenta A) | Correo de Auth con enlace → `/auth/callback` → `/delete-account/confirm` → "Confirmar eliminación": solicitud `scheduled` con `execute_after` a 5 min, negocios `is_active = false`, sesiones revocadas. Al vencer, el envío llamó a la Edge Function y la solicitud quedó `completed`. |
| Cancelar desde la web dentro del plazo | **Parcial** | La RPC `cancel_my_deletion()` (la que usa la web) devolvió `true` en plazo y la solicitud quedó `cancelled`. No se pulsó el botón "Cancelar eliminación" de la página: el enlace del correo de B no se llegó a abrir (token sin usar) y no se repitió. Pendiente un clic manual. |
| Cancelar iniciando sesión en la app (aviso incluido) | **Parcial** | Misma RPC como usuario autenticado de B. La pantalla y el aviso se cubren con los 27 tests de `test/features/auth` (todos pasan). No se probó en dispositivo ni emulador: requiere iniciar sesión con Google real. |
| Cuenta de correo y cuenta de Google | **Cumple con matiz** | A (correo) siguió todo el flujo por web. B (Google) se solicitó, canceló, volvió a solicitar y ejecutó llamando a las RPC como esa cuenta; el enlace del correo es el mismo para ambos proveedores. |
| Sin datos al final salvo lo declarado | **Cumple** | Ver "Residuos" abajo. |
| URL de Play responde sin sesión | **Cumple** | `GET /delete-account` y `/delete-account/confirm`: 200 sin cookies; `/privacy-policy` también. |

## Residuos tras ejecutar (A y B)

Consultas sobre los ids de prueba tras `completed`: `auth.users`, `auth.identities`, `auth.one_time_tokens`, `public.users`, `businesses`, `reviews`, `feedback`, `user_interactions`, `user_favorites`, `businesses_views`, `beta` y `storage.objects` (avatar, imagen de negocio y adjunto): **0 filas** en ambas cuentas. Las calificaciones del negocio de C se recalcularon (de 3 reseñas / 2.67 a 1 reseña / 5.0, al irse A y B). Los conteos globales volvieron a la línea base (34 usuarios, 7 negocios, 1 feedback, 228 interacciones, 15 objetos de Storage).

Lo que sí queda: las filas de `account_deletion_requests` (ver abajo).

## Hallazgos

1. **Dato no declarado en el registro retenido (corregido).** La solicitud `completed` conservaba `hidden_business_ids` (ids de negocios ya borrados). La política declara solo huella del correo, fechas y estado. `2026-10-30_clear_hidden_business_ids_on_completion.sql` vacía la lista al pasar a `completed` o `cancelled` (la RPC de cancelar la lee antes) y limpia las filas previas. Aplicada en el proyecto; prueba en `docs/sql/tests/2026-10-30_clear_hidden_business_ids_test.sql`.
2. **Copias de seguridad (P4 de OUR-142).** La organización está en el plan **Free**: Supabase no hace copias diarias de la base ni ofrece descargarlas (Pro: 7 días, Team: 14, Enterprise: hasta 30; las copias no incluyen los archivos de Storage, solo sus metadatos). Hoy no hay copias de plataforma que caduquen; los "30 días como máximo" de la política son una cota superior válida en todos los planes. Si se pasa a Pro, el plazo real sería 7 días. Si se hacen volcados manuales (`supabase db dump`), hay que borrarlos o contarlos como copia.
3. **Sembrar `auth.users` a mano** exige `instance_id` y las columnas de token (`confirmation_token`, `recovery_token`, `email_change*`, `phone_change*`, `reauthentication_token`) en cadena vacía; si no, Auth responde `otp_disabled` o 500 "Database error finding user". Útil para futuras pruebas.
4. **Archivos de Storage:** los objetos de prueba eran filas de metadatos sin archivo físico. Se comprobó que la función los quita; la baja de archivos reales ya la cubrió OUR-152.

## Retenciones y coincidencia con `/privacy-policy`

| Dato | Plazo medido/declarado | En `/privacy-policy` (sección 13.2) |
|---|---|---|
| Datos de la cuenta | Hasta `execute_after` (30 días en producción), después 0 filas | "Plazo de gracia de 30 dias" ✔ |
| Registro de la solicitud | Hash SHA-256 del correo, fechas, estado, 12 meses; purga diaria 03:17 UTC (`purge-expired-account-deletion-requests`) | "huella criptografica del correo, fechas y estado… 12 meses" ✔ (tras el hallazgo 1) |
| Copias de seguridad de Supabase | Plan Free: sin copias de plataforma; tope declarado 30 días | "caducan… en un maximo de 30 dias" ✔ como cota |
| Registros de envío de Auth/SMTP | Según el proveedor | "registros de envio… segun el plazo de cada proveedor" ✔ |

Constantes del sitio: `DELETION_GRACE_PERIOD_DAYS = 30`, `DELETION_RECORD_RETENTION_MONTHS = 12`, `BACKUP_RETENTION_DAYS = 30`, coherentes con la base.

## Pendiente de verificación manual

- Pulsar "Cancelar eliminación" en `/delete-account/confirm` con un enlace real (plazo vigente).
- Iniciar sesión en la app con una cuenta programada y ver el aviso en dispositivo.
- Decidir si el aviso del correo ("se conservará 30 días") debe reflejar el plazo configurado; hoy el texto es fijo.
