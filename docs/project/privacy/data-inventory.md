# Inventario de datos, permisos y SDK (OUR-109)

Estado a **2026-10-23**, versión 0.3.0, recorridos del piloto de
[`first-release-scope.md`](../scope/first-release-scope.md). Es la fuente para
el aviso de privacidad y los términos de `ournego-web` y para la sección de
datos y seguridad de la ficha de Google Play (OUR-103).

La verificación contra el AAB firmado (manifest final, SDK empaquetados) queda
en OUR-122. Esta lista sale del código fuente, no del binario.

## 1. Permisos de Android

| Permiso | Estado | Motivo |
| --- | --- | --- |
| `ACCESS_FINE_LOCATION` | Se mantiene | Centrar el mapa en el usuario y mostrar negocios cercanos. Se pide al usuario, y la app funciona sin él (zona manual). |
| `INTERNET`, `ACCESS_NETWORK_STATE` | Se mantienen | Supabase, mapas, geocodificación y detectar si hay red. |
| `RECORD_AUDIO` | Se mantiene | Búsqueda por voz del mapa, parte del recorrido del consumidor en el piloto. Se pide al tocar el botón de micrófono; la app funciona sin él (búsqueda por texto). |

El micrófono y el reconocimiento de voz (`NSMicrophoneUsageDescription` y
`NSSpeechRecognitionUsageDescription` en iOS) se usan solo para la búsqueda por
voz (`speech_to_text`). El audio no se graba ni se guarda en la app ni en
Supabase: lo procesa el servicio de reconocimiento del sistema (en Android el
de Google, en iOS el de Apple) y la app recibe solo el texto.

Cámara y galería (`image_picker`, `image_cropper`) no declaran permiso propio
en Android: usan el selector del sistema. En iOS siguen
`NSCameraUsageDescription` y `NSPhotoLibraryUsageDescription`.

## 2. Datos que se recopilan

| Dato | Origen | Dónde se guarda | Finalidad | Retención |
| --- | --- | --- | --- | --- |
| Correo, contraseña o cuenta de Google | Registro / inicio de sesión | Supabase Auth | Cuenta | Hasta eliminar la cuenta |
| Nombre, teléfono (`phone_num`), foto de perfil | Completar perfil | Supabase (`users`, bucket `profile_pictures`) | Perfil | Hasta eliminar la cuenta |
| Datos del negocio: nombre, tipo, descripción, dirección, coordenadas, teléfono, horarios, imágenes | Registro de negocio | Supabase (`businesses`, `business_hours`, bucket `businesses_pictures`) | Mostrar el negocio en el mapa. **Es público** una vez aprobado. | Hasta eliminar la cuenta o el negocio |
| Favoritos | Usuario | Supabase (`user_favorites`) | Guardar negocios | Hasta eliminar la cuenta |
| Interacciones con un negocio (ver ficha, contacto, catálogo, reseñas, compartir) con origen y `user_id` si hay sesión | Uso de la app | Supabase (`user_interactions`) | Métricas de vistas por negocio | Se eliminan con la cuenta |
| Reporte de comentarios: mensaje, modelo y sistema del dispositivo, captura adjunta | Formulario de feedback | Supabase (`feedback`, `feedback_attachments`) | Soporte y corrección de datos | Se elimina con la cuenta |
| Ubicación GPS | Dispositivo | **Solo en el dispositivo.** No se sube a Supabase. | Centrar el mapa | Última posición y zoom en `shared_preferences` hasta borrar los datos de la app |
| Zona manual elegida | Usuario | `shared_preferences` | Mapa sin GPS | Hasta borrar los datos de la app |
| Preferencias de onboarding y mapa | App | `shared_preferences` / `sembast` | Experiencia | Hasta borrar los datos de la app |
| Registro de solicitud de eliminación (huella del correo, fechas, estado) | Web | Supabase | Prueba de cumplimiento | Ver `deletion-policy.ts` en `ournego-web` |

No se recopila: RFC o datos fiscales, datos de pago, mensajes entre usuarios,
historial de ubicaciones, grabaciones de voz, contactos, ni identificadores
publicitarios. No hay reseñas ni pagos en la app (el botón de reseñas muestra
«próximamente»).

## 3. Datos compartidos con terceros

| Tercero | Qué recibe | Para qué | Notas |
| --- | --- | --- | --- |
| Supabase (hospedaje de base de datos, autenticación y archivos) | Todos los datos de la sección 2 que se guardan en el servidor | Operación del servicio | Proveedor de infraestructura. |
| Google (inicio de sesión) | Cuenta de Google, solo si el usuario elige ese método | Autenticación | `google_sign_in` + OAuth de Supabase. |
| Mapbox | Peticiones de teselas (zona visible), dirección IP | Mostrar el mapa | Sin identificador de usuario. |
| LocationIQ | Texto de búsqueda de dirección; coordenadas de la zona elegida a mano | Autocompletar y geocodificación inversa | No recibe la posición GPS continua. |
| Servicio de reconocimiento de voz del sistema (Google en Android, Apple en iOS) | Audio del micrófono mientras se dicta | Convertir la búsqueda hablada en texto | Solo al usar el botón de voz. No pasa por Ournego ni Supabase. |
| Servicio de correo (SMTP de Supabase y envío del enlace de eliminación) | Correo del usuario | Enlaces de acceso y de eliminación | |

No se venden datos ni hay publicidad ni analítica de terceros.

## 4. SDK empaquetados

- **Quitado en esta tarea:** `firebase-analytics` en
  `android/app/build.gradle.kts`. Ninguna parte de `lib/` inicializaba Firebase
  ni registraba eventos, pero el SDK nativo de Analytics se inicia solo y
  recoge un identificador de instalación.
- **Siguen en `pubspec.yaml` sin uso en `lib/`:** `firebase_core`,
  `firebase_auth`, `cloud_firestore`. Quitarlos y revisar el plugin
  `com.google.gms.google-services` y `google-services.json` corresponde a
  OUR-122, que audita el AAB.
- **En uso:** `speech_to_text`, `supabase_flutter`, `google_sign_in`, `flutter_map`,
  `geolocator`, `permission_handler`, `image_picker`, `image_cropper`,
  `device_info_plus` (modelo y sistema en el feedback), `shake`, `feedback`,
  `connectivity_plus`, `share_plus`, `url_launcher`,
  `flutter_phone_direct_caller`, `shared_preferences`, `sembast`.

## 5. Eliminación de cuenta

Pública y sin iniciar sesión en `ournego.com/delete-account` (OUR-137). Plazos
y alcance están en el aviso de privacidad (sección 13.2).

## 6. Textos públicos alineados

`ournego-web`: `src/app/(marketing)/privacy-policy/page.tsx` y
`src/content/terms-and-conditions.md` se reescribieron contra este inventario:
se quitaron pagos, suscripciones, mensajería, notificaciones push, analítica y
datos fiscales que la app no tiene. Cuando se añada alguna de esas funciones
hay que actualizar primero este documento y luego los textos.
