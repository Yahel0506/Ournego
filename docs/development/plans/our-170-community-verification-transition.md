# OUR-170 · Transición a verificación comunitaria

Inventario previo a la migración de [OUR-170](https://linear.app/yaheldev/issue/OUR-170/negocios-migrar-la-validacion-con-revision-previa-al-modelo-de). La nueva base de datos y los filtros automáticos pertenecen a [OUR-164](https://linear.app/yaheldev/issue/OUR-164/negocios-publicacion-automatica-con-filtros-y-base-de-datos-de). OUR-170 también requiere ejecutar su propio dry-run SQL con `rollback` antes de aplicar cambios. Después, [OUR-171](https://linear.app/yaheldev/issue/OUR-171/pruebas-actualizar-pruebas-sql-recorrido-integral-y-documentacion-al) actualiza las suites SQL, el recorrido integral y la documentación del flujo nuevo.

## Inventario y decisión

| Pieza vigente | Conservar o adaptar | Retirar cuando la nueva ruta cubra el mismo caso |
| --- | --- | --- |
| `businesses.status`, `business_status` y políticas de [2026-11-05](../../sql/2026-11-05_business_review_status.sql) | Conservar el predicado público actual `status = 'approved' and is_active is not false`. Añadir `under_review` al enum en OUR-164. Por definición, el estado nuevo sigue oculto bajo la política pública existente. Revisar y probar ese resultado sin relajar el predicado. | — |
| Tabla `reviewers`, `is_reviewer()` y políticas de lectura | Conservar el registro de revisores y sus permisos, junto con el permiso del dueño para consultar sus fichas en cualquier estado. La base decide ambos accesos por identidad y rol. | — |
| `is_business_public` y políticas de horarios, productos y excepciones | Conservar `is_business_public` con `status = 'approved' and is_active is not false`, las políticas de revisor y las políticas de dueño vigentes en cada tabla hija. Verificar que la lectura pública de los registros relacionados se limite a fichas visibles. | — |
| Política de inserción del dueño | Conservar la autoría autenticada. OUR-164 determina si la fila nueva se crea directamente `approved` o `pending` según los filtros del servidor. | La obligación universal de crear cada alta como `pending`, solo al aplicar con seguridad el filtro nuevo. |
| `enforce_business_status_change` de [2026-11-06](../../sql/2026-11-06_business_review_requests.sql) y [2026-11-07](../../sql/2026-11-07_business_review_decisions.sql) | Adaptar en una única transición autoritativa en servidor, conservando los filtros de estado para impedir que una decisión obsoleta sobrescriba otra. Moderación solo decide `pending` (aprobar/rechazar), retira `approved` y resuelve `under_review` hacia `approved` o `withdrawn`. El revisor no decide su propio negocio. El dueño conserva retirada y reenvío permitidos. | Devolver a `pending` automáticamente todo negocio `approved` cuando cambia un dato público, después de que los filtros de OUR-164 puedan volver a evaluar ese cambio. |
| `stamp_business_submission` y fechas `submitted_at`, `reviewed_at` | Conservar la autoría/fechas y sus reglas de escritura de servidor para transiciones manuales y nuevas altas en cola. Acordar con OUR-164 las fechas y autores de auto-publicación antes de tocar el trigger. | El requisito de que cada alta pase por la cola para poder asignar una fecha. |
| `business_review_log`, RLS y trigger `log_business_status_change` de [2026-11-07](../../sql/2026-11-07_business_review_decisions.sql) | Conservar el historial append-only y la lectura por dueño y revisor. Registrar los cambios automáticos con `actor_role = 'system'`. Distinguir las acciones de dueño y revisor según la transición y conservar el actor y la razón del historial previo. | — |
| Paneles y estados Flutter | Adaptar `BusinessReviewStatus`, su conversión `fromWire` y los textos a los cinco estados: `pending`, `approved`, `under_review`, `rejected`, `withdrawn`. Adaptar `register_business_screen.dart`, `RegisterBusinessUsecase`, `BusinessRepositoryImpl`, `BusinessSupabaseDatasource`, el panel y el botón de reenvío a publicación inmediata o a razón de cola. | Mensaje de “enviar a revisión” como resultado normal del alta y mensajes que prometen aprobación previa. |
| Revisión manual y validaciones de [OUR-114](../../../lib/features/moderation/README.md) | Adaptar `ModerationScreen`, `ReviewListingCard`, `ReviewDecision.requiredStatus`, `SupabaseModerationDatasource` y el historial para la cola de excepciones. Llevar filtros de `ListingChecker` y `CheckListingBeforeApprovalUsecase` a las altas y ediciones del servidor. Mostrar resultados de duplicados en tarjetas `pending`. Mantener decisión obsoleta protegida por condición de estado. | La validación de datos solo al aprobar, una vez el servidor la aplique al crear y editar. |
| Mapa, búsqueda y detalle | Conservar la selección explícita de fichas visibles en `SupabaseMapDatasource.getBusinesses` y `getBusinessById`. `SearchBusinessesUsecase` filtra la lista que recibe del mapa. Verificar los cuatro estados ocultos en búsqueda y enlace directo. | — |

## Ediciones de negocios publicados

Para editar nombre, categoría, dirección, coordenadas, contacto, imágenes u horarios, el trigger debe aplicar en servidor el contrato de filtros y campos que defina OUR-164. Si pasan, el negocio sigue `approved`; si fallan, vuelve `pending`. Contacto y horario no deben quedar excluidos solo porque el trigger anterior no los comparaba. Si cambia nombre, ubicación o categoría, limpiar la verificación de comunidad para reevaluar el negocio. Conservar los datos y el historial anterior durante la migración.

## Censo de datos antes de DDL

El 19 de noviembre de 2026, una consulta con acceso a todas las filas del proyecto Ournego en Supabase confirmó **7 `approved`, 0 `pending`, 0 `rejected` y 0 `withdrawn`**. El enum tiene cuatro estados. La tabla `trust_settings` y las columnas `published_at`, `verified_at` y `verification_paused` siguen pendientes de OUR-164. La consulta de políticas confirmó que RLS está habilitada en `businesses`, que la política pública exige `approved` e `is_active is not false` y que existen políticas públicas en las tres tablas relacionadas.

Para repetir el censo justo antes de la migración, usar una conexión de solo lectura con acceso a todas las filas de `public.businesses`:

```sql
BEGIN READ ONLY;

SELECT status::text AS status, count(*) AS total
FROM public.businesses
GROUP BY status::text
ORDER BY status::text;

ROLLBACK;
```

Conservar las siete fichas activas en `approved`. Las siete tienen `reviewed_at` nulo, así que el backfill desde este campo dejará `published_at` nulo para todas. Si se necesita una fecha histórica, acordar la fuente antes de cambiar los datos. Si aparecen otras fichas en el siguiente censo, preservar su estado, motivo e historial y resolver su destino antes de cambiarlos. Registrar únicamente los conteos por estado.

## Dry-run y alcance de OUR-171

Ejecutar el dry-run de OUR-170 dentro de una transacción con `rollback` antes de aplicar la migración. Comprobar visibilidad pública, permisos del dueño y revisor, decisiones obsoletas, negocio propio e historial. Después, OUR-171 actualiza los tests SQL de OUR-111/112/113, documenta los resultados y completa el recorrido con cuentas independientes.

## Activación de OUR-164 y OUR-170

El alta nueva sube la foto con un nombre único y envía la ficha y los horarios mediante `submit_business_listing`. El servidor publica en la misma transacción cuando el perfil está completo y los filtros pasan. Una cuenta nueva cumple esta regla desde el primer día. Las versiones que todavía guardan la foto y los horarios en solicitudes separadas conservan el alta en revisión.

El piloto usa el polígono urbano de Ciudad Guzmán, clave `140230001`. La lista editable de palabras empieza vacía. En las fichas aprobadas históricas, la ausencia de una foto se conserva cuando se editan otros campos. Una foto válida se exige en el alta nueva, al cambiar las imágenes o al aprobar una solicitud pendiente. [Polígono de INEGI](https://gaia.inegi.org.mx/wscatgeo/v2/geo/localidades/pol/14/023/U)

1. Aplicar y confirmar [la migración del enum](../../sql/2026-11-19_business_under_review_status.sql).
2. Aplicar [la migración de publicación y moderación](../../sql/2026-11-19_business_trust_submission.sql). Configurar `private.trust_settings.storage_public_origin` con el origen HTTPS exacto del proyecto Supabase. Mantener el esquema `private` fuera de los esquemas expuestos por PostgREST.
3. Verificar el conteo del catálogo, las políticas públicas y el acceso al RPC. Desplegar después el cliente que reconoce los cinco estados y consume el nuevo contrato.

La [prueba SQL con rollback](../../sql/tests/2026-11-19_business_trust_submission_test.sql) pasó en PostgreSQL 17 con PostGIS y las migraciones históricas de RLS. Cubrió el alta atómica, los cupos, los filtros, el historial, los permisos y las transiciones. Flutter pasó el análisis y 579 pruebas.

Aplicadas en Supabase Ournego el 19 de noviembre de 2026, hora de Ciudad de México. Se verificaron las siete fichas aprobadas sin cambios en estado ni imágenes, el origen de Storage, los cupos, la lista de términos vacía y los permisos del RPC y de las políticas públicas.
