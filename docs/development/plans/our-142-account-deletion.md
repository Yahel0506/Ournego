# OUR-142 — Dimensionamiento de la cadena de eliminación de cuenta

Estado: decisiones D1–D10 tomadas el 2026-10-16. Pendiente solo el plazo de las copias de seguridad (P4), que bloquea la publicación del texto de la política pero no el resto del trabajo.

Issue: OUR-142. Cadena: OUR-108 (padre) → OUR-137, OUR-138, OUR-136, OUR-139. Requisito: eliminación de cuenta de Google Play (URL pública en la ficha).

## Decisiones

| # | Decisión | Estado |
|---|---|---|
| D1 | Las reseñas del usuario se **borran por completo**. | Tomada |
| D2 | `feedback` y `user_interactions` del usuario se **borran** (no se anonimizan). | Tomada |
| D3 | Se borran también los archivos de Storage asociados (avatar, adjuntos de feedback). | Derivada de D2 |
| D4 | Verificación con el correo de Supabase Auth, sin proveedor nuevo: la página pública llama a `signInWithOtp(email, shouldCreateUser: false, emailRedirectTo: /auth/callback?next=/delete-account/confirm)`. El enlace del correo pasa por el callback SSR que ya existe en `ournego-web` (`verifyOtp` con `token_hash`, cookies de sesión, `next` seguro) y abre una sesión temporal. En `/delete-account/confirm` la persona pulsa "Confirmar eliminación" (no se actúa al abrir el enlace, para que un escáner de correo no dispare nada), la página llama a la RPC `request_account_deletion()` (usa `auth.uid()`) y cierra la sesión. Supabase se encarga de token, caducidad y límite por correo. La página muestra siempre el mismo mensaje exista o no la cuenta. Funciona igual para cuentas de Google, siempre que usen ese correo. Alternativa si el enlace diera problemas: código `{{ .Token }}` introducido en la página. | Tomada |
| D5 | Periodo de gracia de **30 días** para recuperar la cuenta. Al verificar, la solicitud pasa a `scheduled` con `execute_after = now() + 30 días`, se revocan las sesiones y los negocios se ocultan (`is_active = false`). Un trabajo de `pg_cron` ejecuta la eliminación al vencer el plazo. | Tomada |
| D10 | Recuperar la cuenta tiene dos vías, ambas válidas solo mientras `execute_after` no haya pasado y ambas restauran los negocios: (a) la misma página web, con la opción "Cancelar eliminación", que reutiliza el flujo de código de D4 y llama a `cancel_my_deletion()` (Supabase Auth no permite enviar un correo de confirmación con enlace propio sin un proveedor aparte); (b) iniciar sesión en la app, que cancela la eliminación con esa misma RPC y muestra un aviso ("Tu cuenta estaba programada para eliminarse; la restauramos"). | Tomada |
| D6 | Los negocios del usuario se borran con la cuenta, junto con horarios, productos, excepciones, favoritos y vistas de terceros. | Tomada |
| D7 | Se conserva un registro mínimo de la solicitud (hash SHA-256 del correo, fechas, estado, sin el correo en claro) durante 12 meses, como prueba de cumplimiento. | Tomada |
| D8 | Las filas de `beta` con el mismo correo se borran. | Tomada |
| D9 | Las copias de seguridad de Supabase no se purgan; la política de privacidad debe decir cuánto tardan en caducar. | Tomada; el plazo está por definir (P4) |

## Inventario de datos (Supabase `Ournego`, auditado el 2026-10-16)

Hoy: 34 usuarios, 7 negocios, 0 reseñas. Sin triggers en `public`. Sin Edge Functions. Buckets: `businesses_pictures` (público), `profile_pictures` (público), `feedback_attachments` (privado).

