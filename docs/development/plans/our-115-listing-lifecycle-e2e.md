# OUR-115 - Verificación de alta, revisión y retirada con Supabase real

Fecha: 2026-11-10. Proyecto Supabase `Ournego` (el único; no hay entorno de pruebas aparte).
Script: `docs/sql/tests/2026-11-10_listing_lifecycle_e2e_test.sql`.

## Método

Un único bloque `DO` que simula, con `set local role` y `request.jwt.claims` (como PostgREST),
cuatro actores independientes: dueño, otra cuenta, revisor y anónimo. Siempre termina con una
excepción, así que **se revierte entero**: no se creó ningún dato real ni se tocó el catálogo.
Tras la ejecución: 0 negocios, usuarios, revisores y filas de log de prueba; el catálogo sigue
igual.

## Resultado por criterio

| Criterio | Resultado |
|---|---|
| Alta pendiente invisible en mapa, búsqueda y enlace directo; aprobación visible | **Cumple** (anon y otra cuenta no ven la ficha pendiente por id ni por nombre; tras aprobar, anon la ve por ambos). |
| Rechazo corregible y retirada invisible sin datos residuales públicos | **Cumple**. Rechazar exige motivo; el dueño lo ve, corrige y reenvía (motivo se limpia). Editar datos públicos de una ficha aprobada la devuelve a revisión. Tras retirar, anon no ve ficha, horarios, productos ni excepciones. |
| Lecturas y decisiones con roles no autorizados denegadas | **Cumple**. Otra cuenta y el propio dueño no pueden aprobar; el dueño no puede insertar como `approved`; anon no lee `business_review_log`. |

El log registró toda la línea de tiempo: `-›pending, pending›rejected, rejected›pending,
pending›approved, approved›pending, pending›approved, approved›withdrawn`.

## Límites

- Verificación a nivel de base de datos y RLS (lo mismo que ven la app y el mapa vía PostgREST).
  No se probó la UI ni un dispositivo Android.
- Depende de OUR-114 (validación y duplicados antes de aprobar), que sigue en *Todo*: esta
  prueba no cubre ese tramo.
- Las imágenes en Storage de fichas no publicadas siguen siendo legibles por URL (ya anotado en
  OUR-111/112).
