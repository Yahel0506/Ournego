# Ournego Design System Components

## Buttons (`lib/shared/widgets/buttons/`)

Spec normativo: [`BUTTONS_SPEC.md`](BUTTONS_SPEC.md). Las features importan solo `package:ournego/shared/widgets/buttons/buttons.dart` y eligen `tone`, `size` e `icon`; nunca pasan `Color` ni `TextStyle`. Una prueba de arquitectura (`test/architecture/no_raw_material_buttons_test.dart`) impide volver a usar botones crudos de Material en `lib/`.

### Botones de acción (con labio, sobre `OurnegoPressable`)

Labio plano (bloque sólido bajo la cara, sin blur), rebote al soltar, estados hover / pressed / focus / disabled / loading / success. Curvas con rebote (`kOurnegoSpring`) exclusivas de esta línea.

- `OurnegoButton` (`.primary`, `.neutral`, `.secondary`, `.tonal`, `.destructive`, `.text`): `label`, `onPressed`, `size` (`large`/`regular`/`compact`/`small`), `icon`, `trailingIcon`, `iconMotion`, `expanded`, `minWidth`, `status` (`idle`/`loading`/`success`), `showNego` (solo `primary`, no `small`).
- `OurnegoIconButton` (`.ghost`, `.toggle`): `icon`, `semanticLabel` (obligatorio), `size` (`s52` … `s28`), `radius`, `outlined`, `child`.
- `OurnegoSocialButton` (`.google`): botones de acceso con tres ranuras y badge opcional.
- `OurnegoRowButton`, `OurnegoActionButton`, `OurnegoActionTile`: acciones del floating sheet.
- `OurnegoChip.filter` / `OurnegoChip<T>.dropdown`: chips del panel de búsqueda.
- `NegoEyesLoader` y `OurnegoBurst`: loader de ojos y ráfaga de puntos.

### Flat glass (sin labio, sobre `OurnegoGlassPressable`)

Para lo que flota sobre el mapa y la navegación: contorno de 1 px (`borderSubtle`), superficie de vidrio y animaciones calmadas sin rebote (`kCalmCurve`, `kEaseOutExpo`).

- `OurnegoGlassIconButton`: micrófono (con halo mientras escucha) y perfil.
- `OurnegoGlassSurface`: contenedor no presionable del buscador.
- `OurnegoGlassChip`: chip de zona.
- `OurnegoNavBar`: barra de navegación opaca con indicador deslizante (alto `navHeight = 72`).

### Diálogos

`OurnegoAlertDialog` recibe `primaryAction` y `secondaryAction` (`OurnegoDialogAction`, con `key` e `isDestructive`).

### Galería de QA

`ButtonGalleryScreen` (`lib/core/debugging/presentation/pages/button_gallery_screen.dart`), accesible desde el panel de depuración.

## Inputs (`lib/shared/widgets/ournego_inputs.dart`)

### `OurnegoInputField`
Campo de texto base con estilos consistentes para toda la app (bordes redondeados XL).

**Props:**
- `controller` (TextEditingController?): Controlador del campo.
- `validator` (FormFieldValidator<String>?): Función de validación.
- `onChanged` (ValueChanged<String>?): Callback al cambiar texto.
- `focusNode` (FocusNode?): Nodo de enfoque.
- `autofillHints` (Iterable<String>?): Sugerencias de autocompletado.
- `keyboardType` (TextInputType?): Tipo de teclado.
- `maxLines` (int?): Líneas máximas.
- `hintText` (String?): Texto sugerido.
- `labelText` (String?): Texto de etiqueta.
- `hint` (Widget?): Widget para pista alternativa.
- `hintStyle` (TextStyle?): Estilo de texto de la pista.
- `icon` (Widget?): Ícono de prefijo.
- `suffixIcon` (Widget?): Ícono de sufijo.
- `obscureText` (bool): Ocultar texto (para contraseñas, default: `false`).

### `OurnegoLabeledInputSection`
Sección que agrupa una etiqueta (`Text`) con su respectivo campo de entrada (`Widget`).

**Props:**
- `label` (String): Texto a mostrar arriba del input.
- `input` (Widget): El campo de texto o widget interactivo.
- `spacing` (double): Espacio entre la etiqueta y el input (default: `10`).

## Themes & Decorations (`lib/core/theme/`)

- **ThemeData**: Definidos en `OurnegoTheme` (`light` y `dark`). Proveen toda la paleta de Material 3 basada en los tokens de colores.
- **Button Themes**: `OurnegoButtonThemes` (Elevated y Outlined) queda solo como red de seguridad para widgets internos de Flutter; la app usa `lib/shared/widgets/buttons/`.
- **Input Decoration**: Definidos en `OurnegoInputStyles` con radios de `OurnegoRadiusTokens.xl`.