| Dato | Relación con `auth.users` | Qué pasa hoy al borrar | Qué debe pasar |
|---|---|---|---|
| `auth.*` (sesiones, identidades, tokens) | CASCADE | Se borra | Igual |
| `public.users` (nombre, avatar) | CASCADE | Se borra | Igual; borrar antes el archivo de `profile_pictures` |
| `businesses` (`owner_id`) | CASCADE | Se borra, con horarios, productos, excepciones, reseñas, favoritos e interacciones (CASCADE desde `businesses`) | D6; borrar antes sus imágenes de `businesses_pictures` |
| `businesses_views` (`user_id`) | CASCADE | Se borra | Igual |
| `businesses_views` (`business_id`) | NO ACTION hacia `businesses` | **Bloquea** el borrado de un negocio con vistas | Borrar sus vistas antes que el negocio |
| `user_favorites` | CASCADE | Se borra | Igual |
| `reviews` (`user_id`) | NO ACTION | **Bloquea** el borrado de la cuenta | D1: borrar las reseñas antes; recalcular `average_rating` y `total_reviews` de los negocios ajenos afectados (no hay trigger que lo haga) |
| `feedback` (`user_id`) | SET NULL | Queda huérfano con el mensaje y el adjunto | D2: borrar filas y el archivo de `feedback_attachments` |
| `user_interactions` (`user_id`) | SET NULL | Queda huérfano | D2: borrar |
| `beta` (`email`) | Ninguna (correo suelto) | No se toca | D8: borrar por correo |

Nota: los adjuntos de feedback no llevan el id de usuario en el nombre (`feedback_<timestamp>_<hash>.png`); hay que resolverlos desde `feedback.attachment`. Verificar en OUR-138c el formato real de `users.avatar_url` y `businesses.images` antes de borrar por ruta.

## Estado de OUR-152 (138c, ejecución)

- `docs/sql/2026-10-26_delete_user_data.sql`: `delete_user_data(uid)` (transaccional, idempotente) y `account_deletion_storage_paths(uid)`. Solo `service_role`.
- `supabase/functions/execute-account-deletion/`: Edge Function (desde OUR-153 con `verify_jwt = false`; hace su propia comprobación: token de un solo uso del trabajo programado o clave de servicio). Orden: archivos de Storage, `delete_user_data`, `auth.admin.deleteUser`, `completed`. Si algo falla queda en `failed` y se puede reintentar. Entrada: `POST {"request_id": "<uuid>"}`; la llamará el trabajo de OUR-153.
- Formatos verificados: avatar `profile_pictures/<uid><ext>`; `businesses.images` es `text[]` de URL públicas de `businesses_pictures/<business>/<archivo>`; `feedback.attachment` es la URL pública completa.
- Pruebas: `docs/sql/tests/2026-10-26_delete_user_data_test.sql`.

## Estado de OUR-153 (138d, cancelación y trabajo programado)

- `docs/sql/2026-10-27_cancel_and_schedule_account_deletion.sql`, aplicada en el proyecto `Ournego`. Habilita `pg_cron` y `pg_net`.
- `cancel_my_deletion()` (usuario autenticado): cancela la solicitud `scheduled` (o `pending`) mientras `execute_after` no haya pasado, restaura solo los negocios que ocultó la solicitud y que siguen siendo del usuario, y devuelve `true` si cambió algo. Fuera de plazo devuelve `false` y no toca nada. Es la RPC que usan la web (OUR-158) y la app (OUR-154).
- Trabajo `execute-due-account-deletions` cada 15 minutos: `dispatch_due_account_deletions()` envía con `pg_net` las solicitudes vencidas y reintenta las `failed` (otra vez a la hora, máximo 5 envíos; después quedan en `failed` para revisarlas a mano). Lotes de 20.
- Autenticación del trabajo sin guardar la clave de servicio en la base: cada envío lleva un token aleatorio de un solo uso; la tabla `account_deletion_dispatches` (sin acceso desde la API) guarda su hash y la Edge Function lo consume con `consume_account_deletion_dispatch()` (válido 15 minutos). La clave de servicio sigue sirviendo para ejecutar a mano.
- La Edge Function ya no ejecuta una solicitud `scheduled` antes de `execute_after` (responde `409 not_due`), así que no puede adelantarse a una cancelación.
- Trabajo `purge-expired-account-deletion-requests` diario (03:17 UTC): aplica la retención de 12 meses de OUR-138.
- Configuración única por proyecto: secreto de Vault `project_url` (`select vault.create_secret('https://<ref>.supabase.co', 'project_url')`), ya creado en `Ournego`.
- Plazo configurable para probar sin esperar 30 días (afecta a las solicitudes nuevas): `update public.account_deletion_settings set grace_period = '5 minutes';` y volver con `... = '30 days'`. Sustituye al `alter database ... set app.account_deletion_grace_period` de OUR-151, que Supabase no permite (`permission denied to set parameter`); ese parámetro solo sigue valiendo dentro de una sesión (`set_config`, lo usan las pruebas). Para ejecutar sin esperar al siguiente cuarto de hora: `select public.dispatch_due_account_deletions();`. La respuesta de cada envío queda en `net._http_response` (id en `account_deletion_dispatches.net_request_id`).
- Pruebas: `docs/sql/tests/2026-10-27_cancel_and_schedule_account_deletion_test.sql` (cancelación en plazo, cancelación tardía rechazada, envío al vencer, reintento, límite de intentos, token de un solo uso). Verificado además de extremo a extremo con una solicitud sin usuario: el trabajo la envió, la función respondió 200 y quedó `completed`.

