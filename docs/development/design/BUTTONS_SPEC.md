# Ournego · Especificación de botones (labio plano + Nego)

**Versión:** 1.1 · 12 de octubre de 2026
**Cambios en 1.1:** la barra superior del mapa (voz, buscador y perfil), el chip de zona y la navbar pasan a flat glass sin labio, con animaciones calmadas. Se conservan los contornos del repo (1 px, outline al 30%). Los controles del mapa mantienen el labio.
**Base de código analizada:** `Yahel0506/Ournego`, commit `a59258e` (Flutter 3.41, Riverpod 3, Material 3)
**Destino sugerido en el repo:** `docs/development/design/BUTTONS_SPEC.md`
**Referencia visual:** playground "Botones Ournego" (https://claude.ai/artifact/K5qQnNMPRNBEFfLnMRGgYv). Es privado y Claude Code no puede abrirlo. Todos los valores que hacen falta para implementar están en este documento; el playground sirve solo para que una persona lo vea.

---

## 0. Cómo usar este documento

Este documento es **normativo**. Las palabras **DEBE**, **NUNCA** y **PUEDE** tienen su significado literal. Si una instrucción de este documento choca con `docs/development/design/DESIGN_SYSTEM.md` o con `docs/development/ui-refactor/README.md`, gana este documento en todo lo relacionado con botones.

### 0.1 Decisiones ya cerradas (no volver a preguntar)

| Tema | Decisión |
|---|---|
| Fuente | Fuente del sistema (Roboto en Android, SF en iOS). **No** se bundlea Inter ni Nunito. **No** se agrega `fontFamily`. Los botones usan peso `w800`. |
| Contenido sobre aqua | Siempre `noche #161616` (9.77:1), en ambos temas. El blanco sobre aqua (1.85:1) desaparece. |
| Radios | Se conservan los radios actuales de cada elemento (24, 16, 14, 12, 30, círculo, pill). |
| Labio | Solo los **botones de acción** llevan labio plano: un bloque sólido debajo de la cara, sin `BoxShadow` con blur. Los controles del mapa (zoom, mi ubicación, depuración) cuentan como botones de acción y **sí** llevan labio. |
| Flat glass | La barra superior del mapa (voz, buscador y perfil), el chip de zona y la barra de navegación **no** llevan labio. Conservan su estética actual: superficie, contorno de 1 px visible y movimiento suave **sin rebote ni sobrepaso**. |
| Contornos | Todo elemento que hoy tiene contorno lo conserva: 1 px de `OurnegoSemanticTokens.borderSubtle` (outline al 30%). En el tema claro `colorScheme.outline` vale **negro**, porque `ColorScheme.light` no lo define y Flutter cae a `onBackground`, que ahí es `Colors.black`. Por eso el contorno se ve marcado en claro. **NUNCA** definas `outline` en el tema ni bajes esa opacidad. |
| Ripple | Ningún botón ni elemento de esta familia usa ripple, `InkWell`, `InkResponse` ni splash de Material. |
| Blur | `BackdropFilter` solo en los elementos flat glass que flotan sobre el mapa: voz, buscador, perfil y chip de zona. La barra de navegación es opaca. Los botones con labio **nunca** llevan blur. |
| Nego | Aparece en el botón primario solo donde lo indica la tabla de migración (§9). |
| Haptics | Fuera de alcance. No agregar `HapticFeedback`. |
| Textos | No cambiar textos, salvo las correcciones listadas en §9.9. |

### 0.2 Si algo no está especificado

Elige lo más cercano a este documento, déjalo anotado en la descripción del PR y sigue. **NUNCA** inventes tonos, tamaños ni curvas nuevas. Si de verdad no se puede continuar sin una decisión, detente y pregunta.

---

## 1. Objetivo y alcance

### 1.1 Objetivo

Reemplazar **todos** los botones y elementos interactivos de la app por una familia única de componentes de marca en `lib/shared/widgets/buttons/`, con la estética del playground. La familia tiene dos líneas:

1. **Botones de acción.** Labio plano estilo cartoon, rebote al soltar y Nego integrado en el CTA principal.
2. **Flat glass.** Para lo que flota sobre el mapa y para la barra de navegación: sin labio, con contorno fino visible y animaciones igual de cuidadas pero calmadas, sin rebote.

Al terminar no debe quedar ningún botón de Material crudo ni ningún botón privado por pantalla.

### 1.2 Problemas que se resuelven

1. **Dos clases `OurnegoButtonStyles`:** una en `lib/core/theme/ournego_button_styles.dart` y otra en `lib/shared/widgets/ournego_buttons.dart`.
2. **Botones crudos:** 13 `FilledButton`, 11 `TextButton`, 7 `OutlinedButton`, 7 `ElevatedButton` y 4 `IconButton` en features, cada uno con estilo propio o con el tema por defecto.
3. **Cinco implementaciones distintas de botón de icono:**
   - `circularSurface`
   - `_MapControlButton`
   - `SheetControlButton`
   - `BusinessPanelIconButton`
   - `IconButton` crudo
4. **Botones privados en el floating sheet:** `_LegacyActionButton`, `_LegacyWideButton`, `_CompactAction` y `_brandedSheetButtonStyle`.
5. **Auth copiado:** cuatro clases casi idénticas en `auth_selection_widget.dart`. Además, el botón de teléfono tiene `onPressed: () {}`, así que parece activo pero no hace nada.
6. **Estado de carga a mano:** el spinner se arma dentro del botón en `password_recovery_screen` y `business_form_screen`. No existe un estado `loading`.
7. **Contraste:**
   - En el tema claro, `onPrimary` es blanco sobre aqua (1.85:1).
   - El icono activo de la barra de navegación es `surface` sobre aqua (1.77:1).
8. **API de diálogo invertida:** en `OurnegoAlertDialog`, la acción "principal" (`actionLabel`) se usa como Cancelar y la acción real va en `trailingActions` como `TextButton`.
9. **Código muerto:**
   - `ActionTile` y `BentoActionGrid` no se usan.
   - `tonalCardButton` tampoco.
10. **Estilos de texto pisados:** `OurnegoTextStyles.header` se usa dentro de botones (onboarding, registro de negocio) para hacerlos más grandes.

### 1.3 En alcance

- Todo lo que hoy es `ElevatedButton`, `FilledButton`, `OutlinedButton` o `TextButton` (incluidas sus variantes `.icon`).
- Todo `IconButton`, `FilterChip`, `ZoneChip`, `SheetControlButton`, `BusinessPanelIconButton`, `_MapControlButton`, `_CrystalNavItem`, `_CrystalItemContainer`, `OurnegoPrimaryButton`, `OurnegoNeutralPrimaryButton`, `OurnegoButtonStyles.*` y los `_Legacy*Button` / `_CompactAction` del floating sheet.
- Los dos dropdowns compactos del buscador del mapa (`_compactDropdown`), que pasan a ser chips desplegables.
- La API de acciones de `OurnegoAlertDialog`.
- Las extensiones mínimas de `NegoAvatar` que necesitan los botones (§8).
- Una pantalla de galería en el panel de depuración para hacer QA visual (§12).
- Pruebas nuevas y una prueba de arquitectura que impida volver a meter botones crudos (§11).

### 1.4 Fuera de alcance (NO tocar)

- **Tarjetas tocables:** `_RoleOptionCard`, `BusinessPanelMetricTile`, `BusinessPanelLockedCenterCard`, el contenedor de `BusinessPanelQuickActions` y el banner "Registra tu negocio y crece" de `map_screen.dart` (≈ línea 613). Tampoco `MinimizedStackIcon`.
- **Filas de menú y listas:** los `ListTile` del menú de perfil, del diálogo de feedback, de los resultados del buscador y del panel de depuración.
- **Links de texto:** los dos `InkWell` con texto en `login_email_screen.dart` (Regístrate y Olvidé mi contraseña).
- **Selectores de hora:** los `GestureDetector` de inicio y cierre en `business_hours_picker.dart`.
- **Otros sistemas:** snackbars, inputs (salvo el icono de visibilidad de contraseña), marcadores del mapa, colores de categoría, fuentes, la estructura del floating sheet más allá de sus botones y del header duplicado, y `DropdownButtonFormField` de formularios.
- **Botones internos de Flutter:** los de `showTimePicker`, `showDatePicker` y del paquete `feedback`. Esos siguen usando `textButtonTheme` y está bien.

---

## 2. Principios de la línea visual

1. **Labio plano en los botones de acción.** Debajo de la cara del botón hay un bloque sólido del mismo radio, de un tono más oscuro (o del color del contorno en los tonos con contorno). El labio se ve como el grosor del botón.
   - **Hover:** la cara sube 1 px y el labio se ve 1 px más alto.
   - **Presionar:** la cara baja exactamente lo que mide el labio y el labio desaparece.
   - **Soltar:** la cara rebota.
2. **Flat glass en lo que flota y en la navegación.** La barra superior del mapa (voz, buscador y perfil), el chip de zona y la barra de navegación no son botones de acción: viven encima del mapa o enmarcan la app, y no deben dominar la interfaz.
   - No llevan labio.
   - Conservan su estética actual: superficie (casi opaca con un toque de blur sobre el mapa, opaca en la navbar) y un contorno de 1 px visible. La navbar además conserva su sombra suave.
   - Se animan con la misma calidad que los botones, pero en clave calmada: una escala corta al presionar, cambios de contorno y color, y un indicador que se desliza en la navbar. Todo con curvas **sin sobrepaso**.
3. **Los controles del mapa sí son botones.** Zoom, mi ubicación y depuración flotan sobre el mapa, pero son acciones directas: llevan labio, tono `glass` y contorno.
4. **Contornos de siempre.** Donde la app ya tiene contorno (botones contorneados, botones de acceso, controles del sheet, acciones del sheet, chip de zona, barra superior, navbar y sheet), se conserva: 1 px de `borderSubtle`. En los botones con labio y contorno, el labio es del mismo color que el contorno ya compuesto sobre el fondo, para que se lea como el grosor del borde.
5. **Aqua lleva texto noche.** Todo contenido sobre `azulCielo` usa `#161616`, incluido el icono activo de la navbar.
6. **Radios intactos:**
   - Botones de texto: 24.
   - Controles del mapa: 16.
   - Controles del sheet: 14.
   - Acciones y tiles del sheet: 12.
   - Fila del sheet y buscador: 30.
   - Chips y barra de navegación: pill.
   - Botones de icono: círculo, salvo los dos casos anteriores (16 y 14).
7. **Juguetón con medida.** El rebote al soltar y el "pop" de los iconos al activar un toggle son exclusivos de los botones con labio. La ráfaga de puntos solo aparece al marcar favorito y en el estado de éxito. Los elementos flat glass **nunca** rebotan. No hay animaciones en bucle, salvo:
   - el loader;
   - el halo del micrófono mientras escucha;
   - Nego.
8. **Nego vive en el primario.** En los CTA indicados, un Nego mini va a la izquierda del texto:
   - Se emociona con hover.
   - Se pone feliz al presionar.
   - Cierra los ojos si el botón está apagado.
   - Guiña en éxito.
   - Mientras carga, el loader son sus ojos.
9. **Reduced motion.** Con `MediaQuery.disableAnimationsOf(context) == true`:
   - Se quitan el rebote, el pop y la ráfaga.
   - El halo del micrófono queda fijo al 40%.
   - El indicador de la navbar salta sin transición.
   - El loader pasa a un pulso de opacidad.
   - El desplazamiento al presionar los botones con labio y la escala al presionar los flat glass se conservan, porque son feedback funcional, pero sin sobrepaso.
10. **Un primario por vista.** Si una pantalla necesita dos acciones fuertes, la segunda es `secondary`.

---

## 3. Tokens

### 3.1 Colores por tono (botones con labio)

Los valores están en formato Dart `Color(0xAARRGGBB)`. Dos valores se calculan a partir del tema:

- `borderSubtle` = `OurnegoSemanticTokens.borderSubtle(colorScheme)`. Vale `0x4D000000` en claro y `0x4D89938F` en oscuro.
- `outlineLip` = `Color.alphaBlend(borderSubtle, fondo)`, donde `fondo` es `OurnegoColorTokens.blanco` en claro y `OurnegoColorTokens.surfaceDark` en oscuro. Da `0xFFB3B3B3` en claro y `0xFF3E4745` en oscuro.

**Tema claro**

| Tono | Uso | Cara | Labio | Tinta | Contorno |
|---|---|---|---|---|---|
| `primary` | CTA, acción principal | `0xFF3BCFED` | `0xFF009ABE` | `0xFF161616` | — |
| `neutral` | CTA de onboarding | `0xFF161616` | `0xFF000000` | `0xFFFFFFFF` | — |
| `secondary` | Acción secundaria | `0xFFFFFFFF` | `outlineLip` | `0xFF161616` | `borderSubtle` |
| `tonal` | Acción suave en tarjeta | `0xFFD8F7FD` | `0xFFA4E4F2` | `0xFF055F46` | — |
| `tonal` + `outlined` | Controles del floating sheet | `0xFFD8F7FD` | `outlineLip` | `0xFF055F46` | `borderSubtle` |
| `success` | Estado "listo" | `0xFF7EEFC2` | `0xFF3EBF89` | `0xFF055F46` | — |
| `destructive` | Cerrar sesión, borrar | `0xFFBA1A1A` | `0xFF7A0F0F` | `0xFFFFFFFF` | — |
| `glass` | Controles del mapa, iconos del panel, acciones del sheet, chips | `0xFFFFFFFF` | `outlineLip` | `0xFF161616` | `borderSubtle` |
| `white` | Botón de Google | `0xFFFFFFFF` | `0xFFB3B3B3` (fijo) | `0xFF161616` | `0x4D000000` (fijo) |
| `ghost` | Botón de texto, icono sin fondo | transparente | — | `colorScheme.onSurface` | — |

**Tema oscuro**

| Tono | Cara | Labio | Tinta | Contorno |
|---|---|---|---|---|
| `primary` | `0xFF3BCFED` | `0xFF0A86A6` | `0xFF161616` | — |
| `neutral` | `0xFFFFFFFF` | `0xFFAEBDB8` | `0xFF161616` | — |
| `secondary` | `0xFF1E2625` | `outlineLip` | `0xFFE1E3E1` | `borderSubtle` |
| `tonal` | `0xFF034E3A` | `0xFF012A1F` | `0xFFD8F7FD` | — |
| `tonal` + `outlined` | `0xFF034E3A` | `outlineLip` | `0xFFD8F7FD` | `borderSubtle` |
| `success` | `0xFF3EBF89` | `0xFF25845C` | `0xFF161616` | — |
| `destructive` | `0xFFBA1A1A` | `0xFF5C0909` | `0xFFFFFFFF` | — |
| `glass` | `0xFF1E2625` | `outlineLip` | `0xFFE1E3E1` | `borderSubtle` |
| `white` | `0xFFFFFFFF` | `0xFFB3B3B3` (fijo) | `0xFF161616` | `0x4D000000` (fijo) |
| `ghost` | transparente | — | `colorScheme.onSurface` | — |

**Colores de apoyo**

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `disabledFace` | `0x12161616` | `0x14E1E3E1` | Cara apagada (todos los tonos) |
| `disabledInk` | `0x61161616` | `0x61E1E3E1` | Texto e icono apagados |
| `disabledLip` | `0x17161616` | `0x0DE1E3E1` | Labio apagado |
| `ghostOverlay` | `0x12055F46` | `0x14E1E3E1` | Hover y pressed de `ghost`, y hover de ítems no seleccionados de la navbar |
| `focusRing` | `0xFF009ABE` | `0xFF3BCFED` | Anillo de foco de teclado |
| `accentInk` | `0xFF009ABE` | `0xFF3BCFED` | Chevron de la fila, pin del chip de zona, estado activo de flat glass |
| `burstColors` | `aguamarina`, `azulCielo`, `mentaOscuro`, `azulVerde` | igual | Ráfaga de puntos |
| `ratingStar` | `OurnegoColorTokens.warning` | igual | No es botón; se menciona solo para el sheet |

Reglas:

- El contorno mide **1 px** en todos los tonos que lo llevan. Los tonos sin contorno reservan 1 px transparente, para que todos midan lo mismo.
- En los tonos con contorno, el labio es `outlineLip`. Así el borde y el grosor del botón se leen como una sola pieza. Excepción: `white` usa sus valores fijos.
- `outlined: true` solo se usa con `tonal`, en los controles del floating sheet, que hoy ya tienen contorno.
- **Apagado:** cara `disabledFace`, tinta `disabledInk`, labio `disabledLip` y contorno transparente, para todos los tonos. La excepción es `ghost`, que queda transparente con tinta `disabledInk`.
- **NUNCA** se usan estos colores fuera de `lib/shared/widgets/buttons/`. Las features eligen un tono, nunca un color.

### 3.1.1 Colores flat glass (sin labio)

| Token | Claro | Oscuro | Uso |
|---|---|---|---|
| `glassFace` | `0xE0F4FBF9` (surface al 88%) | `0xE01E2625` | Voz, perfil, buscador, chip de zona |
| `navFace` | `colorScheme.surface` (opaca) | igual | Barra de navegación |
| `glassBorder` | `borderSubtle` (`0x4D000000`) | `borderSubtle` (`0x4D89938F`) | Contorno en reposo |
| `glassBorderHover` | `0x80000000` (outline al 50%) | `0x9989938F` (outline al 60%) | Contorno con hover |
| `glassActive` | `accentInk` | `accentInk` | Contorno y tinta del micrófono escuchando; contorno del buscador enfocado |
| `focusGlow` | `0x473BCFED` | `0x4D3BCFED` | Anillo exterior de 3 px del buscador enfocado |
| `haloColor` | `OurnegoColorTokens.azulCielo` | igual | Halo del micrófono escuchando |
| `navIndicator` | `0xFF3BCFED` con tinta `0xFF161616` | igual | Círculo del ítem activo de la navbar |
| `navShadow` | `OurnegoColorTokens.shadow`, blur 10, spread 0.2 | igual | Solo la navbar (la sombra de hoy) |
| Blur | `ImageFilter.blur(sigmaX: 10, sigmaY: 10)` | igual | Solo `glassFace`. La navbar no lleva blur. |
| Tinta | `colorScheme.onSurface` | igual | Iconos y texto en reposo |

### 3.2 Contraste verificado (WCAG, calculado sobre los hex)

| Par | Ratio |
|---|---|
| `primary` tinta/cara (ambos temas) | 9.77 |
| `neutral` claro / oscuro | 18.10 / 18.10 |
| `secondary` claro / oscuro | 18.10 / 11.98 |
| `tonal` claro / oscuro | 6.82 / 8.65 |
| `success` claro / oscuro | 5.50 / 7.77 |
| `destructive` | 6.46 |
| `glass` claro / oscuro | 18.10 / 11.98 |
| `accentInk` claro sobre blanco (solo iconos ≥ 3:1) | 3.30 |
| `focusRing` claro sobre `surfaceLight` / oscuro sobre `noche` | 3.14 / 9.77 |

Todos los textos de botón pasan AA (4.5:1). La prueba de §11.2 DEBE verificarlo.

### 3.3 Tamaños de `OurnegoButton`

| `OurnegoButtonSize` | Alto de cara | Labio | Padding horizontal | Fuente | Icono | Gap | Nego mini |
|---|---|---|---|---|---|---|---|
| `large` | 56 | 5 | 24 | 17 | 22 | 10 | 30 |
| `regular` (default) | 50 | 4 | 24 | 16 | 22 | 10 | 30 |
| `compact` | 44 | 3 | 18 | 15 | 22 | 10 | 26 |
| `small` | 36 | 2 | 14 | 14 | 18 | 6 | no permitido |

- La altura **total** que ocupa el widget es *alto de cara + labio*, porque el labio reserva su espacio debajo. `ghost` no tiene labio y ocupa solo el alto de cara.
- Radio por defecto: `OurnegoRadiusTokens.button` (24). Se puede sobrescribir con `radius` (solo lo usa el floating sheet, con 14).
- Área táctil mínima: **48×48**. Si la cara mide menos (`small`), el área sensible se extiende de forma invisible hasta 48, centrada y sin cambiar el layout visual (§5.6).

### 3.4 Tamaños de `OurnegoIconButton` (con labio)

| `OurnegoIconButtonSize` | Lado | Labio | Icono | Uso |
|---|---|---|---|---|
| `s52` | 52 | 4 | 22 | Controles del mapa |
| `s48` | 48 | 4 (sin labio si es `ghost`) | 22 | Regresar en onboarding |
| `s44` | 44 | 3 | 22 | Header del panel, editar foto de perfil |
| `s40` | 40 | 3 (sin labio si es `ghost`) | 20 | Iconos dentro de campos, créditos del mapa, cerrar búsqueda |
| `s32` | 32 | 3 | 18 | Controles del floating sheet |
| `s28` | 28 | 2 | 16 | Editar, agregar y borrar dentro del panel de negocio |

Forma por defecto: círculo. `radius` la sobrescribe: 16 para los controles del mapa y 14 para los del sheet.

### 3.5 Otras métricas

| Componente | Alto | Radio | Labio | Detalle |
|---|---|---|---|---|
| `OurnegoChip` (filter, dropdown) | 40 | pill (1000) | 3 | padding h 16, fuente 14 `w800`, gap 6, icono 18 |
| `OurnegoRowButton` | 58 | 30 | 4 | padding izq. 10 / der. 12, círculo de acento 36 (icono 20), chevron 26 |
| `OurnegoActionButton` | 42 | 12 | 3 | solo icono 22, ocupa el ancho del padre |
| `OurnegoActionTile` | mín. 76 | 12 | 3 | columna: icono 22 + texto 12 `w800`, gap 6, padding v 10 / h 4 |
| `OurnegoSocialButton` | 50 | 24 | 4 | 3 ranuras: izquierda 26, centro flexible, derecha 26 (56 si hay badge) |
| `OurnegoGlassIconButton` | 52 | círculo | **sin labio** | icono 22; con `child` (avatar), 6 px de margen interior |
| `OurnegoGlassSurface` (buscador) | 52 | 30 | **sin labio** | envuelve al `SearchBar`, que queda con fondo transparente |
| `OurnegoGlassChip` | 40 | pill | **sin labio** | padding h 16, gap 6, pin 19 en `accentInk`, etiqueta `w600`, acción `w800` subrayada |
| `OurnegoNavBar` | **72** (`navHeight`, sin cambio) | 1000 | **sin labio** | padding 8; indicador círculo 56 en aqua; ítem 56 con icono 30 |
| Anillo de foco | — | radio del elemento + 3 | — | trazo 3 px, separado 3 px del borde |

### 3.6 Movimiento

Constantes nuevas en `lib/core/ournego_motion.dart`:

```dart
// Botones con labio (juguetón)
const Curve kOurnegoSpring = Cubic(0.34, 1.56, 0.64, 1.0);
const Duration kPressDownDuration = Duration(milliseconds: 50);
const Duration kPressReleaseDuration = Duration(milliseconds: 160);
const Duration kBoingDuration = Duration(milliseconds: 340);
const Duration kIconPopDuration = Duration(milliseconds: 450);
const Duration kBurstDuration = Duration(milliseconds: 700);
const Duration kEyesLoaderPeriod = Duration(milliseconds: 720);
const Duration kColorChangeDuration = Duration(milliseconds: 200);

// Flat glass (calmado, sin sobrepaso)
const Curve kCalmCurve = Cubic(0.22, 1.0, 0.36, 1.0);
const Duration kGlassPressDuration = Duration(milliseconds: 90);
const Duration kGlassReleaseDuration = Duration(milliseconds: 240);
const Duration kGlassHoverDuration = Duration(milliseconds: 180);
const Duration kListeningHaloPeriod = Duration(milliseconds: 1800);
const Duration kNavIndicatorDuration = Duration(milliseconds: 380); // con kEaseOutExpo, que ya existe
```

`kCalmCurve` y `kEaseOutExpo` no sobrepasan 1. **NUNCA** uses `kOurnegoSpring` ni ninguna curva con sobrepaso en flat glass.

**Botones con labio**

| Interacción | Valores |
|---|---|
| Hover (solo mouse) | cara `dy: 0 → -1`, `kPressReleaseDuration`, `kOurnegoSpring` |
| Presionar | cara `dy → +labio`, `kPressDownDuration`, `Curves.linear` |
| Soltar sin rebote | cara `dy → 0` (o `-1` si sigue el hover), `kPressReleaseDuration`, `kOurnegoSpring` |
| Rebote al soltar ("boing") | **Reemplaza** a "Soltar". `kBoingDuration` en dos tramos, cada uno con `kOurnegoSpring`. Tramo 1 (0 → 50%): de `dy = +labio, sx = 1.04, sy = 0.92` a `dy = -2, sx = 0.97, sy = 1.04`. Tramo 2 (50 → 100%): a `dy = 0, sx = 1, sy = 1`. Escala alrededor del centro de la cara. |
| Ghost presionar / soltar | escala `1 → 0.94` en `kPressDownDuration`; vuelve en `kPressReleaseDuration` con `kOurnegoSpring`; overlay `ghostOverlay` en hover y pressed |
| Hover de icono `nudge` | icono final `dx: 0 → +3`, 220 ms, `kOurnegoSpring` |
| Hover de icono `wiggle` | icono `rotate 0 → -10°`, `scale 1 → 1.12`, 220 ms, `kOurnegoSpring` |
| Cambio de tono (por ejemplo, a success) | interpolar cara, labio, tinta y contorno en `kColorChangeDuration` |
| Pop de toggle | icono: 0 → 40% `scale 1 → 1.45`, `rotate 0 → -10°`; 40 → 100% de vuelta; `kIconPopDuration`, `kOurnegoSpring` |
| Ráfaga | §6.4 |
| Loader de ojos | §6.3 |

**Flat glass**

| Interacción | Valores |
|---|---|
| Hover (solo mouse) | contorno `glassBorder → glassBorderHover` en `kGlassHoverDuration`, `Curves.easeOut`; icono `scale 1 → 1.06` en `kGlassReleaseDuration`, `kCalmCurve`. Sin desplazamiento. |
| Presionar | elemento completo `scale 1 → 0.96` en `kGlassPressDuration`, `Curves.easeOut` |
| Soltar | `scale → 1` en `kGlassReleaseDuration`, `kCalmCurve`. **Sin rebote.** |
| Buscador enfocado | contorno → `glassActive`; anillo exterior `focusGlow` de 3 px que aparece en 200 ms con `kCalmCurve`; icono de lupa → `accentInk` y `scale 1.06` |
| Micrófono escuchando | contorno y tinta → `glassActive` en 180 ms; el icono cambia de `mic_none_rounded` a `mic_rounded` con fundido de 150 ms; **un** halo de 1 px `haloColor` alrededor que crece `scale 1 → 1.32` mientras baja la opacidad `0.6 → 0`, en bucle de `kListeningHaloPeriod` con `Curves.easeOut` |
| Navbar: cambiar de ítem | el indicador aqua de 56 se **desliza** horizontalmente hasta el ítem nuevo en `kNavIndicatorDuration` con `kEaseOutExpo`. Los iconos cambian de tinta en 200 ms; el activo escala a 1.06 en 300 ms con `kCalmCurve`. |
| Navbar: presionar un ítem | `scale 0.94` en `kGlassPressDuration`; vuelve con `kCalmCurve` |
| Navbar: hover en ítem no activo | fondo `ghostOverlay` en 180 ms |

**Reduced motion:**

- **Botones con labio:** sin rebote, pop ni ráfaga. El loader hace un pulso de opacidad `1 → 0.35 → 1` en 1200 ms. Presionar y soltar se conservan, pero "soltar" usa `Curves.easeOut`.
- **Flat glass:** el halo queda fijo al 40% de opacidad y el indicador de la navbar se coloca sin animar. La escala al presionar se conserva.

### 3.7 Tipografía

En `lib/core/ournego_text_styles.dart`:

```dart
static const TextStyle button = TextStyle(
  fontSize: 16, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.08,
);
static const TextStyle buttonLarge = TextStyle(
  fontSize: 17, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.08,
);
static const TextStyle buttonCompact = TextStyle(
  fontSize: 15, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.08,
);
static const TextStyle buttonSmall = TextStyle(
  fontSize: 14, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: 0.08,
);
static const TextStyle buttonTile = TextStyle(
  fontSize: 12, fontWeight: FontWeight.w800, height: 1.1,
);
```

- `button` cambia de `w700` a `w800`. Sin `fontFamily`.
- `test/core/theme/design_system_tokens_test.dart` DEBE agregar aserciones para los estilos nuevos y para el peso.
- **NUNCA** se pasa un `TextStyle` a un componente de botón desde una feature. El componente elige el estilo según su tamaño. Quitar todos los `style: OurnegoTextStyles.header` que hoy van dentro de botones.

---

## 4. Arquitectura

```
lib/shared/widgets/buttons/
├── buttons.dart                     # barrel: exporta todo lo público de la carpeta
├── ournego_button_tokens.dart       # tonos, paletas (labio y flat glass), tamaños, métricas
├── ournego_pressable.dart           # núcleo con labio: estados, labio, rebote, semántica
├── ournego_glass_pressable.dart     # núcleo flat glass: estados, contorno, escala calmada, blur
├── ournego_button.dart              # OurnegoButton (+ .primary/.neutral/.secondary/...)
├── ournego_icon_button.dart         # OurnegoIconButton (+ .ghost, .toggle)
├── ournego_social_button.dart       # OurnegoSocialButton (+ .google)
├── ournego_row_button.dart          # OurnegoRowButton
├── ournego_action_button.dart       # OurnegoActionButton y OurnegoActionTile
├── ournego_chip.dart                # OurnegoChip.filter / .dropdown
├── ournego_glass_icon_button.dart   # OurnegoGlassIconButton (voz, perfil)
├── ournego_glass_surface.dart       # OurnegoGlassSurface (buscador)
├── ournego_glass_chip.dart          # OurnegoGlassChip (chip de zona)
├── ournego_nav_bar.dart             # OurnegoNavBar + OurnegoNavBarItem
├── nego_eyes_loader.dart            # NegoEyesLoader
└── ournego_burst.dart               # OurnegoBurst (ráfaga de puntos)

lib/shared/widgets/ournego_alert_dialog.dart        # se refactoriza (§6.11)
lib/core/debugging/presentation/pages/button_gallery_screen.dart   # nuevo (§12)

test/shared/widgets/buttons/...                    # pruebas por componente (§11)
test/architecture/no_raw_material_buttons_test.dart  # guardia (§11.3)
```

Reglas de dependencia:

- Las features importan **solo** `package:ournego/shared/widgets/buttons/buttons.dart`.
- **NUNCA** en `lib/`: `ElevatedButton`, `FilledButton`, `OutlinedButton`, `TextButton`, `IconButton`, `FilterChip`, `ChoiceChip`, `ActionChip`, `InputChip` ni `FloatingActionButton`. La única excepción es lo que Flutter o terceros construyen por dentro (`showTimePicker`, `DropdownButtonFormField`, paquete `feedback`).
- Dentro de `lib/shared/widgets/buttons/` tampoco se usan esos widgets:
  - Los botones con labio se construyen sobre `OurnegoPressable`.
  - Los flat glass, sobre `OurnegoGlassPressable`.
  - `OurnegoGlassSurface` no es presionable.
- `BackdropFilter` solo aparece en `ournego_glass_pressable.dart` y `ournego_glass_surface.dart`.
- `NegoAvatar` se importa desde `package:ournego/shared/widgets/nego/nego.dart`.

---

## 5. Núcleo: `OurnegoPressable`

Todos los componentes con labio se construyen sobre este widget. Es el único lugar donde viven los estados, las animaciones de presión, el foco y la semántica.

### 5.1 API

```dart
class OurnegoPressable extends StatefulWidget {
  const OurnegoPressable({
    super.key,
    required this.onPressed,          // null = apagado
    required this.colors,             // OurnegoButtonColors ya resueltos para el tono y brillo
    required this.faceHeight,         // alto de la cara; null = intrínseco (tiles)
    required this.lipDepth,           // 0 para ghost
    required this.borderRadius,
    required this.child,
    this.width,                       // null = intrínseco; double.infinity = expandido
    this.minWidth = 0,
    this.padding = EdgeInsets.zero,
    this.borderWidth = 1,
    this.isLoading = false,
    this.loadingChild,                // default: NegoEyesLoader(color: colors.ink)
    this.isGhost = false,
    this.semanticLabel,
    this.tooltip,
    this.toggled,                     // bool? -> Semantics(toggled:)
    this.enableBoing = true,
    this.focusNode,
    this.autofocus = false,
    this.onHoverChanged,              // para Nego mini
    this.onPressedChanged,            // para Nego mini
  });
}
```

`OurnegoButtonColors` es una clase `@immutable` con `face`, `lip`, `ink` y `border`, y un `lerp` estático para la transición de tono.

### 5.2 Anatomía y árbol de render

Al ancho de la cara se le suma 0 y al alto se le suma `lipDepth`. El labio vive **debajo** y reserva su espacio.

```
Semantics(button: true, enabled:, label:, toggled:, liveRegion: isLoading)
└─ Tooltip? (solo si tooltip != null)
   └─ FocusableActionDetector(
        enabled: onPressed != null && !isLoading,
        mouseCursor: click | forbidden (apagado) | progress (cargando),
        shortcuts: Enter y Espacio -> ActivateIntent,
        actions: ActivateIntent -> _activateFromKeyboard(),
        onShowHoverHighlight / onShowFocusHighlight -> setState)
      └─ _MinTapTarget(min 48×48, centrado, HitTestBehavior.opaque)
         └─ GestureDetector(onTapDown, onTapUp, onTapCancel, onTap)
            └─ SizedBox(width:, height: faceHeight + lipDepth)
               └─ Stack(clipBehavior: Clip.none)
                  ├─ Positioned(left: 0, right: 0, top: lipDepth, height: faceHeight)
                  │    DecoratedBox(color: lip, borderRadius)            ← EL LABIO
                  ├─ Positioned(left: 0, right: 0, top: 0, height: faceHeight)
                  │    AnimatedBuilder(offset + boing)
                  │    └─ Transform(translate(0, dy) · scale(sx, sy) desde el centro)
                  │          └─ DecoratedBox(color: face, border: borderWidth border, borderRadius)
                  │             └─ Padding(padding)
                  │                └─ IconTheme(color: ink) + DefaultTextStyle(color: ink)
                  │                   └─ isLoading ? Stack[ Visibility(maintainSize, child), Center(loader) ] : child
                  └─ if focused: Positioned.fill(-6) DecoratedBox(border 3 focusRing, radius + 6)
```

Puntos a cuidar:

- El labio es un `DecoratedBox` sólido, **NUNCA** una `BoxShadow`.
- Cuando la cara baja `lipDepth` px, cubre por completo al labio.
- Con `faceHeight == null` (tiles), usar `IntrinsicHeight` o un `LayoutBuilder` para que labio y cara compartan altura. Es aceptable medir con un `SizeChangedLayoutNotifier` o un `CustomMultiChildLayout`. Lo que importa es que el labio quede exactamente debajo.
- `ghost`:
  - Sin labio, `lipDepth = 0`, alto total = `faceHeight`.
  - Cara transparente, que en hover y pressed se pinta con `ghostOverlay`.
  - En lugar de bajar, escala `0.94`.
- Al cargar, el contenido real queda en el árbol con `Visibility(visible: false, maintainSize: true, maintainAnimation: true, maintainState: true)`. Así el botón **no cambia de ancho**.

### 5.3 Máquina de estados

Prioridad (el primero que aplique gana):

`disabled` → `loading` → `pressed` → `hovered` → `idle`

`focused` se suma a cualquiera y solo dibuja el anillo.

| Estado | Cara (`dy`) | Colores | Cursor | ¿Dispara `onPressed`? |
|---|---|---|---|---|
| `idle` | 0 | tono | click | — |
| `hovered` | -1 | tono | click | — |
| `pressed` | +`lipDepth` | tono | click | al soltar dentro (`onTap`) |
| `loading` | 0 | tono (no se apaga) | progress | no |
| `disabled` | 0, sin animación | apagado (§3.1) | forbidden | no |

Eventos:

- `onTapDown` → `pressed = true` → animar `dy` a `+lip` en `kPressDownDuration` (lineal). Llamar `onPressedChanged(true)`.
- `onTapUp` → `pressed = false`. Si `enableBoing` y no hay reduced motion, correr el **boing** (§3.6) en lugar de soltar. Si no, soltar con `kOurnegoSpring` hacia `hovered ? -1 : 0`. Llamar `onPressedChanged(false)`.
- `onTapCancel` → soltar **sin** boing.
- `onTap` → `onPressed!()`.
- Teclado (`ActivateIntent`): simular `onTapDown`, esperar `kPressDownDuration`, luego `onTapUp` + `onPressed`.

### 5.4 Implementación de las animaciones

- **Desplazamiento:** usar un `AnimationController` (0..1) que interpola entre `fromDy` y `toDy` guardados en el estado. En cada cambio de estado: `fromDy = dyActual; toDy = destino; controller.duration = …; controller.forward(from: 0)`. El valor es `lerpDouble(fromDy, toDy, curve.transform(t))`. Así `kOurnegoSpring` puede sobrepasar 1 (rebote real) sin que el controller se recorte.
- **Boing:** un segundo `AnimationController` con `kBoingDuration`. Mientras corre, `dy`, `sx` y `sy` salen de una función por tramos:
  - `t ≤ 0.5`: `u = kOurnegoSpring.transform(t / 0.5)`; interpolar del estado A al B.
  - `t > 0.5`: `u = kOurnegoSpring.transform((t - 0.5) / 0.5)`; interpolar del B al C.
  - A = `(dy: lip, sx: 1.04, sy: 0.92)`, B = `(-2, 0.97, 1.04)`, C = `(0, 1, 1)`.
  - Al terminar, el desplazamiento queda en el destino (0 o -1 si sigue el hover).
- **Colores:** `TweenAnimationBuilder<OurnegoButtonColors>` con `kColorChangeDuration` usando `OurnegoButtonColors.lerp`.
- Los controllers se crean en `initState` con `vsync` y se liberan en `dispose`. **NUNCA** usar `setState` dentro de un tick. Usar `AnimatedBuilder`.
- `RepaintBoundary` alrededor de la cara, para que el rebote no repinte el padre.

### 5.5 Semántica y accesibilidad

- `Semantics(button: true)`, con `enabled` según `onPressed`.
- `label` = `semanticLabel` o, si no hay, el texto visible (los componentes de texto lo pasan solos). Los botones **solo de icono DEBEN** recibir `semanticLabel`: es `required` en su API.
- Toggles: `Semantics(toggled: selected)`.
- Cargando: `liveRegion: true` y `NegoEyesLoader` expone `Semantics(label: 'Cargando')`.
- Las `Key` que las features pasan al componente (`key:`) DEBEN quedar en el widget público, para que `find.byKey` y `tester.tap(find.byKey(...))` sigan funcionando. El `tap` sobre el centro del widget debe caer dentro del área sensible.

### 5.6 Área táctil mínima

`_MinTapTarget` envuelve el contenido visual con `ConstrainedBox(minWidth: 48, minHeight: 48)` + `Center` **solo para el hit test**, sin cambiar el tamaño de layout visible. Implementación recomendada:

- Un `SizedBox` del tamaño visual para el layout.
- Dentro, un `OverflowBox` / `Stack(clipBehavior: Clip.none)` con un `GestureDetector` transparente de 48×48 centrado que reenvía los eventos.

Aplica a `small`, `s44`, `s40`, `s32` y `s28`.

### 5.7 Núcleo flat glass: `OurnegoGlassPressable`

Base de `OurnegoGlassIconButton` y `OurnegoGlassChip`. Comparte con `OurnegoPressable` la semántica, el foco, los atajos de teclado y el área táctil mínima (§5.5 y §5.6), pero **no** tiene labio, rebote ni ráfaga.

```dart
class OurnegoGlassPressable extends StatefulWidget {
  const OurnegoGlassPressable({
    super.key,
    required this.onPressed,             // null = apagado
    required this.child,
    required this.height,                // 52 (icono) o 40 (chip)
    this.width,                          // null = intrínseco
    this.borderRadius,                   // null = círculo
    this.padding = EdgeInsets.zero,
    this.active = false,                 // micrófono escuchando
    this.showHalo = false,               // halo animado mientras active
    this.semanticLabel,
    this.tooltip,
    this.focusNode,
  });
}
```

Árbol de render:

```
Semantics(button: true, enabled:, label:)
└─ FocusableActionDetector(... igual que OurnegoPressable ...)
   └─ _MinTapTarget(48×48)
      └─ GestureDetector(onTapDown, onTapUp, onTapCancel, onTap)
         └─ AnimatedBuilder(scale)                       ← 1 → 0.96 → 1, sin sobrepaso
            └─ Stack(clipBehavior: Clip.none)
               ├─ if active && showHalo: _ListeningHalo   ← detrás, sin recortar
               └─ ClipRRect(radio)
                  └─ BackdropFilter(blur 10)
                     └─ AnimatedContainer(kGlassHoverDuration, curve: Curves.easeOut,
                          color: glassFace,
                          border: 1 px, glassBorder | glassBorderHover | glassActive,
                          borderRadius)
                        └─ IconTheme(color: active ? accentInk : onSurface,
                                     size: 22, animated scale 1.06 en hover)
                           └─ child
```

- El contorno se dibuja **dentro** del `AnimatedContainer`, como hoy en `_CrystalItemContainer`. Siempre mide 1 px.
- Apagado: opacidad del contenido al 38% y contorno `borderMuted`. Sin animaciones.
- **NUNCA** uses `kOurnegoSpring` aquí. La escala usa un `AnimationController` con `kGlassPressDuration` (`Curves.easeOut`) al bajar y `kGlassReleaseDuration` (`kCalmCurve`) al subir.

---

## 6. Componentes públicos

### 6.1 `OurnegoButton`

```dart
enum OurnegoButtonSize { large, regular, compact, small }
enum OurnegoButtonStatus { idle, loading, success }
enum OurnegoIconMotion { none, nudge, wiggle }

class OurnegoButton extends StatelessWidget {
  const OurnegoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.tone = OurnegoButtonTone.primary,
    this.size = OurnegoButtonSize.regular,
    this.icon,                         // IconData? a la izquierda
    this.trailingIcon,                 // IconData? a la derecha
    this.iconMotion = OurnegoIconMotion.none,
    this.expanded = false,             // ancho completo
    this.minWidth,                     // double?
    this.status = OurnegoButtonStatus.idle,
    this.successLabel = '¡Listo!',
    this.showNego = false,
    this.radius,                       // double? solo floating sheet (14)
    this.semanticLabel,
  });

  const OurnegoButton.primary({...}) : tone = OurnegoButtonTone.primary;
  const OurnegoButton.neutral({...}) : tone = OurnegoButtonTone.neutral;
  const OurnegoButton.secondary({...}) : tone = OurnegoButtonTone.secondary;
  const OurnegoButton.tonal({...}) : tone = OurnegoButtonTone.tonal;
  const OurnegoButton.destructive({...}) : tone = OurnegoButtonTone.destructive;
  const OurnegoButton.text({...}) : tone = OurnegoButtonTone.ghost;
}
```

Comportamiento:

- **Contenido:** `Row(mainAxisSize: min)` con `[NegoMini?][icono?][Text(label)][trailing?]`. Gap según el tamaño (§3.3). El texto es de una línea con `TextOverflow.ellipsis` y usa el estilo del tamaño (§3.7).
- **Ancho:** intrínseco por defecto; `expanded: true` → `double.infinity`; `minWidth` asegura un ancho mínimo y el contenido queda centrado.
- **`status == loading`:** muestra `NegoEyesLoader` con el color de la tinta, ignora toques y mantiene el ancho.
- **`status == success`:**
  - El tono pasa a `success` con transición de color.
  - El texto cambia a `successLabel`.
  - Nego pasa a `winking` si está visible.
  - Se dispara **una** ráfaga de 14 puntos en la transición `≠ success → success` (detectarla en `didUpdateWidget` de un `StatefulWidget` interno).
  - El botón no es tocable mientras dure.
- **Iconos:** `iconMotion` afecta el `trailingIcon` cuando es `nudge` y el `icon` cuando es `wiggle`. Solo en hover de mouse.
- **`showNego`** solo se permite con tono `primary` y tamaños `large`, `regular` o `compact`. Agrega un `assert`.
- **Tono `ghost` (`OurnegoButton.text`):**
  - Sin labio.
  - Padding horizontal del tamaño.
  - Tinta `onSurface`.
  - Overlay `ghostOverlay` en hover y pressed.
  - Escala 0.94 al presionar.

### 6.2 Nego mini dentro del primario

Widget privado `_NegoMini` dentro de `ournego_button.dart`:

```dart
Transform.translate(
  offset: const Offset(-6, 0),
  child: NegoAvatar(
    size: size == OurnegoButtonSize.compact ? 26 : 30,
    interactive: false,
    mood: status == success ? NegoMood.winking
        : hovered ? NegoMood.excited
        : NegoMood.idle,
    eyesClosed: onPressed == null,     // apagado -> ojos cerrados (§8)
    happyTrigger: _pressCount,         // se incrementa en cada onPressedChanged(true) (§8)
  ),
)
```

- Mientras `status == loading`, Nego queda oculto junto con el resto del contenido; el loader *son* sus ojos.
- Nego mini no cambia el alto del botón: 30 cabe en 50 y 56, y 26 cabe en 44.

### 6.3 `NegoEyesLoader`

```dart
NegoEyesLoader({required Color color, double eyeWidth = 7, double eyeHeight = 17, double gap = 5})
```

- Dos cápsulas (`BorderRadius.circular(4)`) del color de la tinta, separadas `gap`.
- Bucle de `kEyesLoaderPeriod` con `Curves.easeInOut`. Cada ojo sigue estos keyframes (escala desde el centro):

| t | `dy` | `scaleY` |
|---|---|---|
| 0% | 0 | 1 |
| 30% | -4 | 1.08 |
| 55% | +1 | 0.5 |
| 100% | 0 | 1 |

- El segundo ojo va desfasado 120 ms.
- Con reduced motion: sin desplazamiento; la opacidad de ambos ojos pulsa `1 → 0.35 → 1` en 1200 ms.
- `Semantics(label: 'Cargando')`.

### 6.4 `OurnegoBurst`

Ráfaga de puntos que sale del centro del botón. **NUNCA** debe recortarse por un `ClipRRect` o un `ListView` ancestro, así que se dibuja en el `Overlay`.

```dart
class OurnegoBurst extends StatefulWidget {
  const OurnegoBurst({super.key, required this.child, required this.trigger, this.count = 14});
  final Widget child;
  final Object? trigger;   // cada vez que cambia (y no es null) se reproduce una ráfaga
  final int count;
}
```

- Implementación: `CompositedTransformTarget` en el hijo + `OverlayPortal` con `CompositedTransformFollower` centrado; un `CustomPainter` dibuja los puntos durante `kBurstDuration` y luego oculta el portal.
- Cada punto:
  - Círculo de 8 px.
  - Ángulo = `i / count * 360° + random(0..20°)`.
  - Distancia final = `random(34..60)` px.
  - Curva `kEaseOutExpo`; escala `1 → 0.3`; opacidad `1 → 0`.
  - Color = `burstColors[i % 4]`.
- Usos: `count = 14` en `OurnegoButton` al entrar en success; `count = 10` en `OurnegoIconButton.toggle(celebrate: true)` y `OurnegoActionTile` toggle, solo al pasar a seleccionado.
- Con reduced motion no se dibuja nada.

### 6.5 `OurnegoIconButton` (con labio)

```dart
enum OurnegoIconButtonSize { s52, s48, s44, s40, s32, s28 }

class OurnegoIconButton extends StatelessWidget {
  const OurnegoIconButton({
    super.key,
    required this.icon,                 // IconData
    required this.semanticLabel,        // obligatorio
    required this.onPressed,
    this.tone = OurnegoButtonTone.glass,
    this.size = OurnegoIconButtonSize.s52,
    this.radius,                        // null = círculo; 16 mapa, 14 sheet
    this.outlined,                      // bool?; null = lo que diga el tono (§3.1)
    this.child,                         // reemplaza al icono (ej. avatar)
    this.iconMotion = OurnegoIconMotion.none,
    this.tooltip,
  });

  const OurnegoIconButton.ghost({...})  // tone: ghost, size: s48 por defecto

  const OurnegoIconButton.toggle({
    super.key,
    required this.selected,
    required this.icon,                 // icono apagado (ej. favorite_border_rounded)
    required this.selectedIcon,         // icono encendido (ej. favorite_rounded)
    required this.semanticLabel,
    required this.onChanged,            // ValueChanged<bool>?
    this.tone = OurnegoButtonTone.tonal,
    this.size = OurnegoIconButtonSize.s32,
    this.radius,
    this.outlined,
    this.celebrate = false,             // ráfaga de 10 al encender
  });
}
```

Reglas:

- `outlined: true` agrega el contorno `borderSubtle` de 1 px y cambia el labio a `outlineLip`. Solo se usa con `tonal` en los controles del sheet. `glass`, `secondary` y `white` ya lo traen por tono.
- El toggle corre el **pop** sobre el icono en cada cambio, expone `Semantics(toggled: selected)` y cambia de icono con un `AnimatedSwitcher` de 0 ms (el pop ya da el movimiento).
- `child` (avatar): se recorta en círculo dentro de la cara, con 6 px de margen interior en `s52` y 5 en `s44`.
- **NUNCA** se usa `OurnegoIconButton` para voz ni perfil en la barra superior del mapa. Esos son `OurnegoGlassIconButton` (§6.12).

### 6.6 `OurnegoSocialButton`

```dart
OurnegoSocialButton({
  super.key,
  required Widget leading,          // Icon(…_rounded, size: 22) o Image.asset
  required String label,
  required VoidCallback? onPressed,
  String? badge,                    // ej. 'Pronto'
  OurnegoButtonTone tone = OurnegoButtonTone.secondary,
})

factory OurnegoSocialButton.google({Key? key, required VoidCallback? onPressed})
// leading: Image.asset('assets/images/google.png', width: 22), label: 'Continuar con Google', tone: white
```

- Siempre `expanded`, tamaño `regular`.
- Layout de tres ranuras: `SizedBox(width: side, child: leading)` · `Expanded(Center(label))` · `SizedBox(width: side, child: badge?)`, con `side = badge == null ? 26 : 56`. Así el texto queda centrado aunque haya badge.
- Badge: `Container(padding: (7, 3), shape: pill, color: tonal.face)` con texto 10.5 `w800` en mayúsculas, `letterSpacing 0.6` y color `tonal.ink`.
- El ícono `leading` hace `wiggle` en hover.

### 6.7 `OurnegoRowButton`

```dart
OurnegoRowButton({super.key, required IconData icon, required String label, required VoidCallback? onPressed})
```

- Tono `glass`, alto 58, radio 30, labio 4, ancho completo.
- A la izquierda, un círculo de acento de 36 px con fondo `tonal.face` e icono 20 en `tonal.ink`.
- Texto centrado con `Expanded` y estilo `button`.
- A la derecha, `Icons.chevron_right_rounded` 26 en `accentInk` con `iconMotion: nudge`.

### 6.8 `OurnegoActionButton` y `OurnegoActionTile`

```dart
OurnegoActionButton({super.key, required IconData icon, required String semanticLabel, required VoidCallback? onPressed})
// glass, alto 42, radio 12, labio 3, icono 22 con wiggle; ancho = el del padre (usar dentro de Expanded)

OurnegoActionTile({super.key, required IconData icon, required String label, required VoidCallback? onPressed,
                   IconData? selectedIcon, bool? selected, bool celebrate = false})
// glass, alto mínimo 76, radio 12, labio 3; Column(icono 22, gap 6, Text buttonTile)
// si selected != null se comporta como toggle (pop + ráfaga de 10 al encender si celebrate)
```

### 6.9 `OurnegoChip` (con labio)

```dart
OurnegoChip.filter({super.key, required String label, required bool selected, required ValueChanged<bool> onSelected})

OurnegoChip.dropdown<T>({
  super.key,
  required String placeholder,        // 'Categoría' | 'Distancia'
  required T? value,
  required List<OurnegoChipOption<T>> options,
  required ValueChanged<T?> onChanged,
})

class OurnegoChipOption<T> { const OurnegoChipOption({required this.value, required this.label}); final T value; final String label; }
```

- Común a los dos: alto 40, pill, labio 3, padding h 16, gap 6, fuente `buttonSmall`.
- Viven dentro del panel de búsqueda, no flotan sobre el mapa. Por eso llevan labio y tono `glass`, con contorno (el `FilterChip` de Material que reemplazan ya tenía contorno).
- **`.filter`:**
  - Apagado: tono `glass`.
  - Seleccionado: tono `primary` sin contorno, con `Icons.check_rounded` 18 delante del texto.
  - Expone `Semantics(toggled:)`.
- **`.dropdown`:**
  - Tono `glass` con `Icons.expand_more_rounded` 22 detrás del texto.
  - El texto muestra la etiqueta de la opción elegida o el `placeholder`.
  - Al tocar abre un `MenuAnchor` debajo del chip, con una entrada por opción más la entrada "Todas" o "Cualquiera" con valor `null` (conservar las entradas actuales de `_compactDropdown`).
  - Las entradas del menú usan `MenuItemButton`, que es parte del menú y no cuenta como botón crudo: excepción explícita para la prueba de §11.3.

El chip de zona **no** es un `OurnegoChip`: es `OurnegoGlassChip` (§6.12).

### 6.10 `OurnegoNavBar` (flat glass, sin labio)

```dart
class OurnegoNavBarItem {
  const OurnegoNavBarItem({required this.icon, required this.label});
  final IconData icon;
  final String label;                 // etiqueta semántica
}

class OurnegoNavBar extends StatefulWidget {
  const OurnegoNavBar({
    super.key,
    required this.items,              // 3 hoy
    required this.currentIndex,
    required this.onTap,              // ValueChanged<int>
  });
}
```

- **Contenedor flat glass**, igual que hoy:
  - Color `colorScheme.surface` (opaco, sin blur).
  - Contorno 1 px `borderSubtle`.
  - Radio `OurnegoRadiusTokens.pill`.
  - `BoxShadow(color: OurnegoColorTokens.shadow, blurRadius: 10, spreadRadius: 0.2)`.
  - Alto `OurnegoSpacingTokens.navHeight` (**72, sin cambio**).
  - Padding 8.
- **Indicador:**
  - Un solo círculo aqua de 56 detrás de los iconos, posicionado con `AnimatedPositioned` (o un `AnimationController` + `Transform.translate`) en el centro del ítem activo.
  - Se desliza al cambiar `currentIndex` en `kNavIndicatorDuration` con `kEaseOutExpo`.
  - No lleva labio ni rebota.
  - Con reduced motion, duración 0.
  - Calcula la posición con un `LayoutBuilder`: cada ítem ocupa `ancho / items.length`.
- **Ítems:**
  - Círculo de 56 con icono 30, sin fondo propio.
  - Activo: tinta `0xFF161616` (noche) y escala 1.06.
  - Inactivo: tinta `onSurface`, hover `ghostOverlay` y escala 0.94 al presionar.
  - Todo según §3.6 flat glass.
  - `Semantics(button: true, selected:, label:)`.

`AppNavigationBar` (`features/navigation/presentation/widgets/navigation_bar_widget.dart`) queda como un envoltorio delgado:

- Construye `OurnegoNavBar` con un `OurnegoNavBarItem` por icono y etiqueta del datasource (`['Inicio', 'Mapa', 'Mi Negocio']`).
- Conserva `appNavigationBarKey`, la firma `AppNavigationBar(currentIndex:, onTap:)`, el `BottomAppBar` transparente, el margen exterior `fromLTRB(48, 0, 48, 4)` y el ancho de 400 en pantallas de más de 600.
- Se elimina `_CrystalNavItem`. **NUNCA** se copian los ítems a mano.

### 6.11 Acciones de `OurnegoAlertDialog`

Nueva API (rompe la anterior y se migran todos los usos):

```dart
@immutable
class OurnegoDialogAction {
  const OurnegoDialogAction({required this.label, required this.onPressed, this.key, this.isDestructive = false});
  final String label;
  final VoidCallback onPressed;
  final Key? key;
  final bool isDestructive;
}

class OurnegoAlertDialog extends StatelessWidget {
  const OurnegoAlertDialog({
    super.key,
    required this.title,
    required this.content,
    required this.primaryAction,
    this.secondaryAction,
  });
}
```

Render de las acciones, en un `OverflowBar(alignment: end, spacing: 8, overflowSpacing: 8)`:

- `secondaryAction` → `OurnegoButton.text(size: compact, key: secondaryAction.key, …)`.
- `primaryAction` → `OurnegoButton.destructive(...)` si `isDestructive`, o `OurnegoButton.primary(...)` en caso contrario, con `size: compact` y su `key`.

El resto del diálogo (vidrio, 320×400, radio 18, `title` y `content`) se queda igual.

### 6.12 Componentes flat glass

```dart
OurnegoGlassIconButton({
  super.key,
  required IconData icon,
  required String semanticLabel,
  required VoidCallback? onPressed,
  IconData? activeIcon,               // ej. mic_rounded cuando active
  bool active = false,                // contorno y tinta accentInk
  bool showHalo = false,              // halo animado mientras active (micrófono)
  Widget? child,                      // reemplaza al icono (avatar de perfil)
  String? tooltip,
})
// 52×52, círculo, sobre OurnegoGlassPressable.

OurnegoGlassSurface({
  super.key,
  required Widget child,              // el SearchBar del mapa
  double borderRadius = OurnegoRadiusTokens.container, // 30
  double height = 52,
})
// No presionable. glassFace + blur 10 + contorno 1 px.
// Hover: contorno glassBorderHover.
// Cuando un descendiente tiene foco (Focus.hasFocus vía FocusScope / onFocusChange):
//   contorno glassActive + anillo exterior focusGlow de 3 px.
// Transiciones con kCalmCurve.

OurnegoGlassChip({
  super.key,
  required String label,              // 'Zona: Centro'
  required String actionLabel,        // 'Cambiar'
  required VoidCallback? onPressed,
  IconData leadingIcon = Icons.place_rounded,
  String? semanticLabel,
})
// Alto 40, pill, sobre OurnegoGlassPressable. Pin 19 en accentInk; label w600 con ellipsis;
// actionLabel w800 subrayado; ancho máximo = el del padre.
```

Comportamiento del micrófono (`OurnegoGlassIconButton` con `active` y `showHalo`):

- **En reposo:** icono `mic_none_rounded` en `onSurface`.
- **Escuchando:** contorno y tinta `accentInk`, icono `mic_rounded` y un halo de 1 px que se expande y desvanece (§3.6).
- La cara **no** se llena de aqua; se queda en `glassFace`.
- `Semantics(toggled: active)` y etiqueta "Buscar por voz" o "Detener búsqueda por voz".


---

## 7. Cambios en tema y tokens existentes

| Archivo | Cambio |
|---|---|
| `lib/core/theme/ournego_theme.dart` | `ColorScheme.light(onPrimary: OurnegoColorTokens.noche)`, antes `Colors.white`. Esto arregla también el badge "Principal" de la galería del panel. **No** agregar `outline` al `ColorScheme.light`: el contorno negro al 30% que hoy se ve depende de que no esté definido. |
| `lib/core/theme/ournego_button_styles.dart` | Renombrar la clase a `OurnegoButtonThemes` y el archivo a `ournego_button_themes.dart`. Se mantienen `elevatedButtonTheme` y `outlinedButtonTheme` como red de seguridad para widgets internos de Flutter. Cambiar `foregroundColor` del elevated a `colorScheme.onPrimary`, que ya es noche. |
| `lib/core/theme/ournego_theme.dart` | `textButtonTheme` se queda, porque lo usan `showTimePicker` y `showDatePicker`. |
| `lib/core/ournego_text_styles.dart` | §3.7. |
| `lib/core/ournego_motion.dart` | Constantes de §3.6. |
| `lib/core/theme/tokens/ournego_spacing_tokens.dart` | **Sin cambios.** `navHeight` sigue en 72. |
| `lib/shared/widgets/ournego_buttons.dart` | **Eliminar** al terminar la migración: `OurnegoPrimaryButton`, `OurnegoNeutralPrimaryButton` y el `OurnegoButtonStyles` de shared. |
| `lib/core/ournego_colors.dart` | Sin cambios, pero ningún componente de botón lo usa. Los botones leen de `OurnegoButtonPalette` y `OurnegoGlassPalette`. |

---

## 8. Extensiones de `NegoAvatar`

Cambios mínimos en `lib/shared/widgets/nego/`, sin romper el README de Nego ni los tests existentes:

1. **`NegoTokens.eyesClosedScaleY = 0.1`.**
2. **`NegoAvatar({bool eyesClosed = false})`:**
   - Cuando es `true`, `NegoMotionController` mantiene la escala vertical de ambos ojos en `eyesClosedScaleY` y no programa parpadeos.
   - Reutilizar el mecanismo existente `_isBlinkScaleOverridden`, igual que hace `winking`.
   - Al volver a `false`, reanudar el ciclo de parpadeo.
   - Esto **no** es un morph de path: es la misma escala vertical que ya usa el parpadeo, así que respeta la regla del README.
3. **`NegoAvatar({Object? happyTrigger})`:** cuando el valor cambia en `didUpdateWidget` y no es `null`, llamar `_controller.triggerHappy()` **aunque `interactive` sea `false`**. `interactive` sigue controlando tap, foco y seguimiento del puntero.
4. Exponer ambos parámetros en `NegoMotionController.updateConfiguration` como `eyesClosed`.
5. **Pruebas** en `test/shared/widgets/nego/nego_avatar_test.dart`:
   - `eyesClosed` deja `blinkScaleY == 0.1` y no programa timers.
   - Cambiar `happyTrigger` pone `activeMood == NegoMood.happy` durante `happyTemporaryDuration`.
6. **`NegoAvatar({bool floating = true})`:**
   - Con `false`, el `_idleController` **no** corre en bucle y el cuerpo queda quieto.
   - El Nego mini de los botones DEBE usar `floating: false`. Hay dos razones:
     - En el playground el mini no flota; solo flota el Nego grande.
     - Una animación infinita dentro de un botón rompe `tester.pumpAndSettle()` en las pruebas que ya existen: `integration_test/auth_test.dart`, `core_flow_test.dart` y `onboarding_test.dart` lo usan.
   - El parpadeo usa `Timer` entre parpadeos, así que no impide que `pumpAndSettle` termine.
7. **Opcional, solo si es trivial:** respetar `MediaQuery.disableAnimationsOf` desactivando la flotación. Si no es trivial, déjalo anotado como deuda en el PR.

---

## 9. Mapa de migración

Las líneas son aproximadas y corresponden al commit `a59258e`; ubica cada caso por el contenido, no solo por el número.

Reglas generales para todas las filas:

- **Conservar la `Key`:** ponerla en el `key:` del componente nuevo. `buttonKey` desaparece; los llamadores pasan `key:`.
- **Conservar `onPressed` y el texto**, salvo lo indicado en §9.9.
- **Quitar los envoltorios de tamaño fijo** (`SizedBox(height: 50/56/60, width: …)`) y los `style:` de texto que había dentro del botón. Si había un ancho fijo, usar `minWidth` con el mismo valor.
- **Iconos:** pasar a la variante `_rounded`.

### 9.1 Auth

| Archivo · línea | Hoy | Nuevo | Key / notas |
|---|---|---|---|
| `auth/presentation/pages/login_email_screen.dart` · 154 | `PrimaryButton` → `OurnegoPrimaryButton(buttonKey:)` | `OurnegoButton.primary(key: buttonKey, label: text.primaryButton, expanded: true, showNego: true)` | `loginSubmitButton`. Se conserva el nombre público `PrimaryButton` (no se renombra) para no romper importaciones. |
| `login_email_screen.dart` · 289 | `IconButton` en `suffixIcon` | `OurnegoIconButton.ghost(size: s40, icon: _isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, semanticLabel: _isObscure ? 'Mostrar contraseña' : 'Ocultar contraseña')` | — |
| `auth/presentation/pages/signup_email_screen.dart` · 84 | `OurnegoPrimaryButton` | `OurnegoButton.primary(expanded: true, showNego: true)` | — |
| `auth/presentation/pages/create_password_screen.dart` · 198 | `OurnegoPrimaryButton` | `OurnegoButton.primary(expanded: true)` | — |
| `auth/presentation/pages/password_recovery_screen.dart` · 114 | `OurnegoPrimaryButton` con spinner manual | `OurnegoButton.primary(label: 'Enviar correo', expanded: true, status: _isLoading ? loading : idle, onPressed: _submit)` | Quitar `CircularProgressIndicator`. `onPressed` ya no se vuelve `null` al cargar: el estado `loading` bloquea solo. |
| `auth/presentation/pages/verify_email_screen.dart` · 132 | `OurnegoPrimaryButton` | `OurnegoButton.primary(expanded: true)`, mismo texto dinámico y misma condición `null` | Los dos `CircularProgressIndicator` de estado (líneas 100 y 116) **no** se tocan: no son botones. |
| `auth/presentation/pages/account_check_failed_screen.dart` · 46 | `OurnegoPrimaryButton(buttonKey:)` | `OurnegoButton.primary(key: Key('account-check-retry'), label: 'Reintentar', icon: Icons.refresh_rounded, iconMotion: wiggle, expanded: true)` | — |
| `account_check_failed_screen.dart` · 52 | `TextButton` | `OurnegoButton.text(key: Key('account-check-continue'), label: 'Continuar al mapa')` | — |
| `auth/presentation/pages/complete_profile_screen.dart` · 124 | `ElevatedButton` editar foto (50×50) | `OurnegoIconButton(tone: primary, size: s44, icon: Icons.edit_rounded, semanticLabel: 'Cambiar foto de perfil')` | — |
| `complete_profile_screen.dart` · 180 | `TextButton` Reintentar | `OurnegoButton.text(key: Key('profile-load-retry'), size: small, label: 'Reintentar')` | — |
| `complete_profile_screen.dart` · 190 | `OurnegoPrimaryButton` | `OurnegoButton.primary(expanded: true, showNego: true)` | — |
| `auth/presentation/widgets/auth_selection_widget.dart` · 143 | `GuestAccessButton` (`OutlinedButton` + `authOutlinedOnSurface`) | `OurnegoSocialButton(key: ValueKey('guestAccessButton'), leading: Icon(Icons.person_rounded), label: 'Continuar como invitado')` | Se conservan las clases públicas `GuestAccessButton`, `PhoneLoginButton`, `MailLoginButton` y `GoogleLoginButton` como envoltorios delgados (su lógica no cambia). Se quitan los `SizedBox(height: 50)`. |
| `auth_selection_widget.dart` · 175 | `PhoneLoginButton` con `onPressed: () {}` | `OurnegoSocialButton(leading: Icon(Icons.call_rounded), label: 'Continuar con número telefónico', onPressed: null, badge: 'Pronto')` | Queda **apagado** a propósito, porque hoy no hace nada. |
| `auth_selection_widget.dart` · 202 | `MailLoginButton` | `OurnegoSocialButton(key: ValueKey('emailAccessButton'), leading: Icon(Icons.mail_rounded), label: 'Continuar con correo')` | — |
| `auth_selection_widget.dart` · 234 | `GoogleLoginButton` (`ElevatedButton` + `authFilledOnSurface`) | `OurnegoSocialButton.google(onPressed: …)` | Se borra el comentario "Asegúrate de que esta imagen exista". |
| `auth/presentation/widgets/session_expired_listener.dart` · 34 | `OurnegoAlertDialog(actionLabel: 'Iniciar sesión', trailingActions: [TextButton('Seguir como invitado')])` | `primaryAction: OurnegoDialogAction(label: 'Iniciar sesión', …)`, `secondaryAction: OurnegoDialogAction(label: 'Seguir como invitado', …)` | — |

### 9.2 Onboarding

| Archivo · línea | Hoy | Nuevo | Key / notas |
|---|---|---|---|
| `onboarding/presentation/pages/onboarding_screen.dart` · 63 | `TextButton` 'Entendido' en `OurnegoInformationDialog` | `OurnegoButton.text(size: compact, label: 'Entendido')` | — |
| `onboarding_screen.dart` · 69 | `FilledButton` 'Abrir ajustes' | `OurnegoButton.primary(size: compact, label: 'Abrir ajustes')` | — |
| `onboarding_screen.dart` · 391 | `IconButton` regresar | `OurnegoIconButton.ghost(key: ValueKey('onboardingBackButton'), size: s48, icon: Icons.arrow_back_rounded, semanticLabel: 'Regresar', tooltip: 'Regresar')` | — |
| `onboarding/.../explore_onboarding_screen.dart` · 54 | `OurnegoNeutralPrimaryButton` en `SizedBox(200×56)` con texto `header` | `OurnegoButton.neutral(key: ValueKey('onboardingExploreContinueButton'), size: large, minWidth: 200, label: 'Explorar', trailingIcon: Icons.arrow_forward_rounded, iconMotion: nudge)` | — |
| `onboarding/.../discover_onboarding_screen.dart` · 60 | `OurnegoNeutralPrimaryButton` en `SizedBox(160×56)` | `OurnegoButton.neutral(key: ValueKey('onboardingDiscoverContinueButton'), size: large, minWidth: 160, label: 'Continuar', trailingIcon: Icons.arrow_forward_rounded, iconMotion: nudge)` | — |
| `onboarding/.../location_onboarding_screen.dart` · 113 | `OurnegoPrimaryButton` en `SizedBox(160×60)` con texto `header` | `OurnegoButton.primary(key: ValueKey('activateLocationButton'), size: large, minWidth: 160, label: _isPermissionGranted ? 'Continuar' : 'Activar')` | Sin Nego: la pantalla ya tiene ilustración. |

### 9.3 Negocio

| Archivo · línea | Hoy | Nuevo | Key / notas |
|---|---|---|---|
| `business/presentation/pages/business_form_screen.dart` · 292 y 302 | `OutlinedButton` 'Feedback' + `FilledButton` 'Entiendo' en `Row` de `Expanded` | `OurnegoButton.secondary(size: compact, expanded: true, label: 'Feedback')` + `OurnegoButton.primary(size: compact, expanded: true, label: 'Entiendo')` | El gap pasa de 12 a `OurnegoSpacingTokens.sm` (12). |
| `business_form_screen.dart` · 444 | `FilledButton` 'Subir foto del negocio' (56) con `Row` e icono de estado | `OurnegoButton.tonal(size: large, expanded: true, label: 'Subir foto del negocio', icon: _pickedImageBytes == null ? Icons.add_a_photo_rounded : Icons.check_circle_rounded, iconMotion: wiggle)` | Se conserva la lógica del icono que hoy está en el `Row`. |
| `business_form_screen.dart` · 638 | `FilledButton` 'Registrar Negocio' con spinner | `OurnegoButton.primary(size: large, expanded: true, label: 'Registrar negocio', status: _isSending.value ? loading : idle, showNego: true)` | Quitar el spinner manual. |
| `business_form_screen.dart` · 712 | `OurnegoAlertDialog(title: 'Error', onAction:)` | `primaryAction: OurnegoDialogAction(label: 'Entendido', onPressed: …)` | — |
| `business/presentation/widgets/register_business_widget.dart` · 29 y 49 | Feedback / Entiendo | Igual que `business_form_screen` 292/302 | — |
| `register_business_widget.dart` · 84 | `ElevatedButton` 'Comenzar' (secundario aguamarina, 200×60, texto `header`) | `OurnegoButton.primary(size: large, minWidth: 200, label: 'Comenzar', showNego: true)` | Pasa a primario: es el único CTA de la pantalla. |
| `business/presentation/widgets/business_panel_dashboard_widget.dart` · 103/107, 196/200, 261/265 | `TextButton` 'Cancelar' + `FilledButton` 'Guardar' en `AlertDialog` | `OurnegoButton.text(size: compact, label: 'Cancelar')` + `OurnegoButton.primary(size: compact, label: 'Guardar')` | El `AlertDialog` no se toca. |
| `business/.../dialogs/location_editor_dialog.dart` · 114/118 | Igual | Igual | — |
| `business/.../business_panel/business_panel_states.dart` · 54 | `FilledButton` 'Reintentar' | `OurnegoButton.primary(size: compact, label: 'Reintentar', icon: Icons.refresh_rounded, iconMotion: wiggle)` | — |
| `business/.../business_panel/business_panel_gallery.dart` · 45 | `FilledButton.icon` 'Agregar imagen' | `OurnegoButton.primary(size: compact, label: 'Agregar imagen', icon: Icons.add_rounded)` | — |
| `business_panel_gallery.dart` · 117 | `BusinessPanelIconButton(small)` borrar | `OurnegoIconButton(size: s28, icon: Icons.delete_outline_rounded, semanticLabel: 'Eliminar imagen')` | — |
| `business/.../business_panel/business_panel_header.dart` · 30 | `BusinessPanelIconButton` perfil | `OurnegoIconButton(size: s44, icon: isLogged ? Icons.account_circle_rounded : Icons.login_rounded, child: avatar si hay imagen, semanticLabel: isLogged ? 'Perfil' : 'Iniciar sesión')` | El avatar se recorta en círculo con `errorBuilder` igual que hoy. |
| `business/.../business_panel/business_panel_section_header.dart` · 22 | `BusinessPanelIconButton(small)` | `OurnegoIconButton(size: s28, icon: actionIcon, semanticLabel: actionIcon == Icons.add_rounded ? 'Agregar en $title' : 'Editar $title')` | — |
| `business/.../business_panel/business_panel_map_preview.dart` · 90 | `BusinessPanelIconButton(small)` | `OurnegoIconButton(size: s28, icon: Icons.edit_rounded, semanticLabel: 'Editar ubicación')` | — |
| `business/.../business_panel/business_panel_info_grid.dart` · 115 | `BusinessPanelIconButton(small)` | `OurnegoIconButton(size: s28, icon: Icons.edit_rounded, semanticLabel: 'Editar $title')` | — |

### 9.4 Mapa

| Archivo · línea | Hoy | Nuevo | Key / notas |
|---|---|---|---|
| `map/presentation/pages/map_screen.dart` · 319/339 | Feedback / Entiendo | Igual que en 9.3 | — |
| `map_screen.dart` · 657 | `ZoneChip(label:, onTap:)` | `OurnegoGlassChip(key: Key('zone-chip'), label: 'Zona: ${reference.label}', actionLabel: 'Cambiar', onPressed: _openZonePicker, semanticLabel: 'Zona: ${reference.label}. Cambiar')` | **Flat glass, sin labio.** Se borra `zone_chip_widget.dart`. |
| `map/presentation/widgets/map_location_banner_widget.dart` · 69 | `FilledButton` compacto (36) | `OurnegoButton.primary(key: Key('map-location-banner-action'), size: small, label: actionLabel)` | El contenedor del banner no cambia. |
| `map/presentation/widgets/location_access_sheet_widget.dart` · 68 | `FilledButton` | `OurnegoButton.primary(key: Key('location-access-primary'), expanded: true, label: …)` | — |
| `location_access_sheet_widget.dart` · 78 | `OutlinedButton` | `OurnegoButton.secondary(key: Key('location-access-secondary'), expanded: true, label: …)` | — |
| `map/presentation/widgets/top_navigation_bar_widget.dart` · 57 | `ElevatedButton` + `circularSurface` (micrófono) dentro de `_CrystalItemContainer` | `OurnegoGlassIconButton(icon: Icons.mic_none_rounded, activeIcon: Icons.mic_rounded, active: isVoiceListening, showHalo: true, semanticLabel: isVoiceListening ? 'Detener búsqueda por voz' : 'Buscar por voz', onPressed: onVoiceSearchTap)` | **Flat glass, sin labio.** Sin `_CrystalItemContainer`: el componente ya trae contorno y blur. |
| `top_navigation_bar_widget.dart` · 94 | `ElevatedButton` + `circularSurface` (perfil) | `OurnegoGlassIconButton(key: ValueKey('mapProfileButton'), icon: isLogged ? Icons.account_circle_rounded : Icons.login_rounded, child: avatar 40 si hay imagen, semanticLabel: 'Abrir menú de perfil', onPressed: …)` | **Flat glass, sin labio.** |
| `top_navigation_bar_widget.dart` · `SearchBar` | `SearchBar` dentro de `_CrystalItemContainer` | `OurnegoGlassSurface(child: SearchBar(...))`, con el `backgroundColor` del `SearchBar` transparente, `elevation: 0` y el resto igual | **Flat glass, sin labio.** Se borra `_CrystalItemContainer`. |
| `top_navigation_bar_widget.dart` · 170–188 | `OurnegoAlertDialog(actionLabel: 'Cancelar', trailingActions: [TextButton(key: confirmLogoutButton)])` | `primaryAction: OurnegoDialogAction(key: ValueKey('confirmLogoutButton'), label: 'Cerrar sesión', isDestructive: true, onPressed: …)`, `secondaryAction: OurnegoDialogAction(label: 'Cancelar', …)` | — |
| `map/presentation/widgets/map_controls_widget.dart` · 26–33 | `_MapControlButton` ×4 | `OurnegoIconButton(tone: glass, size: s52, radius: 16, …)` con `bug_report_rounded` ('Depuración'), `add_rounded` ('Acercar'), `remove_rounded` ('Alejar') y `my_location_rounded` / `location_disabled_rounded` ('Mi ubicación') | **Con labio:** flotan sobre el mapa, pero son botones de acción. El gap pasa de 12 a `OurnegoSpacingTokens.xs` (8), porque el labio de 4 ya suma el resto. La lógica de "presionado mientras espera el `Future`" se quita; `onPressed` llama al callback sin `await`. Se borra `_MapControlButton`. |
| `map/presentation/widgets/map_canvas_widget.dart` · 224 | `IconButton` créditos | `OurnegoIconButton(tone: glass, size: s40, icon: Icons.info_outline_rounded, semanticLabel: 'Créditos del mapa')` | — |
| `map_canvas_widget.dart` · 265 | `TextButton` 'Cerrar' | `OurnegoButton.text(size: compact, label: 'Cerrar')` | — |
| `map/presentation/widgets/map_search_overlay_widget.dart` · 89 | `FilterChip` 'Abiertos' | `OurnegoChip.filter(label: 'Abiertos', selected: filters.onlyOpenNow, onSelected: onOpenNowChanged)` | El `avatar` del reloj se reemplaza por el check de seleccionado del chip. |
| `map_search_overlay_widget.dart` · `_compactDropdown` ×2 | `DropdownButton` en contenedor de radio 10/12 | `OurnegoChip.dropdown<BusinessType?>(placeholder: 'Categoría', …)` y `OurnegoChip.dropdown<double?>(placeholder: 'Distancia', …)` con las mismas opciones y callbacks | Se borra `_compactDropdown`. |
| `map_search_overlay_widget.dart` · 277 | `TextButton` 'Limpiar' | `OurnegoButton.text(size: small, label: 'Limpiar')` | — |
| `map_search_overlay_widget.dart` · 281 | `IconButton` cerrar | `OurnegoIconButton.ghost(size: s40, icon: Icons.close_rounded, semanticLabel: 'Cerrar búsqueda', tooltip: 'Cerrar búsqueda')` | — |

### 9.5 Floating sheet (`map/presentation/widgets/floating_sheet/ournego_floating_sheet.dart`)

| Línea | Hoy | Nuevo | Notas |
|---|---|---|---|
| 275–325 y 463–510 | `SheetControlButton` ×8, repartidos en dos bloques casi idénticos | Un widget privado `_SheetControls` que usan **ambos**, `_buildComparisonCard` y `_buildFloatingSheet`. Cada control es `OurnegoIconButton(tone: tonal, outlined: true, size: s32, radius: 14, …)`, que conserva el contorno de 1 px que ya tienen hoy | **Compartir:** `Icons.share_rounded`, 'Compartir'.<br>**Favorito:** `OurnegoIconButton.toggle(outlined: true, selected: business.isFavorite, icon: Icons.favorite_border_rounded, selectedIcon: Icons.favorite_rounded, celebrate: true, semanticLabel: 'Favorito', onChanged: _isFavoriteUpdating ? null : …)`. Mientras actualiza queda apagado en lugar de usar el `() {}` de hoy.<br>**Minimizar:** `Icons.picture_in_picture_alt_rounded`, 'Minimizar'.<br>**Expandir:** `isExpanded ? Icons.keyboard_arrow_down_rounded : Icons.open_in_full_rounded`, 'Contraer' / 'Expandir'.<br>**Cerrar** (comparación): `Icons.close_rounded`, 'Cerrar'. |
| 685–730 | `_LegacyCollapsedActions` con `_LegacyActionButton` ×3 | `_CollapsedActions` con un `Row` de 3 `Expanded(OurnegoActionButton)` y gap `OurnegoSpacingTokens.xs` | Iconos `sentiment_satisfied_rounded` ('Reseñas'), `search_rounded` ('Catálogo') y `chat_rounded` ('Mensaje'). Se borra el `SizedBox(width: 8)` inicial suelto. |
| 882 | `_LegacyWideButton` 'Opinión General' | `OurnegoRowButton(icon: Icons.sentiment_satisfied_rounded, label: 'Opinión general', onPressed: onReviews)` | — |
| 980 / 986 | `_CompactAction` 'Mensaje' / 'Llamar' | `OurnegoButton.secondary(size: compact, radius: 14, label: 'Mensaje', icon: Icons.chat_rounded, iconMotion: wiggle)` y lo mismo con 'Llamar' + `Icons.call_rounded` | Siguen llamando a `onContact` las dos, como hoy. No cambiar comportamiento. |
| 1038 | `TextButton.icon` 'Ver catálogo' | `OurnegoButton.text(size: compact, label: 'Ver catálogo', icon: Icons.inventory_2_rounded, iconMotion: wiggle)` | — |
| — | `_brandedSheetButtonStyle`, `_LegacyActionButton`, `_LegacyWideButton`, `_CompactAction` | **Eliminar** | `_brandedSheetCardDecoration` y `_SheetAccentIcon` se quedan (son tarjetas). Renombrar `_LegacyExpandedContent` → `_ExpandedContent`. |

Archivos a eliminar en `floating_sheet/components/`: `sheet_control_button.dart`, `action_tile.dart` y `bento_action_grid.dart` (código muerto). `OurnegoActionTile` los sustituye en shared y por ahora solo se usa en la galería (§12).

### 9.6 Navegación

| Archivo | Cambio |
|---|---|
| `navigation/presentation/widgets/navigation_bar_widget.dart` | §6.10: `AppNavigationBar` pasa a ser un envoltorio de `OurnegoNavBar`, que es flat glass sin labio y tiene indicador deslizante, contorno 1 px, la sombra de hoy y alto 72. Las etiquetas semánticas salen del datasource. Se borra `_CrystalNavItem`. Se conservan `appNavigationBarKey` y la firma pública `AppNavigationBar(currentIndex:, onTap:)`. |

### 9.7 Core

| Archivo · línea | Hoy | Nuevo |
|---|---|---|
| `core/routing/app_router.dart` · 327 | `ElevatedButton` 'Go to Home' | `OurnegoButton.primary(label: 'Ir al mapa', onPressed: …)` |
| `core/startup/startup_gate.dart` · 368 / 372 | `TextButton` 'Cerrar' / 'Contactar soporte' | `OurnegoButton.text(size: compact, label: 'Cerrar')` / `OurnegoButton.primary(size: compact, label: 'Contactar soporte')` |
| `startup_gate.dart` · 446 | `FilledButton.icon` 'Reintentar' (ya forzaba `foregroundColor: noche`) | `OurnegoButton.primary(label: 'Reintentar', icon: Icons.refresh_rounded, iconMotion: wiggle)` |
| `startup_gate.dart` · 454 | `OutlinedButton.icon` 'Ver ayuda' | `OurnegoButton.secondary(label: 'Ver ayuda', icon: Icons.help_outline_rounded)` |
| `shared/widgets/ournego_alert_dialog.dart` · 38 | `TextButton` interno + API invertida | §6.11 |
| `core/debugging/presentation/pages/debug_panel_screen.dart` | — | Agregar un `ListTile` "Galería de botones" que abra `ButtonGalleryScreen` (§12) con `Navigator.push` (no hace falta ruta nueva). |

### 9.8 Lo que NO se migra (recordatorio)

Todo lo de §1.4. En particular:

- **Quedan como `InkWell` o `GestureDetector`:** `_RoleOptionCard`, `BusinessPanelMetricTile`, `BusinessPanelLockedCenterCard`, `BusinessPanelQuickActions`, `MinimizedStackIcon`, los dos links de login y los selectores de hora. La prueba de §11.3 no los bloquea, porque solo busca widgets de botón de Material.
- **Quedan como `ListTile`:** los del menú de perfil y del diálogo de feedback.

### 9.9 Correcciones de texto permitidas

| Dónde | Antes | Después |
|---|---|---|
| `app_router.dart` 404 | 'Go to Home' | 'Ir al mapa' |
| `business_form_screen.dart` | 'Registrar Negocio' | 'Registrar negocio' |
| `ournego_floating_sheet.dart` | 'Opinión General' | 'Opinión general' |
| `business_form_screen.dart` diálogo de error | acción 'OK' (default) | 'Entendido' |

Ninguna otra cadena cambia, salvo las etiquetas semánticas nuevas, que antes no existían.

---

## 10. Eliminaciones (deuda que se cierra)

Al final de la migración NO deben existir:

- `lib/shared/widgets/ournego_buttons.dart` (con `OurnegoPrimaryButton`, `OurnegoNeutralPrimaryButton` y el `OurnegoButtonStyles` de shared).
- La clase `OurnegoButtonStyles` en core (queda renombrada a `OurnegoButtonThemes`).
- `features/business/presentation/widgets/business_panel/business_panel_icon_button.dart`.
- `features/map/presentation/widgets/zone_chip_widget.dart`.
- `features/map/presentation/widgets/floating_sheet/components/sheet_control_button.dart`, `action_tile.dart` y `bento_action_grid.dart`.
- Las clases privadas `_MapControlButton`, `_CrystalNavItem`, `_CrystalItemContainer`, `_LegacyActionButton`, `_LegacyWideButton` y `_CompactAction`, y las funciones `_brandedSheetButtonStyle` y `_compactDropdown`.
- Cualquier `CircularProgressIndicator` **dentro** de un botón.

Documentación a actualizar en el mismo PR:

- **`docs/development/design/components.md`:** reemplazar la sección de botones por un resumen de §6 con enlace a este spec. Hoy además documenta `OurnegoOnboardingPrimaryButton`, que ya no existe.
- **`docs/development/ui-refactor/README.md`:** reemplazar la lista de `OurnegoButtonStyles.*` por la familia nueva, y quitar la regla "use `OurnegoButtonStyles` variants".
- **`docs/development/design/DESIGN_SYSTEM.md`:** en §9 y §19, marcar como resueltos los puntos de botones, las dos `OurnegoButtonStyles` y el contraste de `onPrimary`.
- **Este spec:** copiarlo a `docs/development/design/BUTTONS_SPEC.md`.

---

## 11. Pruebas

### 11.1 Línea base

Antes de tocar nada, correr y guardar el resultado:

```bash
flutter analyze
flutter test
```

Si algo ya falla en la línea base, anotarlo en el PR y no arreglarlo salvo que lo rompa esta migración.

### 11.2 Pruebas nuevas (en `test/shared/widgets/buttons/`)

| Archivo | Qué debe probar |
|---|---|
| `ournego_button_tokens_test.dart` | Para cada tono y brillo, el contraste tinta/cara es ≥ 4.5 (calcular la luminancia WCAG en la prueba). `primary` usa tinta `0xFF161616` en ambos temas. `outlineLip` vale `0xFFB3B3B3` en claro y `0xFF3E4745` en oscuro con `OurnegoTheme.light` y `.dark` (comparar con tolerancia de ±1 por canal, porque la mezcla usa flotantes). `borderSubtle` del tema claro es `0x4D000000`: si falla, alguien definió `outline` en el tema. Apagado aplica a todos los tonos. Los tamaños de §3.3, §3.4 y §3.5 coinciden. |
| `ournego_pressable_test.dart` | Tap llama `onPressed` una vez. `onPressed: null` no llama nada y expone `Semantics(enabled: false)`. Al `press` (gesture down) la cara baja `lipDepth` (leer el `Transform` o el `Positioned` de la cara). Al soltar vuelve a 0 tras `pump(kBoingDuration)`. El alto total es cara + labio. Enter y Espacio activan con foco. Con `MediaQuery(disableAnimations: true)` no corre el boing (el controller no está animando tras el `tapUp`). El área táctil mínima es de 48 en `s28` (tocar a 10 px fuera de la cara visible y comprobar que llama). |
| `ournego_glass_pressable_test.dart` | **No hay labio:** el alto total es igual al alto de la cara. Al presionar, la escala llega a 0.96. Al soltar, muestrear cada 16 ms durante `kGlassReleaseDuration` y verificar que la escala **nunca** pasa de 1.0, o sea sin sobrepaso. El contorno mide 1 px y usa `borderSubtle` en reposo. Hay un `BackdropFilter` en el árbol. Con `active` + `showHalo`, el halo existe; con reduced motion no anima. |
| `ournego_button_test.dart` | Muestra el texto. `status: loading` muestra `NegoEyesLoader`, mantiene el ancho (comparar `tester.getSize` antes y después) y no llama `onPressed`. `status: success` muestra '¡Listo!'. `showNego: true` renderiza un `NegoAvatar` con `floating: false`. `assert` si `showNego` va con un tono distinto de primary. `expanded` ocupa todo el ancho. La `key` pasada es encontrable con `find.byKey`. **Importante:** en pruebas con loader o halo usar `pump(Duration)`, no `pumpAndSettle()`. |
| `ournego_icon_button_test.dart` | `semanticLabel` llega a `Semantics`. El toggle invierte `selected` vía `onChanged` y expone `toggled`. `radius: 16` aplica radio 16. `outlined: true` con `tonal` dibuja contorno de 1 px y labio `outlineLip`. |
| `ournego_glass_widgets_test.dart` | `OurnegoGlassIconButton(active: true)` usa `accentInk` en contorno e icono y cambia a `activeIcon`. `OurnegoGlassSurface` cambia el contorno a `glassActive` cuando su `TextField` hijo recibe foco. `OurnegoGlassChip` muestra etiqueta y acción, y llama `onPressed`. Ninguno de los tres tiene labio. |
| `ournego_social_button_test.dart` | El texto queda centrado con y sin badge (el centro del `Text` coincide con el centro del botón ±1 px). `.google` usa el asset `assets/images/google.png`. |
| `ournego_chip_test.dart` | `.filter` alterna. `.dropdown` abre el menú, elige una opción y llama `onChanged`; la opción nula muestra el `placeholder`. |
| `ournego_nav_bar_test.dart` | Con `currentIndex: 1`, el indicador queda centrado en el segundo ítem (±1 px). Al cambiar a 2, el indicador se desliza: muestrear durante `kNavIndicatorDuration` y verificar que la posición se mueve de forma monótona y **no** se pasa del destino. El ítem activo tiene tinta noche. `Semantics(selected:)`. Alto total 72. Con reduced motion, el indicador salta en un solo frame. |
| `ournego_alert_dialog_test.dart` (en `test/shared/widgets/`) | Renderiza primaria y secundaria. `isDestructive` usa tono destructive. Las keys de cada acción son encontrables. |
| `nego_avatar_test.dart` (ampliar) | §8.5 y `floating: false`, que no deja animaciones pendientes: `pumpAndSettle` termina. |

Para todas las pruebas de widgets, envolver con `MaterialApp(theme: OurnegoTheme.light)`. Repetir con `OurnegoTheme.dark` las que verifican colores.

### 11.3 Prueba de arquitectura (`test/architecture/no_raw_material_buttons_test.dart`)

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final dartFiles = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  String norm(File f) => f.path.replaceAll('\\', '/');

  test('no raw Material buttons in lib/', () {
    final forbidden = RegExp(
      r'\b(ElevatedButton|FilledButton|OutlinedButton|TextButton|IconButton|'
      r'FilterChip|ChoiceChip|ActionChip|InputChip|FloatingActionButton)'
      r'(\.\w+)?\s*\(',
    );
    final offenders = <String>[];
    for (final file in dartFiles) {
      final path = norm(file);
      // Theme files only build ButtonStyle/ThemeData safety nets.
      if (path.startsWith('lib/core/theme/')) continue;
      final lines = file.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (forbidden.hasMatch(line)) offenders.add('$path:${i + 1}: $line');
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('legacy button widgets are gone', () {
    const legacy = [
      'OurnegoPrimaryButton', 'OurnegoNeutralPrimaryButton', 'OurnegoButtonStyles',
      'SheetControlButton', 'BusinessPanelIconButton', '_MapControlButton',
      '_CrystalNavItem', '_CrystalItemContainer', '_LegacyActionButton',
      '_LegacyWideButton', '_CompactAction', '_brandedSheetButtonStyle',
      '_compactDropdown', 'circularSurface', 'authOutlinedOnSurface',
      'authFilledOnSurface', 'tonalCardButton', 'BentoActionGrid',
    ];
    final offenders = <String>[];
    for (final file in dartFiles) {
      final content = file.readAsStringSync();
      for (final name in legacy) {
        if (RegExp('\\b$name\\b').hasMatch(content)) {
          offenders.add('${norm(file)}: $name');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });
}
```

Notas sobre la prueba:

- La regex no choca con `OurnegoIconButton` (no hay límite de palabra antes de `IconButton`), ni con `MenuItemButton`, ni con `ElevatedButtonThemeData`.
- `ActionTile` no se bloquea por nombre porque `OurnegoActionTile` contiene esa palabra; el archivo viejo se borra igual.

### 11.4 Keys que DEBEN sobrevivir

13 de estas keys las usan `test/` e `integration_test/`. Las otras tres (`onboardingBackButton`, `account-check-continue` y `profile-load-retry`) hoy no las usa ninguna prueba, pero se conservan igual. Después de migrar, cada una debe seguir en un widget tocable con el mismo comportamiento:

`loginSubmitButton`, `guestAccessButton`, `emailAccessButton`, `onboardingExploreContinueButton`, `onboardingDiscoverContinueButton`, `onboardingBackButton`, `activateLocationButton`, `mapProfileButton`, `confirmLogoutButton`, `account-check-retry`, `account-check-continue`, `profile-load-retry`, `location-access-primary`, `location-access-secondary`, `map-location-banner-action`, `zone-chip`.

Las `profileMenu*` y `zone-picker-*` no cambian porque no son botones migrados.

### 11.5 Comandos de cierre

```bash
dart format lib test
flutter analyze            # 0 issues nuevos respecto a la línea base
flutter test               # todo verde, incluidas las nuevas y la de arquitectura
```

Si hay un dispositivo o emulador disponible, correr también `flutter test integration_test`. Si no, anotarlo en el PR.

---

## 12. Galería de QA (`ButtonGalleryScreen`)

Pantalla nueva en `lib/core/debugging/presentation/pages/button_gallery_screen.dart`. Solo en `kDebugMode`, abierta desde el panel de depuración. Replica el playground para revisar a ojo en el dispositivo.

- **Cabecera:**
  - Tres `OurnegoChip.filter` para Sistema / Claro / Oscuro, que fuerzan un `Theme` local sobre la galería. No usar `SegmentedButton`.
  - Un `Switch` de Material para "Simular reduced motion", que envuelve la galería en `MediaQuery(disableAnimations:)`. `Switch` no es botón y está permitido.
- **Secciones, en este orden y con el mismo contenido que el playground:**
  1. **Acción principal:**
     - Primario con Nego y un control de estado (Normal / Presionado / Apagado / Cargando / Listo).
     - Un primario que al tocarse corre el flujo cargando 1300 ms → listo 1300 ms → normal.
     - Neutro grande.
     - Compactos: 'Guardar', 'Reintentar', y 'Permitir' dentro de un banner.
  2. **Secundarios:** secondary (con contorno), text, destructive dentro de un mini diálogo, y tonal. Cada uno con su tira Normal / Presionado / Apagado.
  3. **Acceso:** tres sociales con contorno, uno de ellos apagado con badge 'Pronto', y Google.
  4. **Botones de icono:**
     - Controles de mapa (radio 16, con labio).
     - Controles de sheet (tonal con contorno, radio 14) con favorito celebrando.
     - Iconos del panel (44 y 28).
     - Regresar.
  5. **Flat glass:**
     - La barra superior completa: micrófono que alterna escuchando, buscador enfocable y perfil.
     - El chip de zona.
     - La navbar con el indicador deslizante.
     - Todo sobre un fondo de mapa de prueba (un `Container` con un degradado suave), para ver el blur.
  6. **Floating sheet:** acciones de icono, fila, acción con texto y tiles (Favorito como toggle con celebración).
  7. **Chips:** filtro y los dos desplegables.
- Para la variante "Presionado" de las tiras, `OurnegoPressable` y los componentes que lo envuelven aceptan `bool forcePressed = false`, documentado como "solo para la galería de QA". No usar `@visibleForTesting`, porque la galería vive en `lib/` y el analizador lo marcaría.

---

## 13. Criterios de aceptación

- [ ] No queda ningún botón de Material crudo en `lib/` (pasa la prueba de §11.3).
- [ ] Todos los elementos de §9 usan componentes de `lib/shared/widgets/buttons/` con el tono, tamaño, radio e icono indicados.
- [ ] **Labio solo en botones de acción.** Los controles del mapa sí lo llevan. Voz, buscador, perfil, chip de zona y navbar **no**.
- [ ] Los elementos flat glass se animan sin rebote ni sobrepaso: escala 0.96 al presionar, cambio de contorno en hover, halo del micrófono e indicador deslizante en la navbar.
- [ ] Todo lo que hoy tiene contorno lo conserva con 1 px de `borderSubtle`, visible en claro (negro al 30%). El tema no define `outline`.
- [ ] El texto sobre aqua es noche en ambos temas, incluido el icono activo de la navbar.
- [ ] Cada botón con labio muestra el labio en reposo, baja al presionar, sube 1 px en hover (web/escritorio) y rebota al soltar.
- [ ] Con reduced motion no hay rebote, pop ni ráfaga; el halo queda fijo; el indicador de la navbar salta, y el loader pulsa en opacidad.
- [ ] Los cinco CTA con `showNego` (login, registro, completar perfil, "Comenzar" de registro de negocio y "Registrar negocio") muestran a Nego, que reacciona a hover, press, apagado y éxito.
- [ ] "Registrar negocio" y "Enviar correo" muestran los ojos de Nego mientras cargan, sin cambiar de ancho.
- [ ] Favorito en el floating sheet hace pop y ráfaga al marcarse, y queda apagado mientras se actualiza.
- [ ] `BackdropFilter` solo aparece en `ournego_glass_pressable.dart` y `ournego_glass_surface.dart`. Comprobar con `grep -rn "BackdropFilter" lib/shared/widgets/buttons`.
- [ ] `OurnegoSpacingTokens.navHeight` sigue en 72.
- [ ] Todos los botones de solo icono tienen `semanticLabel`.
- [ ] Todas las keys de §11.4 siguen funcionando.
- [ ] `flutter analyze` sin issues nuevos y `flutter test` en verde.
- [ ] La galería de QA se ve como el playground en claro y oscuro.
- [ ] Docs actualizados (§10).

---

## 14. Orden de commits sugerido

Usar el estilo del repo (Conventional Commits en inglés, mensajes cortos) y una rama propia, por ejemplo `feat/ournego-buttons`.

1. `feat(theme): button tokens, motion constants and noche on primary`: §3, §7 (sin borrar nada todavía).
2. `feat(nego): eyesClosed, happyTrigger and floating options`: §8 + pruebas.
3. `feat(buttons): OurnegoPressable and lip button family`: §5.1–§5.6, §6.1–§6.9, §6.11 + pruebas.
4. `feat(buttons): flat glass pressable, glass widgets and nav bar`: §5.7, §6.10, §6.12 + pruebas.
5. `feat(debug): button gallery`: §12.
6. `refactor(auth): migrate buttons to Ournego family`: §9.1.
7. `refactor(onboarding): migrate buttons`: §9.2.
8. `refactor(business): migrate buttons`: §9.3.
9. `refactor(map): migrate map controls, glass top bar, chips and floating sheet`: §9.4 y §9.5.
10. `refactor(navigation): flat glass nav bar with sliding indicator`: §9.6.
11. `refactor(core): migrate startup, router and alert dialog actions`: §9.7 y §6.11.
12. `chore(buttons): remove legacy button widgets and add architecture guard`: §10 + §11.3.
13. `docs(design): buttons spec and component docs`: §10.

Correr `flutter analyze` y `flutter test` al final de cada commit. Si un commit intermedio no compila por dependencias cruzadas, juntar los pasos 6–11 en uno solo.

---

## 15. Qué NO hacer

- NO usar `BoxShadow` con blur, `InkWell`, `InkResponse`, `Material(elevation:)` ni splash en los botones de marca. La única sombra difusa permitida es la que ya tiene la navbar.
- NO poner labio en voz, buscador, perfil, chip de zona ni navbar.
- NO usar `kOurnegoSpring`, rebote, pop ni ráfaga en los elementos flat glass.
- NO agregar `BackdropFilter` fuera de `OurnegoGlassPressable` y `OurnegoGlassSurface`. NO ponerle blur a la navbar ni a ningún botón con labio.
- NO definir `outline` en `ColorScheme.light`, NO quitar contornos que existen hoy y NO bajar su opacidad.
- NO cambiar `navHeight`.
- NO crear tonos, tamaños, curvas ni duraciones que no estén en §3.
- NO pasar `TextStyle` ni `Color` desde una feature a un botón. Las features eligen `tone`, `size` e `icon`.
- NO cambiar la navegación, los providers, los usecases ni el comportamiento de ningún `onPressed`, salvo:
  - el teléfono apagado (§9.1);
  - favorito apagado mientras actualiza (§9.5);
  - el control del mapa que ya no espera el `Future` (§9.4).
- NO tocar lo de §1.4.
- NO usar `pumpAndSettle()` en pruebas donde haya un loader, el halo o un Nego con `floating: true` visible.
- NO bundlear fuentes ni agregar dependencias. Todo se hace con Flutter puro (`MenuAnchor`, `OverlayPortal` y `CompositedTransform*` ya vienen en el SDK).

---

## Apéndice A · Esqueleto de `ournego_button_tokens.dart`

```dart
import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';

enum OurnegoButtonTone {
  primary, neutral, secondary, tonal, success, destructive, glass, white, ghost,
}

@immutable
class OurnegoButtonColors {
  const OurnegoButtonColors({
    required this.face,
    required this.lip,
    required this.ink,
    this.border = const Color(0x00000000),
  });

  final Color face;
  final Color lip;
  final Color ink;
  final Color border;

  static OurnegoButtonColors lerp(OurnegoButtonColors a, OurnegoButtonColors b, double t) {
    return OurnegoButtonColors(
      face: Color.lerp(a.face, b.face, t)!,
      lip: Color.lerp(a.lip, b.lip, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      border: Color.lerp(a.border, b.border, t)!,
    );
  }
}

class OurnegoButtonPalette {
  OurnegoButtonPalette._();

  static Color borderSubtle(ColorScheme s) => OurnegoSemanticTokens.borderSubtle(s);

  /// Contour composited over the page background: 0xFFB3B3B3 light, 0xFF3E4745 dark.
  static Color outlineLip(ColorScheme s) => Color.alphaBlend(
        borderSubtle(s),
        s.brightness == Brightness.dark
            ? OurnegoColorTokens.surfaceDark
            : OurnegoColorTokens.blanco,
      );

  static OurnegoButtonColors of(OurnegoButtonTone tone, ColorScheme s, {bool? outlined}) {
    final dark = s.brightness == Brightness.dark;
    final border = borderSubtle(s);
    final lipOutline = outlineLip(s);

    OurnegoButtonColors base;
    switch (tone) {
      case OurnegoButtonTone.primary:
        base = OurnegoButtonColors(
          face: OurnegoColorTokens.azulCielo,
          lip: dark ? const Color(0xFF0A86A6) : OurnegoColorTokens.azulVerde,
          ink: OurnegoColorTokens.noche,
        );
      case OurnegoButtonTone.neutral:
        base = dark
            ? const OurnegoButtonColors(face: OurnegoColorTokens.blanco, lip: Color(0xFFAEBDB8), ink: OurnegoColorTokens.noche)
            : const OurnegoButtonColors(face: OurnegoColorTokens.noche, lip: Color(0xFF000000), ink: OurnegoColorTokens.blanco);
      case OurnegoButtonTone.secondary:
        base = OurnegoButtonColors(
          face: dark ? OurnegoColorTokens.surfaceDark : OurnegoColorTokens.blanco,
          lip: lipOutline,
          ink: s.onSurface,
          border: border,
        );
      case OurnegoButtonTone.tonal:
        base = dark
            ? const OurnegoButtonColors(face: OurnegoColorTokens.verdeBrunswick, lip: Color(0xFF012A1F), ink: OurnegoColorTokens.cianClaro)
            : const OurnegoButtonColors(face: OurnegoColorTokens.cianClaro, lip: Color(0xFFA4E4F2), ink: OurnegoColorTokens.verdeCastleton);
      case OurnegoButtonTone.success:
        base = dark
            ? const OurnegoButtonColors(face: OurnegoColorTokens.mentaOscuro, lip: Color(0xFF25845C), ink: OurnegoColorTokens.noche)
            : const OurnegoButtonColors(face: OurnegoColorTokens.aguamarina, lip: OurnegoColorTokens.mentaOscuro, ink: OurnegoColorTokens.verdeCastleton);
      case OurnegoButtonTone.destructive:
        base = OurnegoButtonColors(
          face: OurnegoColorTokens.error,
          lip: dark ? const Color(0xFF5C0909) : const Color(0xFF7A0F0F),
          ink: OurnegoColorTokens.blanco,
        );
      case OurnegoButtonTone.glass:
        base = OurnegoButtonColors(
          face: dark ? OurnegoColorTokens.surfaceDark : OurnegoColorTokens.blanco,
          lip: lipOutline,
          ink: s.onSurface,
          border: border,
        );
      case OurnegoButtonTone.white:
        base = const OurnegoButtonColors(
          face: OurnegoColorTokens.blanco,
          lip: Color(0xFFB3B3B3),
          ink: OurnegoColorTokens.noche,
          border: Color(0x4D000000),
        );
      case OurnegoButtonTone.ghost:
        base = OurnegoButtonColors(face: const Color(0x00000000), lip: const Color(0x00000000), ink: s.onSurface);
    }

    if (outlined == true) {
      base = OurnegoButtonColors(face: base.face, lip: lipOutline, ink: base.ink, border: border);
    }
    return base;
  }

  static OurnegoButtonColors disabled(ColorScheme s, {bool ghost = false}) {
    final dark = s.brightness == Brightness.dark;
    return OurnegoButtonColors(
      face: ghost ? const Color(0x00000000) : (dark ? const Color(0x14E1E3E1) : const Color(0x12161616)),
      lip: ghost ? const Color(0x00000000) : (dark ? const Color(0x0DE1E3E1) : const Color(0x17161616)),
      ink: dark ? const Color(0x61E1E3E1) : const Color(0x61161616),
    );
  }

  static Color ghostOverlay(ColorScheme s) =>
      s.brightness == Brightness.dark ? const Color(0x14E1E3E1) : const Color(0x12055F46);
  static Color focusRing(ColorScheme s) =>
      s.brightness == Brightness.dark ? OurnegoColorTokens.azulCielo : OurnegoColorTokens.azulVerde;
  static Color accentInk(ColorScheme s) =>
      s.brightness == Brightness.dark ? OurnegoColorTokens.azulCielo : OurnegoColorTokens.azulVerde;
}

class OurnegoGlassPalette {
  OurnegoGlassPalette._();

  static Color face(ColorScheme s) => s.surface.withValues(alpha: 0.88);   // 0xE0F4FBF9 / 0xE01E2625
  static Color navFace(ColorScheme s) => s.surface;                        // opaca
  static Color border(ColorScheme s) => OurnegoSemanticTokens.borderSubtle(s);
  static Color borderHover(ColorScheme s) => s.brightness == Brightness.dark
      ? s.outline.withValues(alpha: 0.6)
      : s.outline.withValues(alpha: 0.5);
  static Color active(ColorScheme s) => OurnegoButtonPalette.accentInk(s);
  static Color focusGlow(ColorScheme s) => OurnegoColorTokens.azulCielo
      .withValues(alpha: s.brightness == Brightness.dark ? 0.30 : 0.28);
  static const Color halo = OurnegoColorTokens.azulCielo;
  static const double blurSigma = 10;
}
```

Los literales que quedan (`0xFF0A86A6`, `0xFFAEBDB8`, `0xFF000000`, `0xFF012A1F`, `0xFFA4E4F2`, `0xFF25845C`, `0xFF5C0909`, `0xFF7A0F0F`, los de apagado y overlay, y los fijos de `white`) son labios y estados nuevos que solo existen en este archivo. Todo lo demás DEBE salir de `OurnegoColorTokens`, `OurnegoSemanticTokens` o el `ColorScheme`.
