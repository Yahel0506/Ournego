# Ournego Design System Components

## Buttons (`lib/shared/widgets/ournego_buttons.dart`)

### `OurnegoPrimaryButton`
Botón principal que se adapta al tema. Usa el color primario y cambia a `azulVerde` cuando es presionado.

**Props:**
- `onPressed` (VoidCallback?): Acción a ejecutar al presionar el botón.
- `child` (Widget): Contenido del botón (normalmente un Text).
- `buttonKey` (Key?): Llave para pruebas o referencias.
- `minimumSize` (Size): Tamaño mínimo del botón (default: `Size(double.infinity, 50)`).

### `OurnegoOnboardingPrimaryButton`
Variante del botón principal específicamente usada para el flujo de onboarding, con un radio de borde diferente y una sombra ligera.

**Props:**
- `onPressed` (VoidCallback?): Acción a ejecutar al presionar.
- `child` (Widget): Contenido del botón.
- `minimumSize` (Size): Tamaño mínimo (default: `Size(double.infinity, 56)`).
- `radius` (double): Radio de los bordes (default: `24`).
- `elevation` (double): Elevación del botón (default: `6`).

### `OurnegoButtonStyles` (Utility methods para variantes)
- `authOutlinedOnSurface`: Botón contorneado usado en pantallas de autenticación.
- `authFilledOnSurface`: Botón rellenado usado en pantallas de autenticación.
- `circularSurface`: Botón circular para acciones rápidas (default size: `Size(52, 52)`).
- `tonalCardButton`: Botón usado dentro de tarjetas con fondo tonal claro.

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
- **Button Themes**: Definidos en `OurnegoButtonStyles` (Elevated y Outlined).
- **Input Decoration**: Definidos en `OurnegoInputStyles` con radios de `OurnegoRadiusTokens.xl`.