## Qué se retiene

| Dato | Plazo | Motivo |
|---|---|---|
| Todos los datos de la cuenta (perfil, negocios ocultos, reseñas, feedback, interacciones, archivos) | 30 días desde la verificación | Periodo de gracia para recuperar la cuenta (D5) |
| Registro de la solicitud (hash del correo, fechas, estado) | 12 meses | Demostrar el cumplimiento ante Google Play o ante la persona |
| Copias de seguridad de Supabase | Según el plan contratado (confirmar) | Recuperación ante desastre; no se editan |
| Registros de envío de Supabase Auth y del SMTP configurado | Según el proveedor | Entrega del código de verificación |

Todo lo demás se elimina. Estos textos deben coincidir con la política de privacidad (criterio de OUR-137).

## Orden y dependencias

```
OUR-138a  tabla de solicitudes + RLS ───┬──► OUR-137  página web pública (código OTP)
          (decisiones en papel)         └──► OUR-138b  RPC request_account_deletion + SMTP + límites
                                                │
                                      OUR-138c  ejecución (función SQL + Edge Function)
                                                │
                                      OUR-138d  RPC cancel_my_deletion + trabajo pg_cron
                                                │
                              ┌─────────────────┼──────────────────────┐
                           OUR-136 entrada    NUEVO (app)           OUR-139 prueba
                           en ajustes         cancelar al iniciar   extremo a extremo
                                              sesión y avisar       (también depende
                                                                    de 137 y del nuevo)
```

1. Cerrar las decisiones de este documento (OUR-142).
2. **OUR-138a**: tabla `account_deletion_requests`, estados y RLS. OUR-137 la necesita para guardar la solicitud como pendiente.
3. **OUR-137** y **OUR-138b** en paralelo.
4. **OUR-138c**: función SQL transaccional + Edge Function de ejecución.
5. **OUR-138d**: cancelación por RPC y trabajo programado. Desbloquea a OUR-136 y al issue nuevo. La opción "Cancelar eliminación" de la página web (OUR-137) se conecta aquí.
6. En paralelo, ambos en la app:
   - **OUR-136**: el punto de entrada en ajustes abre la URL pública con el correo precargado, de modo que el flujo verificable es uno solo. Sin cambios de alcance.
   - **Issue nuevo `[Cuenta] Cancelar la eliminación al iniciar sesión y avisar`** (2 pts, hijo de OUR-108): tras iniciar sesión (correo o Google), llama a `cancel_my_deletion()`; si cancela algo, muestra un aviso con `showOurnegoDialog`. Debe cubrir también la sesión restaurada al abrir la app. Hay que decidir cómo convive con la guarda de perfil de `app_router.dart`.
7. **OUR-139**: prueba de extremo a extremo (solicitar, verificar, cancelar por enlace, cancelar al iniciar sesión, vencer el plazo, ejecutar) y evidencia de retenciones. El plazo debe ser configurable para poder probarlo sin esperar 30 días.

`pg_cron` y `pg_net` se habilitaron en OUR-153 (138d); `pgmq` sigue sin instalar.

## OUR-137 en `ournego-web`

La página pública vive en el proyecto Next.js (`ournego-web`, repositorio aparte; PRs allí). Ya tiene el cliente Supabase SSR, el callback `/auth/callback`, `/privacy-policy` y el flujo de recuperación de contraseña, así que se reutiliza todo eso. Alcance:

- Módulo `src/features/account-deletion/` con la estructura de `reset-password` (domain, application, infrastructure, presentation). Se pensó así porque el sitio crecerá hasta replicar la app: la eliminación quedará como una función más de cuenta.
- Rutas en el grupo `(marketing)`, con nombres en inglés como `/privacy-policy`: `/delete-account` (formulario de correo, mismo mensaje exista o no la cuenta), `/delete-account/confirm` (confirmar eliminación o cancelar la programada, con la fecha de ejecución) y la entrada en el pie. La URL de Play es `https://www.ournego.com/delete-account`.
- Sección nueva en `/privacy-policy` sobre eliminación, plazo de 30 días, retenciones y copias de seguridad (hoy la política no menciona la eliminación).
- Mantener la regla de `next` seguro del callback y que los tokens no queden en la URL final.

