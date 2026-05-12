# Nego (Flutter)

Implementación procedural y nativa en Flutter del avatar **Nego**, basada en primitivas vectoriales (círculo + borde + glow + ojos) y recortes expresivos. El objetivo es replicar fielmente el comportamiento y la estética del componente de referencia (React/JSX) sin agregar rasgos extra (no boca, no cejas, no highlights, no gradientes internos en ojos).

## Objetivo

- Mantener una identidad visual **minimalista, plana y geométrica**.
- Expresar estado principalmente con: **forma/tamaño de ojos**, **posición del grupo ocular**, **recortes (cutouts)** y **transformaciones** (rotación/escala/traslación).
- Proveer una API simple para uso en UI (ej. onboarding) con modo `interactive` opcional.

## API Pública

El widget público es `NegoAvatar`:

```dart
NegoAvatar(
  size: 256,
  mood: NegoMood.idle,
  lookAngle: -18,
  lookVertical: NegoLookVertical.down,
  interactive: true,
  onTap: null,
)
```

Parámetros:

- `size`: tamaño total del avatar (escala proporcional de todos los elementos).
- `mood`: estado persistente (ver sección de moods).
- `lookAngle` y `lookVertical`: solo afectan en `NegoMood.looking`.
- `interactive`:
  - `true`: habilita pointer tracking (ojos + rotación corporal) y `happy` temporal por tap/click.
  - `false`: render decorativo; no se comporta como botón.
- `onTap`: callback opcional ejecutado tras el feedback visual de `happy`.

## Estados (Moods)

Estados persistentes (externos, mutuamente excluyentes):

- `NegoMood.idle`
- `NegoMood.excited`
- `NegoMood.winking`
- `NegoMood.looking`

Estado temporal interno:

- `NegoMood.happy` (no debe ser el mood persistente principal; se activa por interacción y se limpia automáticamente).

Regla de prioridad:

- `activeMood = temporaryMood ?? mood`

## Reglas Importantes (Fidelidad)

1. **Blink aditivo**: el parpadeo no hace morph de path; comprime el ojo con `scaleY` alrededor del centro.
2. **Blink no detiene el idle**: el idle float sigue ocurriendo durante blink.
3. **Winking desactiva blink**: cuando `activeMood == winking`, blink se cancela y se fuerza `scaleY = 1`.
4. **Looking**:
   - No aplica desplazamiento horizontal del grupo ocular.
   - Aplica rotación por `lookAngle` y offset vertical por `lookVertical`.
5. **Winking cutout**:
   - Recorte triangular del color del rostro.
   - Debe ser `fill` (no `stroke`) para no redondear vertices no deseados.
6. **Excited cutout**:
   - Recorte inferior curvo del color del rostro.
   - Incluye stroke del color del rostro para suavizar extremos (join/cap redondeados).
7. No se agregan: boca, cejas, highlights, texturas, sombras internas ni gradientes en ojos.

## Arquitectura Interna

Archivos (composición):

- `nego_avatar.dart` (`NegoAvatar`): widget público. Maneja interacción (tap/pointer/focus), `TickerMode`, `dispose` y render con `CustomPaint`.
- `nego_painter.dart` (`NegoPainter`): render de:
  - glow externo
  - círculo del rostro + stroke
  - pulso de `happy`
  - ojos (paths) + recortes expresivos
- `nego_motion_controller.dart` (`NegoMotionController`): orquestación de:
  - idle float (loop)
  - blink aleatorio (timers + `scaleY`)
  - happy temporal (timer + pulso)
  - pointer tracking (spring smoothing)
  - transición entre geometrías de mood
- `nego_geometry_state.dart` (`NegoGeometryState`): parámetros geométricos derivados del `activeMood` (tamaños de ojos, offsets, glow, float).
- `nego_motion_values.dart` (`NegoMotionValues`): valores animados calculados desde tiempo/interacción (rotación, offsets, blinkScaleY, pulso).
- `nego_tokens.dart` (`NegoTokens`): constantes (colores, tamaños base, duraciones, rangos).
- `nego_paths.dart` (`NegoPaths`): paths:
  - ojo base (rounded rect path en viewBox 68x132)
  - recorte excited (activo + inactivo fuera de viewBox)
  - recorte winking (activo + inactivo fuera de viewBox)
- `nego.dart`: barrel export.

### Flujo de datos (simplificado)

`NegoAvatar` -> `NegoMotionController` (estado/tiempo/interacción) -> produce:

- `geometry` (`NegoGeometryState`, interpolado en transiciones)
- `motionValues` (`NegoMotionValues`)
- `activeMood`

Luego `NegoPainter` consume esos valores y dibuja en un `Canvas`.

## Uso Recomendado

### 1) Decorativo (no interactivo)

```dart
const NegoAvatar(
  size: 200,
  interactive: false,
)
```

### 2) Interactivo (tap + tracking)

```dart
NegoAvatar(
  size: 256,
  mood: NegoMood.idle,
  interactive: true,
  onTap: () {
    // analytics / navigation / etc
  },
)
```

### 3) Looking controlado

```dart
NegoAvatar(
  size: 256,
  mood: NegoMood.looking,
  lookAngle: -18,
  lookVertical: NegoLookVertical.down,
  interactive: true,
)
```

## Performance / Buenas Practicas

- `NegoAvatar` envuelve el render en `RepaintBoundary`.
- `TickerMode` se respeta para pausar timers/animación cuando el árbol lo deshabilita.
- `dispose` del controller cancela timers y controllers.

