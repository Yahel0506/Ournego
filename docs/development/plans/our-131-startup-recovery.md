# OUR-131 — Plan de recuperación del arranque móvil

Estado: implementación completa; diseño y entrega aprobados técnicamente por Astra; revisión del Lead satisfactoria.

Issue: [OUR-131](https://linear.app/yaheldev/issue/OUR-131/inicio-completar-estado-de-error-de-configuracion-y-supabase).
Rama: `our-131-startup-recovery`.
Dirección aprobada: opción B, mensajes y ayuda contextuales, con reintento manual únicamente cuando pueda recuperar el fallo de manera segura.
Cómputo previsto: MEDIUM, con un solo subagente activo a la vez.

## Alcance

Completar el primer criterio de OUR-110: una configuración ausente o un fallo de inicialización debe mostrar estado y acción clara, sin entrar en un flujo roto.

Se conserva el flujo de onboarding, el estado de sesión, el routing posterior al arranque, la configuración web y los temas actuales. No se implementan recuperación de sesión vencida, disponibilidad del backend durante el uso ni permisos de ubicación. No se añaden comprobaciones de red obligatorias, dependencias, migraciones ni cambios al SDK.

## Evidencia y restricción del reintento

- `lib/main.dart` ya evita construir `MaterialApp.router` cuando existe `startupError`.
- La pantalla actual solo presenta texto técnico sobre configuración; no ofrece acciones.
- Supabase Flutter 2.12.0 marca el singleton como inicializado antes de finalizar `SupabaseAuth.initialize`.
- Si esa inicialización falla, otra llamada a `Supabase.initialize` puede devolver la misma instancia sin recuperar el fallo.
- `dispose()` usa un campo que solo se asigna después del paso que puede fallar; no se puede asumir un rollback seguro.
- El SDK inicializa SharedPreferences para persistencia de sesión. Preparar esa dependencia antes de crear el cliente permite reintentar una conexión de plataforma fallida sin reinicializar un singleton parcial.
- SharedPreferences 2.5.3 descarta su Completer almacenado si falla la lectura; una llamada posterior efectúa otra lectura. Pigeon en Android 2.4.18 y foundation 2.5.6 emite `channel-error` cuando no puede establecer conexión. Ese código no garantiza que el fallo sea temporal: solo se permitirá un reintento manual seguro; si vuelve a fallar, se ofrecerá volver a abrir la aplicación. Los demás códigos y MissingPluginException no habilitarán reintento.

## Comportamiento propuesto

| Resultado | Estado y acción |
| --- | --- |
| Configuración ausente, ilegible o de formato inválido | Mensaje de instalación/configuración, `Ver ayuda`; sin reintento que prometa reparar la configuración compilada. |
| `channel-error` al preparar SharedPreferences antes de tocar Supabase | Mensaje de fallo de arranque, un único `Reintentar` manual y `Ver ayuda`; si vuelve a fallar, indicar volver a abrir la app. |
| Dependencia de plataforma ausente o error local desconocido/determinista | Ayuda para volver a abrir la app o contactar soporte; sin reintento. |
| Error después de entrar en `Supabase.initialize` | Reinicio de la aplicación requerido; no volver a inicializar ni intentar disponer un cliente parcial. |
| Intento que supera 20 segundos | Mensaje de espera vencida y ayuda para volver a abrir; sin segundo intento concurrente. Un resultado tardío no habilita el router. |
| Inicialización completa | Construir la app principal y respetar la elección previa de onboarding/mapa. |

No habrá reintentos automáticos. Una doble pulsación no creará dos intentos. La clasificación de error no dependerá de buscar palabras en el mensaje de una excepción.

## Implementación por etapas

### 1. Extraer configuración y lógica de arranque

Crear un área pequeña en `lib/core/startup/`, sin reorganizar features existentes.

- Resolver configuración con entradas inyectables para pruebas.
- Mantener `window.ENV` en web y `--dart-define`/dotenv en móvil.
- Si un valor necesita fallback, conservar el otro valor válido suministrado mediante define.
- Comprobar valores no vacíos y URL HTTP/HTTPS con host; no confundir validación de formato con aceptación de credenciales por el backend.
- No incluir valores de configuración en mensajes, `toString` ni registros.
- Preparar SharedPreferences antes de entrar en la inicialización del SDK.
- Clasificar de forma conservadora los fallos de preparación: solo `PlatformException.code == 'channel-error'` permite un reintento, sin afirmar que la causa es temporal. Plugin ausente, otros códigos y errores desconocidos no permiten reintento.
- Inyectar las operaciones mínimas necesarias para probar la implementación real, no solo errores fabricados.

### 2. Controlar estados y exclusión de intentos

- Controlador con estados de inicio, error y listo.
- Un solo intento activo; como máximo un reintento manual desde un fallo de conexión de plataforma ocurrido antes de tocar Supabase.
- Marcar explícitamente la entrada en la inicialización del SDK: cualquier fallo posterior requiere volver a abrir la aplicación.
- Aplicar el límite de tiempo sin asumir que `Future.timeout` cancela la operación subyacente.
- Invalidar el intento al vencer el límite o disponer el controlador y comprobar su vigencia después de cada operación asíncrona, especialmente antes de entrar en Supabase. Una preparación completada después del timeout debe producir cero llamadas al SDK.
- Tras vencer el límite, impedir que un resultado tardío construya la app principal. Si el SDK ya comenzó, mantener el estado de reinicio requerido.
- Gestionar el cierre del widget/controlador sin notificaciones posteriores a su eliminación.
- Leer el estado de onboarding separadamente, conservando el fallback actual sin borrar preferencias ni sesión.

### 3. Integrar la barrera de arranque

- Montar la interfaz de inicio antes de esperar operaciones asíncronas.
- Mantener `ProviderScope` y `BetterFeedback` sin leer dependencias de Supabase en la pantalla de error.
- Construir `MyApp`, su router y el listener de autenticación web únicamente tras completar el arranque.
- Conservar el comportamiento del router y sus guards.
- Registrar solo categorías seguras del error; evitar que el SDK añada detalles sensibles al registro de este flujo.

### 4. Presentar error, ayuda y reintento

- Pantalla con `SafeArea`, contenido desplazable, temas actuales y textos en español.
- Configuración: `Ournego no puede iniciar` / `Esta instalación necesita una corrección para funcionar`.
- Inicialización: `No pudimos iniciar Ournego`; explicar la acción disponible sin atribuir automáticamente el fallo a internet.
- `Reintentar` muestra progreso y queda deshabilitado durante el intento.
- `Ver ayuda` abre instrucciones locales apropiadas a la causa.
- La ayuda puede ofrecer el canal de consultas que ya usa la app, mediante `url_launcher`, sin enviar mensajes automáticamente.
- No reutilizar el diálogo completo de feedback: su construcción lee un usecase que depende de Supabase.
- Si no se puede abrir el canal externo, mostrar una explicación segura y conservar la ayuda local.
- No pedir al usuario credenciales ni recomendar borrar datos o reinstalar.

### 5. Pruebas y documentación

Agregar pruebas focalizadas en `test/core/startup/` y una comprobación de integración de la barrera de arranque.

- Configuración ausente/URL inválida: el inicializador no se invoca y no hay reintento.
- Resolución parcial de defines y fallback: se conserva el valor suministrado.
- Preparación real mediante SharedPreferences/plataforma: primera lectura emite `channel-error`, la conexión posterior responde; no se toca Supabase antes del reintento exitoso y el flujo se libera después.
- Repetición de `channel-error` en el único reintento: la pantalla pasa a ayuda/reinicio, sin tercer intento.
- Plugin ausente/error desconocido: no se promete recuperación mediante reintento.
- Inicializador que falla después de entrar: el flujo principal queda bloqueado y no hay segunda llamada.
- Pulsaciones repetidas: un único intento.
- Espera vencida durante la preparación seguida de éxito tardío: cero llamadas al SDK y router bloqueado.
- Espera vencida durante la inicialización seguida de éxito tardío: el router sigue bloqueado.
- Pantalla principal/listener/proveedores dependientes no se construyen antes del éxito.
- Ayuda y fallo al abrir soporte no necesitan Supabase y no muestran excepciones crudas.
- Onboarding previo y casos de primer arranque permanecen correctos.
- Pantalla legible sin overflow con ventana pequeña, texto ampliado y ambos temas.

Actualizar `docs/development/testing/TESTING.md` con cobertura y límites de la validación realizada. Ajustar documentación de arquitectura solo si el cambio final lo requiere.

### 6. Verificación y entrega

Ejecutar:

```sh
flutter analyze
flutter test
flutter build apk --release
git diff --check
```

Comprobar en Android los estados de error y las acciones si hay dispositivo accesible; informar explícitamente de cualquier limitación. El APK habitual contiene la configuración de desarrollo existente: no generar ni compartir un artefacto de prueba que exponga credenciales.

El Lead revisará el diff, la preservación de cambios locales y los criterios de aceptación. Astra revisará después el paquete de entrega con evidencias. La solicitud posterior del Product Owner autoriza los commits, el push de la rama y la apertura de una pull request hacia `main`.

## Criterios de aceptación

1. Error y acción comprensibles para un usuario móvil.
2. Configuración defectuosa diferenciada de un fallo de inicialización.
3. Como máximo un reintento manual, exclusivamente para un fallo de conexión de plataforma previo al SDK que puede resolverse al restablecer la conexión; ningún reintento de códigos desconocidos ni de cliente parcial.
4. SDK parcial, espera vencida y resultados tardíos nunca se interpretan como arranque correcto.
5. Router y consumidores de Supabase bloqueados hasta completar la inicialización.
6. Onboarding y sesión conservados; configuración web operativa.
7. Ayuda independiente del backend, sin exposición de credenciales.
8. Pruebas y verificaciones del cambio satisfactorias, con límites de ejecución en Android identificados.

## Preservación del trabajo existente

Antes de empezar existían una modificación de `pubspec.yaml` y `android/build/` sin seguimiento. Son ajenos a esta implementación: conservarlos, no incluirlos en el diff de la feature ni limpiar esos archivos. No leer ni imprimir `.env`.

## Revisión de Astra

Astra aprobó el diseño revisado el 5 de octubre de 2026. La revisión inicial exigió invalidar las operaciones vencidas antes de que pudieran iniciar Supabase y concretar la clasificación del reintento. La versión aprobada permite un único reintento manual de `channel-error` durante la preparación de SharedPreferences, sin prometer que el fallo sea temporal. La entrega debe acreditar recuperación real de la dependencia, cero llamadas tardías al SDK y ausencia de un tercer intento.

Astra aprobó también la entrega el 5 de octubre de 2026: no identificó inconsistencias materiales en el reintento acotado, el bloqueo del singleton parcial, la concurrencia ni los resultados tardíos. Reconoció los límites documentados de la validación Android con fallos inyectados.

## Evidencia de implementación

- `StartupController` resuelve la configuración, prepara las preferencias y bloquea resultados vencidos; `StartupGate` construye la app principal solo después del éxito.
- 18 pruebas focalizadas y 48 pruebas de la suite completa satisfactorias; análisis sin problemas; APK release compilado (66.5 MB).
- Comprobación nativa en Samsung S24 mediante una app temporal sin `.env`, con fallos inyectados, inicializador simulado y preferencias nativas propias. Reintento, doble pulsación, configuración defectuosa, fallo persistente, fallo del inicializador, timeout y ayuda comprobados. Texto ampliado al doble y ambos temas revisados visualmente.
- Cambios locales previos conservados y excluidos de los commits de OUR-131. La conexión de producción y la suite Patrol no forman parte de esta evidencia.
- Detalle de cobertura y límites en `docs/development/testing/TESTING.md`.