Sube de 2 a 3 pts porque incluye la política y las dos pantallas (eliminar y cancelar).

## División de OUR-138 (hoy 5 pts, pasa a 7)

Issues en Linear: 138a = OUR-138 (retitulado), 138b = OUR-151, 138c = OUR-152, 138d = OUR-153. El issue de la app para cancelar al iniciar sesión es OUR-154.

| Pieza | Contenido | Pts |
|---|---|---|
| 138a | Tabla, estados (`pending`, `scheduled`, `cancelled`, `completed`, `failed`), RLS (insertar solo vía función, sin lectura pública), limpieza de caducadas | 1 |
| 138b | RPC `request_account_deletion()` (idempotente; `scheduled`, sesiones revocadas, negocios ocultos), ajuste de la plantilla de magic link para que el correo de eliminación no diga "inicia sesión" (la plantilla actual es compartida; se puede bifurcar con `{{ if eq .RedirectTo "…" }}`, a verificar), límites por correo e IP, comprobar el SMTP, pruebas de RLS | 2 |
| 138c | Función `delete_user_data(uid)` en una transacción, borrado de Storage, `auth.admin.deleteUser`, reintento idempotente, estado final | 2 |
| 138d | RPC `cancel_my_deletion()` para usuarios autenticados (restaura negocios), trabajo `pg_cron` que ejecuta las vencidas, plazo configurable | 2 |

El periodo de gracia añade 2 pts a la cadena. Cada pieza cabe en un PR revisable; 138a/138b avanzan aparte de 138c/138d.

## Estimaciones

| Issue | Actual | Propuesta |
|---|---|---|
| OUR-136 | 1 | 1 |
| OUR-137 | 2 | 3 (ver "OUR-137 en ournego-web"). Ajustar su criterio 2: la solicitud no se guarda antes de verificar el correo (hacerlo permitiría llenar la tabla de solicitudes anónimas); se guarda como `scheduled` al verificar |
| OUR-138 | 5 | Se divide en 138a (1), 138b (2), 138c (2), 138d (2) = 7 |
| Nuevo (app): cancelar al iniciar sesión y avisar | — | 2 |
| OUR-139 | 2 | 2 (cubre también la cancelación al iniciar sesión) |
| OUR-108 | sin estimar | Sin estimación: es el padre y los puntos están en los hijos, así que no se cuentan dos veces. Regla: un padre que solo agrupa no se estima |

Total de las piezas hijas: 1 + 3 + 7 + 2 + 2 = 15 pts, frente a los 10 pts estimados antes (1 + 2 + 5 + 2).

## Criterios de salida de OUR-108, revisados

Los tres criterios actuales se mantienen. Se añade un cuarto, que falta hoy:

- [ ] La URL pública está declarada en la ficha de Play y responde sin sesión.
- [ ] Tras ejecutar la eliminación no queda en Supabase ningún dato del usuario salvo lo listado en "Qué se retiene".

## Preguntas abiertas

- ~~**P1.**~~ Resuelta: los negocios se borran con la cuenta (D6).
- ~~**P2.**~~ Resuelta: periodo de gracia de 30 días (D5).
- ~~**P2b.**~~ Resuelta: enlace del correo e inicio de sesión (D10).
- ~~**P3.**~~ Resuelta: correo de Supabase Auth con código (D4).
- ~~**P6.**~~ Resuelta: la página vive en `ournego-web` (Next.js).
- ~~**P7.**~~ Resuelta: el proyecto tiene SMTP propio, así que no hay límite de envío del SMTP predeterminado.
- ~~**P8.**~~ Resuelta: ruta `/delete-account` y OUR-137 incluye la sección nueva de la política de privacidad.
- **P4 (abierta).** No hay plazo definido para las copias de seguridad. Hay que consultar qué retención da el plan de Supabase contratado y decidir qué se declara. Se resuelve antes de publicar la política (OUR-137) y se registra en OUR-139 como retención documentada.
- ~~**P5.**~~ Resuelta: OUR-108 sin estimación (ver "Estimaciones").
