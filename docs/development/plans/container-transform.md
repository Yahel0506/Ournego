# Container transform: plan de implementación

Estado: olas 0 y 1 y la estética flat glass fusionadas; ola 2 en revisión (#110); ola 3 implementada en `feat/container-transform-w3` (pendiente de verificar en teléfono y de PR). Siguiente: ola 4.
Reconstruido el 15 oct 2026: el borrador original (`Claude outputs/CONTAINER_TRANSFORM_PLAN.md`, 13 oct) nunca se versionó y se perdió. Este documento conserva sus decisiones e incorpora los cambios de diseño aprobados después.

Fuentes: la spec de container transform (v1.0, en adelante «la spec») y el análisis «Ournego: casos de Container Transform» (55 casos numerados 3.x a 9.x, que este plan cita por número). La implementación vigente está documentada en [`docs/development/design/motion/README.md`](../design/motion/README.md).

| PR | Contenido | Estado |
| --- | --- | --- |
| [#95](https://github.com/Yahel0506/Ournego/pull/95) | Ola 0: prerrequisitos sin animación nueva | Fusionada |
| [#96](https://github.com/Yahel0506/Ournego/pull/96) | Ola 1: motor y menú de cuenta | Fusionada |
| [#97](https://github.com/Yahel0506/Ournego/pull/97) | Diálogos flat glass, menú en bloques, feedback como ventana Ournego | Fusionada |
| [#110](https://github.com/Yahel0506/Ournego/pull/110) | Ola 2: ventanas desde ítems, popovers, créditos, panel | En revisión |

---

## 1. Resumen

Lo que el usuario toca **se convierte** en la ventana que se abre, y la ventana **vuelve** a ese elemento al cerrarse. Un solo motor (una `PopupRoute` movida por resortes) sirve a todos los diálogos y menús; las superficies que viven en el árbol del mapa (búsqueda, hoja flotante) usan un reloj de resorte propio (`SpringClock`).

Carácter: calmado. El tamaño y la X nunca se pasan de su destino. La única excepción deliberada es la trayectoria vertical, que pasa un poco su destino y regresa (§3.2). El rebote fuerte (`kOurnegoSpring`) sigue siendo exclusivo de los botones lip.

---

## 2. Decisiones

### 2.1 Decisiones originales (D1–D32)

| # | Tema | Decisión | Vigencia |
| --- | --- | --- | --- |
| D1 | Ubicación del plan | `Claude outputs/` | **Reemplazada**: `docs/development/plans/` |
| D2 | Alcance del plan | Olas 0–4 detalladas, 5–8 esbozadas | Vigente |
| D3 | Carácter | Calmado: ζ de apertura 0.85–0.90, cierre ζ = 1 | Vigente (§3.1) |
| D4 | Entrega | Una rama, un PR y un issue por ola | Vigente |
| D5 | Radios | Un token unificado para todas las ventanas | Vigente |
| D6 | Valor | `OurnegoRadiusTokens.window = 24` | Vigente |
| D7 | Scrim | Negro: menú 0.30, hoja 0.40, diálogo 0.50 | Vigente |
| D8 | Blur | Nivel B (blur de contenido), scrim solo de color | **Ajustada** por E4 y E5 |
| D9 | Posición del menú de cuenta | Centrado, naciendo del botón (center-expand) | Vigente |
| D10 | Stagger del menú | Sin stagger | Vigente |
| D11 | Menú → acción (3.4–3.7) | El menú se cierra y la ventana siguiente nace del ítem tocado; se conserva `Future<ProfileMenuAction?>` | Hecho (ola 2) |
| D12 | Botón de perfil del panel (3.3) | Abre el mismo menú, sin «Mi negocio» | Hecho (ola 0) |
| D13 | Selector de zona (6.4) | Se mantiene como hoja inferior; 6.6 es una sola hoja que cambia de contenido | Pendiente (ola 5) |
| D14 | Marcador → hoja (5.1) | Origen medido una vez; la cámara espera a `p > 0.4` | Pendiente (ola 4) |
| D15 | Motor | `PopupRoute` propia con reloj de resorte | Hecho (ola 1) |
| D16 | Guardado en el panel (7.7) | El diálogo queda abierto mientras guarda | Pendiente (ola 6) |
| D17 | Movimiento reducido | Solo el ajuste del sistema | Hecho |
| D18 | Degradación | Estática primero, dinámica en la ola 8 | Estática hecha |
| D19 | Hoja expandida: scrim y atrás | Colapsar; un segundo atrás la cierra; en comparación, la segunda tarjeta vuelve a la pila | Hecho (ola 0) |
| D20 | Búsqueda: atrás, Esc, tocar el mapa | Cierra el panel y conserva el texto; la X borra | Hecho (ola 0) |
| D21 | Háptica | No por ahora | Vigente |
| D22 | Colapsada ↔ expandida (5.2) | `p` ligado al arrastre | Pendiente (ola 4) |
| D23 | Diálogos sin origen | Mismo preset desde el centro | Hecho (ola 1) |
| D24 | Validación de rendimiento | Android físico de gama media o baja, modo profile | Parcial (ver §6) |
| D25 | Interruptor global | Sí, activo por defecto, en el panel de depuración | Hecho (ola 1) |
| D26 | Radio de popovers pequeños | Excepción `lg = 14` | Hecho (ola 2) |
| D27 | Ubicación del menú de cuenta | `lib/features/navigation/presentation/widgets/profile_menu/` | Hecho (ola 0) |
| D28 | Nivel C por diseño | Hoja flotante, búsqueda, hojas inferiores y popovers sin blur | Vigente |
| D29 | Cerrar → reabrir rápido | Se acepta que la reapertura espere al cierre (≈ 0.3 s) | Vigente |
| D30 | Regreso de ventanas encadenadas | Nacen del ítem del menú y regresan al botón de perfil | Hecho (ola 2) |
| D31 | Barra tras elegir un resultado | Conserva la consulta | Hecho (ola 3) |
| D32 | Fichas de la spec §13 | Una por preset en `docs/development/design/motion/` | La del preset `dialog` está hecha |

### 2.2 Cambios de diseño aprobados después (E1–E15)

E1–E8 surgieron al revisar la ola 1 en el teléfono; E9–E15, al revisar la ola 4. Prevalecen sobre la spec y sobre D3/D8 donde chocan.

| # | Cambio | Motivo |
| --- | --- | --- |
| E1 | **El contenido viaja con el contenedor**, anclado a su centro (la spec §5.5 ancla el contenido al contenedor). Antes quedaba fijo y un recorte se movía solo | «Solo el fondo realiza el movimiento» |
| E2 | **Trayectoria vertical curva**: una sola curva suave para todo el recorrido (`kWindowVerticalPath = Cubic(0.5, 0.2, 0.7, 1.25)`): la Y se adelanta a la X hasta ~20 %, pasa su destino ~3.5 % hacia el 90 % y regresa. La X y el tamaño siguen la ruta normal. La misma curva al abrir y al cerrar | Primero se pidió un pequeño exceso en Y; una protuberancia localizada se sentía como un tirón, así que se reemplazó por una curva única |
| E3 | **Resortes más suaves** para `dialog`: apertura k 170 / ζ 0.9, cierre k 185 / ζ 1 (antes 350 y 450). ≈ 0.4 s | «Demasiada aceleración» |
| E4 | **Blur estático que se despeja al final**: el contenido aparece pronto (alpha `[0.05, 0.30]`) y totalmente desenfocado (12 dp, constante); desde `p = 0.62` el blur se despeja (`easeInQuad`) y vale 0 exactamente al terminar. Los ítems responden desde `p = 0.62` | Pedido explícito |
| E5 | **Diálogos flat glass**: `OurnegoDialogSurface` con fondo plano opaco (`OurnegoGlassPalette.navFace`), contorno de 1 px (`OurnegoGlassPalette.border`), sin blur ni sombra, como la barra de navegación y la hoja flotante. El blur de tránsito va dentro de la superficie (`ContainerTransformBlur`), así que solo se desenfoca el contenido | Pedido explícito |
| E6 | **El diálogo de feedback es una ventana Ournego**: misma superficie y misma animación (antes un `AlertDialog` de Material con fundido de respaldo) | Pedido explícito |
| E7 | **Menú de cuenta en bloques** (estilo ajustes de Google): cada sección es un rectángulo redondeado de bloques (esquinas externas 18, internas 4, 2 dp entre bloques); cerrar sesión en su propio grupo | Pedido explícito |
| E8 | **Diálogo de alerta sin `AlertDialog` interno**: título, cuerpo y barra de acciones directamente en la superficie, con el padding del menú (margen de texto ~20 dp). Antes el texto quedaba a 65 dp del borde | Error visual reportado |
| E9 | **El scrim sigue a la hoja visible**, no solo a su expansión: se aclara al minimizar o cerrar desde expandida | Error reportado: el scrim se quedaba oscuro al minimizar desde expandida |
| E10 | **Se cierra hacia un origen vivo**: el origen se vuelve a medir al cerrar. Si ya no existe (ícono restaurado, fila de un panel cerrado) o quedó fuera de la pantalla, la hoja sale hacia abajo como antes | Error reportado: la hoja volvía al hueco de un ícono que ya no estaba |
| E11 | **Descartar en dos fases**: mientras el dedo arrastra hacia abajo, la hoja baja y se encoge; al soltar, desaparece mientras viaja a su origen con la curva de E2 | Pedido explícito |
| E12 | **La hoja usa el motor de las olas 1–2**: blur estático de E4 en el contenido al abrir y cerrar, y la trayectoria curva de E2 al abrir, cerrar, minimizar y restaurar. La hoja pasa de nivel C a nivel B (sin blur en web, nada en movimiento reducido) | Pedido explícito |
| E13 | **El ícono minimizado no parpadea**: relevo en el mismo cuadro, sin fundido de la pila | Error reportado |
| E14 | **La pila crece hacia abajo**: el negocio que se minimiza ocupa el hueco bajo la pila sin mover a los demás; con 4, el más viejo (arriba) sale animado y el resto sube un lugar | Pedido explícito |
| E15 | **Del marcador a la hoja también cambia el contenido**: la hoja nace con el aspecto del marcador (círculo, color, ícono) y el contenido se funde con blur estático solo en la primera fracción | Pedido explícito |

---

## 3. Sistema de movimiento

### 3.1 Presets

En `lib/core/ournego_motion.dart`. `kDialogSpring` y `kPopoverSpring` tienen consumidores; los demás son puntos de partida que se calibrarán en su ola con el mismo criterio que E1–E4.

| Preset | Usado en | Apertura k / ζ | Cierre k / ζ | Contenido (alpha) | Scrim | Blur | Estado |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `kDialogSpring` | Menú de cuenta, todos los diálogos | 170 / 0.9 | 185 / 1 | 0.05–0.30 | 0.30 menú · 0.50 diálogo | 12 dp, se despeja desde 0.62 | En uso (E2–E4) |
| `kPopoverSpring` | Chips, aviso de «Contactar» | 320 / 0.90 | 380 / 1 | 0.10–0.45 | — | C | En uso (ola 2) |
| `kBottomSheetSpring` | Hojas de ubicación y zona | 300 / 0.90 | 400 / 1 | 0.25–0.65 | 0.40 | C | Ola 5 |
| `kFloatingSheetSpring` | Marcador o fila → hoja colapsada | 300 / 0.90 | 400 / 1 | 0.25–0.65 | — | C | Ola 4 |
| `kSheetExpandSpring` | Colapsada ↔ expandida (arrastre) | 380 / 0.90 | 380 / 1 | 0.35–0.75 | 0.40 · 0.50 comparación | C | Ola 4 |
| `kMinimizeSpring` | Hoja ↔ ícono de la pila | 380 / 0.90 | 450 / 1 | 0.60–1.0 | — | C | Ola 4 |
| `kSearchInPlaceSpring` | Barra → panel de resultados | 450 / 0.88 | 550 / 1 | 0.35–0.70 | — | C | Ola 3 |
| `kFullBleedSpring` | Card → pantalla | 300 / 1 | 400 / 1 | 0.25–0.65 | — | C | Ola 7 |

### 3.2 Reglas vigentes

- Tamaño y X: `P_MAX = 1` (el controlador de la ruta está acotado a [0, 1]).
- Y: `kWindowVerticalPath` (E2) cuando el preset lo define (`verticalPath`).
- El contenido viaja con el contenedor (E1) y se recorta con su forma.
- El disparador se aparta en `p = 0.12` (conserva su layout) e ignora toques mientras su ventana exista.
- Movimiento reducido o interruptor apagado: fundido de 120 ms en el rect final, sin viaje ni blur.
- Web: nivel C (sin blur de tránsito).

### 3.3 Piezas

| Pieza | Archivo |
| --- | --- |
| Tokens y curvas | `lib/core/ournego_motion.dart` |
| Ventanas (`seg`) | `lib/core/motion/motion_window.dart` |
| Nivel y interruptor | `lib/core/motion/ournego_motion_level.dart` |
| Reloj en el árbol | `lib/core/motion/spring_clock.dart` |
| Disparador | `lib/shared/widgets/container_transform/container_transform_origin.dart` |
| Destino y blur | `lib/shared/widgets/container_transform/container_transform_destination.dart` |
| Ruta | `lib/shared/widgets/container_transform/container_transform_route.dart` |
| API (`showOurnegoDialog`, `showOurnegoMenu`) | `lib/shared/widgets/container_transform/show_ournego_window.dart` |
| Superficie de diálogo | `lib/shared/widgets/ournego_dialog_surface.dart` |

---

## 4. Invariantes

Toda ola los cumple.

1. **Contratos**: cada API devuelve el mismo `Future<T?>` que reemplaza. La `Future` se completa al iniciar el pop, igual que la de `showDialog`.
2. **Claves de prueba**: se conservan todas las `ValueKey` existentes, y el contenido está en el árbol desde el primer frame.
3. **Asentamiento**: los resortes usan `kOurnegoSpringTolerance` para que `pumpAndSettle` termine.
4. **Estado restaurado**: `restoreState` de la hoja no anima (`SpringClock.jumpTo`).
5. **Entrada**: scrim y atrás responden desde el primer frame; los ítems, cuando su contenido es legible.
6. **Interruptor global** (`OurnegoMotion.containerTransformEnabled`): mitigación sin revertir código.
7. **Guardas de arquitectura**: `test/architecture/no_raw_dialogs_test.dart` (ya existe); en la ola 5 se extiende a `showModalBottomSheet`.
8. **Verificación en teléfono**: cada ola se revisa grabando la transición a 60 fps en el Android físico en modo profile, antes de abrir la PR.

---

## 5. Olas

### Ola 0: prerrequisitos (hecha, #95)

Tokens de resorte y ventanas, radio `window = 24`, `OurnegoFormDialog`, diálogos de edición y créditos migrados, sin `bounceInOut`, atrás/Esc/scrim en hoja y búsqueda (D19, D20), menú de cuenta movido a `navigation` y botón del panel conectado (D12, D27), cadena error → feedback extraída, caracterización del controlador de la hoja, configuración nativa de Patrol.

### Ola 1: motor y menú de cuenta (hecha, #96, más E1–E4)

`ContainerTransformRoute`, `ContainerTransformTrigger`, `ContainerTransformDestination`, `showOurnegoDialog`/`showOurnegoMenu`, `SpringClock`, interruptor de depuración, guarda contra `showDialog`. El menú de cuenta crece desde los botones de perfil del mapa y del panel. Todos los `showDialog` migrados, sin origen.

**Movido a la ola 2:** el traspaso de origen desde un ítem del menú (antes 1.6), porque solo se usa ahí.

### Estética de diálogos (hecha, #97)

E5–E8.

### Ola 2: ventanas desde ítems, popovers, créditos y panel (en revisión, #110)

- **Motor:** `showOurnegoPopover` (anchored-grow sin velo, voltea, no sale de la pantalla, start/end), origen estático con regreso (`staticOrigin`, `returnOrigin`), `ContainerTransformHandoff`, `OurnegoPopoverSurface` (radio 14, D26). `kPopoverSpring` recalibrado.
- **3.4, 3.5:** feedback y la confirmación de cerrar sesión nacen del bloque tocado del menú y vuelven al botón de perfil (D11, D30). Un segundo toque mientras el menú se cierra ya no abre otra ruta.
- **4.5:** las opciones de los chips son un popover desplazable bajo el chip (sin `MenuAnchor`).
- **5.9:** «Contactar» sin teléfono es un popover anclado al botón.
- **9.1:** los créditos nacen del botón «i».
- **7.1, 7.3, 7.4 (solo el origen):** los editores de identidad, teléfono y horarios nacen de su tile.

### Pautas comunes a las olas 3–8

Cada ola se ejecuta igual que la 2:

1. Rama `feat/container-transform-wN` desde `main` actualizado; un issue por ola (D4).
2. **Antes de tocar una superficie sin pruebas, caracterizarla** (como el controlador de la hoja en la ola 0).
3. Calibrar el preset de la ola con el criterio de E1–E4: el contenido viaja con su contenedor, arranque suave (rigidez baja), contenido visible pronto, nada se pasa salvo la Y cuando el preset lo pida.
4. Pruebas por caso: forma (rect inicial, rect final), continuidad al interrumpir, movimiento reducido, entrada bloqueada hasta ser legible, claves conservadas.
5. Grabar cada transición en el teléfono en modo profile y revisar los cuadros a 60 fps (§6).
6. Commits y título de la PR en Conventional Commits; validar con `tool/check_commit_subjects.sh` antes de subir (los scopes no admiten comas).
7. Documentar en `docs/development/design/motion/README.md` (pieza nueva o ficha del preset) y marcar la ola en este plan.

### Ola 3: búsqueda in-place (4.1–4.4)

**Estado:** implementada en `feat/container-transform-w3`, apilada sobre la #110 porque toca `map_screen.dart`. Pendiente: verificación en teléfono (no había dispositivo conectado al implementarla) y PR.

**Lo construido:** `SearchMorphSurface` (`lib/features/map/presentation/widgets/search_morph_surface.dart`) con un `SpringClock(kSearchInPlaceSpring)` en `map_screen.dart`; el marco interpola de la barra (medida al abrir con `searchBarKey`) al panel, con relleno transparente → opaco en [0, 0.3], radio 30 → 24, y contenido a tamaño final centrado y recortado, con fundido en [0.35, 0.70]. La X cierra y borra la consulta al asentarse (`onSettled`); si el usuario vuelve durante el cierre, borra ya. Elegir un resultado conserva la consulta (D31) y oculta el panel. Filas con entrada escalonada de 40 ms (máximo 6) que se reproduce una vez por consulta; cambios de estado (vacío, cargando, sin resultados, resultados) con fundido de 120 ms.

**Desviaciones:** (a) el panel es de altura completa, así que no hay animación de altura: la transición de estados es solo un fundido; (b) el origen de la hoja desde la fila (4.4) se pospone a la ola 4, porque `openBusinessSheet` todavía no acepta origen; hoy la búsqueda cierra el panel y la hoja aparece como siempre; (c) el `FocusNode` nunca cambia de árbol, así que el foco se conserva por construcción y lo prueba `map_search_panel_test.dart`.

**Rama:** `feat/container-transform-w3`. **Preset:** `kSearchInPlaceSpring` (sin velo, nivel C).

**Estado actual.** La barra vive en `TopNavigationBarWidget`; el panel (`MapSearchOverlayWidget`) es un hermano en el `Stack` de `map_screen.dart`, envuelto en `FadeTransition` + `SlideTransition(Offset(0, 0.04))` movidos por `_searchPanelAnimationController` (260/220 ms, `easeOutCubic`/`easeInCubic`; `map_screen.dart` ~67-69, ~348-361, ~654-660). La visibilidad la decide `_syncSearchPanelVisibility` (~993) con foco, texto y `_isSearchPanelDismissed` (ola 0). El borde inferior del panel sale de `_searchPanelBottomInset` (~133), que depende de la altura de la hoja abierta.

**Restricción que decide la arquitectura.** La barra no puede cambiar de árbol ni entrar a una ruta: perdería su `FocusNode` y el teclado parpadearía. Por eso esta ola **no** usa `ContainerTransformRoute`; usa `SpringClock` dentro del `Stack` del mapa.

| Caso | Implementación |
| --- | --- |
| 4.1 Foco → panel | Sustituir el `AnimationController` y sus dos animaciones por un `SpringClock(preset: kSearchInPlaceSpring)` del estado del mapa. Una capa nueva, `_SearchMorphSurface`, pinta detrás de la barra un rect que interpola del rect de la barra (medido con `topNavigationBarKey`/la `GlobalKey` del `OurnegoGlassSurface` una vez por apertura) al rect del panel. El borde inferior se lee **en cada frame** de `_searchPanelBottomInset`. Radio 30 → 24 (`container` → `window`); relleno de vidrio a opaco en [0, 0.3]; sin `BackdropFilter` en ningún momento |
| 4.1 Contenido | `MapSearchOverlayWidget` se maqueta a tamaño final y se recorta con la forma interpolada; viaja con el contenedor (E1) y entra en [0.35, 0.70]. Las filas de resultados entran con stagger 0.04 solo en la primera aparición de cada consulta |
| 4.2 Cierre | Resorte de cierre (ζ = 1), sin stagger. Con la X, el texto se borra cuando `p` llega a 0 (`SpringClock.onSettled`), no en el mismo frame. Atrás, Esc y tocar el mapa siguen ocultando sin borrar (D20) |
| 4.3 Estados del panel | Vacío, cargando, sin resultados y resultados: cross-fade corto (120 ms) con altura animada por un resorte corto aparte, sin cambiar el rect de golpe (spec §11, contenido que carga) |
| 4.4 Fila → hoja | `onBusinessSelected` (~695) mide el rect de la fila tocada y lo pasa como origen a `_viewController.openBusinessSheet(..., origin:)`. El panel se pliega a la barra mientras la hoja crece desde la fila (efecto completo cuando exista la ola 4; aquí se deja el parámetro conectado). La barra conserva la consulta (D31): hoy `onBusinessSelected` escribe el nombre del negocio y `_closeSearchOverlay` lo borra; cambiar a `_dismissSearchPanel` y no tocar el texto |
| Atrás y Esc | Ya resueltos en la ola 0; comprobar que siguen con la nueva capa |

**Archivos:** `map_screen.dart`, `map_search_overlay_widget.dart`, `top_navigation_bar_widget.dart`, nuevo `lib/features/map/presentation/widgets/search_morph_surface.dart`.

**Pruebas:** la existente `map_search_panel_test.dart` debe seguir verde. Nuevas: el `FocusNode` conserva el foco en cada frame de apertura y cierre; el rect pasa del de la barra al del panel sin saltos; con la hoja abierta el destino cambia durante la animación sin saltos; la X borra al final y no antes; elegir un resultado conserva la consulta; movimiento reducido (fundido de 120 ms, sin viaje).

**Riesgos:** alto (árbol del mapa, foco y teclado). Reversión: interruptor global (vuelve al fundido) o revertir la PR.

### Ola 4: hoja flotante (5.1–5.8)

**Rama:** `feat/container-transform-w4`, en dos PRs. **Presets:** `kFloatingSheetSpring`, `kSheetExpandSpring`, `kMinimizeSpring` (nivel C). **Precondición:** `floating_sheet_controller_test.dart` y `map_floating_sheet_back_test.dart` en verde.

**Estado actual.** `ournego_floating_sheet.dart` (~1017 líneas) anima con `Animated*` independientes a 420 ms (`kSheetTransitionDuration`, `kEaseOutExpo`): un `AnimatedSwitcher` cuyo `Stack` lleva una `ValueKey` compuesta por modo y negocios (~95-130), así que scrim y pila se desmontan en cada cambio; `_buildFloatingSheet` (~338) usa `AnimatedPositioned` + `AnimatedOpacity(onEnd: finalizeTransitionOut)` + `AnimatedScale` + `AnimatedContainer`, y el arrastre solo usa `onVerticalDragEnd` (~400). Al minimizar (`isMinimizingToStack`, ~345) la hoja se encoge a escala 0.2 mientras el ícono de la pila aparece aparte: dos objetos. `FloatingSheetController.openBusiness` (~54) pasa por `minimized` y espera 40 ms con `Future.delayed` antes de `collapsed`. `MapViewController.openBusinessSheet` (~110) hace `animateTo(zoom: 18)` en el mismo instante.

**Diseño.** El controlador sigue siendo la fuente de verdad de los estados. La capa visual pasa a tres `SpringClock`: `pOpen` (origen → colapsada), `pExpand` (colapsada ↔ expandida, ligado al arrastre) y `pMin` (hoja ↔ ícono). El `Stack` deja de tener key; scrim, pila y hoja son hermanos estables y solo el contenido de la hoja cambia con el negocio.

**PR 4a: interior de la hoja**

| Caso | Implementación |
| --- | --- |
| 5.3 Scrim | Alpha = 0.40 · `seg(pExpand, 0, 0.6)`; 0.50 en comparación. Color plano. Ya responde a toques (ola 0) |
| 5.2 Colapsada ↔ expandida (D22) | `onVerticalDragUpdate` → `pExpand.dragTo(...)`; `onVerticalDragEnd` → `release(velocity)` (umbral 0.5, o velocidad > 700 dp/s). El contenido expandido se maqueta a la altura expandida y se recorta; `_CollapsedActions` sale en [0, 0.3] y `_ExpandedContent` entra en [0.35, 0.75]. El controlador se actualiza al asentarse (`onSettled`) |
| 5.6 Cambiar de negocio | Mismo contenedor; el contenido hace cross-fade con 8 dp de desplazamiento en la dirección del cambio. Scrim y pila no se desmontan |

**PR 4b: entrar, salir y pila**

| Caso | Implementación |
| --- | --- |
| 5.1 Marcador o fila → hoja (D14) | `openBusiness(business, {Rect? origin})`; el origen se mide una vez al tocar (marcador en `map_canvas_widget.dart`, fila en la ola 3). Se elimina el `Future.delayed(40 ms)`: el estado pasa a `collapsed` y la capa anima `pOpen` desde el origen. `openBusinessSheet` espera a que `pOpen` cruce 0.4 antes de `animateTo` (timeout 150 ms; sin espera en movimiento reducido). Sin origen (enlace profundo, restaurar) entra desde el borde inferior |
| 5.4 Minimizar | Un solo contenedor: rect de la hoja → rect del ícono de 48 dp (medido desde `MinimizedStackIcon` con `GlobalKey`). Radio 24 → 24 (círculo de 48). El contenido sale en [0, 0.3] y el logo entra en [0.6, 1]. El ícono de la pila solo se pinta cuando `pMin` llega a 1; se elimina `isMinimizingToStack` |
| 5.5 Restaurar | Inversa de 5.4 desde el ícono |
| 5.7 Ícono → segunda tarjeta | El ícono se convierte en la segunda tarjeta (`pMin` inverso hacia la mitad derecha) mientras la primera interpola su ancho a la mitad |
| 5.8 Cerrar una tarjeta en comparación | La restante interpola al ancho completo; la cerrada se minimiza (5.4) o se desvanece si la pila está llena |
| Restauración | `restoreState` usa `jumpTo`: la hoja aparece ya colocada al abrir la app |

**Interrupciones:** tocar otro marcador a mitad de `pOpen` cambia el contenido y `pOpen` sigue desde su `p` y `v`; minimizar a mitad de una expansión congela `pExpand` y cede a `pMin`. Comparación: `openBusinessSheet` hoy ignora toques en modo comparación; se conserva.

**Pruebas:** caracterización sin cambios de expectativa (salvo la del retardo de 40 ms); `restoreState` no anima; arrastre parcial y suelta por umbral y por velocidad; nunca dos objetos al minimizar; interrupción con otro marcador; la cámara arranca después de `p = 0.4`; movimiento reducido.

**Rendimiento:** `RepaintBoundary` separados para scrim, hoja y pila; la sombra de la hoja se conserva (excepción documentada). Es la superficie más usada: perfilar con el mapa en movimiento.

#### Estado

Implementada en `feat/container-transform-w4` (dos commits locales, sin PR): tres `SpringClock`, arrastre ligado al dedo, minimizar como un solo objeto, apertura desde el marcador o la fila de búsqueda, cámara después de `p = 0.4`, sin el retraso de 40 ms. Verificado en el teléfono: apertura desde el marcador, expansión por arrastre y minimizar. Los ajustes E9–E15 de abajo también están implementados (cinco commits, en el orden indicado). Verificado en el teléfono: apertura desde el marcador con color, icono y blur; descarte con swipe (se hunde, se encoge y regresa al marcador); minimizar con un negocio ya apilado (el nuevo queda debajo sin mover al primero). Sin verificar en el teléfono: scrim al minimizar desde expandida, expulsión con 4 apilados, cierre con el marcador fuera de pantalla y restaurar desde la pila. Pendiente: 5.7/5.8 (comparación), que siguen con el `AnimatedSwitcher` anterior.

#### Ajustes tras la revisión en el teléfono (E9–E15)

Van en la misma rama, antes de abrir la PR. Cada ajuste dice qué falla hoy, por qué, y cómo se resuelve.

**E9. El scrim se queda oscuro al minimizar desde expandida.**
- *Causa:* el scrim lee solo `pExpand` (`0.40 · pExpand`). Al minimizar, el estado pasa a `minimized`, `_syncSheetMotion` deja de mover `pExpand` y este se queda en 1; tras `finalizeTransitionOut` la hoja desaparece, pero el scrim sigue pintado.
- *Diseño:* `alpha = 0.40 · pExpand · (1 − seg(pMin, 0, 0.6)) · presencia`, donde `presencia = seg(pOpen, 0, 0.3)`, así el scrim se va con la hoja al minimizar y al cerrar. Cuando la hoja termina de irse (`activeBusiness == null`), `pExpand.jumpTo(0)`. El scrim deja de bloquear toques en cuanto el estado deja de ser `expanded`, como hoy.
- *Pruebas:* minimizar desde expandida deja el scrim en 0 al terminar; cerrar desde expandida, igual; colapsar sigue aclarando el scrim con la expansión.

**E10. Al cerrar, el origen puede no existir ya.**
- *Causa:* el origen es un `Rect` fijo medido al tocar. Si la hoja salió del ícono de la pila, ese ícono ya no existe al cerrar; si salió de un marcador, la cámara se movió después y el rectángulo ya no coincide.
- *Diseño:* `SheetEntry.origin` pasa a ser un `SheetOrigin` con: un `resolve()` que vuelve a medir el origen en el momento de cerrar, y el aspecto del origen (E15). Para el marcador, `resolve()` proyecta su `LatLng` con la cámara actual (`camera.latLngToScreenOffset`) y lo devuelve solo si cae dentro de la pantalla visible (descontando la barra superior y la navegación inferior, con un margen de 8 dp). El ícono de la pila restaurado y la fila de búsqueda devuelven `null`, porque ya no están. Con `null`, la hoja sale hacia abajo: se desliza fuera de la pantalla con trayectoria recta, sin la curva (con la curva rebotaría hacia arriba antes de bajar).
- *Archivos:* `floating_sheet_controller.dart` (`SheetOrigin`), `map_canvas_widget.dart` y `map_screen.dart` (el marcador entrega su `LatLng` y su aspecto), `ournego_floating_sheet.dart` (resolver al empezar el cierre y fijar el destino para todo el cierre, para que no salte si la cámara se mueve durante el cierre).
- *Pruebas:* cerrar una hoja restaurada desde la pila sale hacia abajo; cerrar con el marcador fuera de la pantalla sale hacia abajo; cerrar con el marcador visible termina sobre su posición actual.

**E11. Descartar con el dedo, en dos fases.**
- *Fase 1, el dedo:* con la hoja colapsada, arrastrar hacia abajo alimenta un progreso de descarte `d = clamp(dy / 280, 0, 1)`. La hoja se desplaza `dy` con un poco de resistencia (`dy · (1 − 0.3·d)`) y se encoge de 1 a 0.88 alrededor de su centro. Desde expandida, el mismo gesto primero colapsa (`pExpand` baja a 0) y lo que sobra del recorrido pasa a `d`: un solo gesto continuo.
- *Fase 2, al soltar:* si `dy ≥ 96 dp` o la velocidad es mayor a 700 dp/s hacia abajo, se cierra. Si no, `d` vuelve a 0 con un resorte (`kSheetExpandSpring`, cierre). El cierre arranca del rectángulo actual (desplazado y encogido), no del de reposo: se guarda como `closeFrom`, y `pOpen` se asienta en 0 con la velocidad del dedo convertida a unidades de `p`. Con la curva de E2, una hoja cuyo origen está arriba sigue bajando un poco antes de curvarse hacia él, que es el «primero baja y luego regresa» pedido. El contenido se desenfoca y se desvanece según E12.
- *El botón de cerrar y atrás* usan la misma fase 2 desde el reposo, sin la fase 1.
- *Pruebas:* arrastrar 60 dp y soltar despacio vuelve a su lugar; arrastrar 120 dp cierra; a mitad del arrastre la hoja está más abajo y es más pequeña que en reposo; desde expandida, un solo gesto largo colapsa y después descarta.

**E12. El motor de las olas 1–2 en la hoja.**
- *Blur:* se extrae la cuenta de `ContainerTransformBlur` (blur constante de 12 dp que se despeja desde `blurClearStart` con `easeInQuad` y vale 0 en `p = 1`) a una función pura compartida, `transitBlurSigma(p, preset)`. La ruta la sigue usando igual, y la hoja la aplica con un `ImageFiltered` solo sobre el contenido (no sobre el fondo ni el borde), que se omite cuando sigma es 0. Al cerrar es la misma cuenta en reversa, así que el contenido se desenfoca en cuanto empieza el cierre.
- *Trayectoria:* la Y del marco sigue `kWindowVerticalPath` y la X y el tamaño siguen `p`, igual que en las ventanas, al abrir, cerrar, minimizar y restaurar. La salida hacia abajo de E10 es la excepción (recta).
- *Presets:* `kFloatingSheetSpring` y `kMinimizeSpring` ganan `maxItemBlur: 12`, `blurClearStart: 0.62` y `verticalPath: kWindowVerticalPath`. La ventana del contenido de la hoja pasa a `[0.10, 0.35]` para que aparezca pronto y desenfocado, como en E4. Se calibra en el teléfono.
- *Minimizar y restaurar:* el contenido que sale y el ícono que entra llevan el mismo blur estático durante su fundido.
- *Niveles:* B en Android e iOS; C en web (curva sí, blur no); R con movimiento reducido o con el interruptor global apagado (sin curva ni blur, saltos instantáneos, como hoy).
- *Rendimiento:* un solo `ImageFiltered` sobre ~576 × 200 dp. Se mide en el teléfono; si cae de 60 fps, la degradación dinámica de la ola 8 (D18) lo baja a C.
- *Pruebas:* a mitad de la apertura el contenido tiene blur y al terminar no; la Y del marco no es lineal respecto a `p` mientras la X sí; en web no hay `ImageFiltered`.

**E13. Parpadeo del ícono al minimizar.**
- *Causa:* la columna de la pila está envuelta en un `AnimatedOpacity` (opacidad 0 si está vacía, 1 si no, en 420 ms). Cuando el marco llega y se quita, el ícono nuevo entra en una pila que estaba vacía o recién recalculada y se desvanece desde 0: el ícono desaparece un cuadro y reaparece con fundido.
- *Diseño:* se quita el `AnimatedOpacity` de la pila. Cada ícono maneja su propia entrada (E14). Un ícono que llega por relevo desde la hoja aparece con opacidad 1 en el mismo cuadro en que se quita el marco, que en `pMin = 1` ya pinta exactamente el mismo ícono en el mismo rectángulo y con el mismo radio (`innerCard`) y borde.
- *Pruebas:* en cada cuadro del relevo hay exactamente una copia visible del ícono, con opacidad 1, en su hueco.

**E14. La pila crece hacia abajo.**
- *Orden:* `minimizedBusinesses` pasa de «más nuevo primero» a «más viejo primero». `_pushToMinimized` agrega al final y, con más de 4, quita el primero. Afecta a todos los que apilan: minimizar, reemplazar el negocio abierto y minimizar en comparación. `restoreState` conserva los últimos 4. El orden guardado por versiones anteriores se verá invertido una sola vez; es solo orden visual, así que no hace falta migrar.
- *Pila animada:* `_MinimizedStack` pasa a ser un widget con estado. Cada ícono va `Positioned` en su hueco (`top = sideStackTop + i · 56`) con un resorte corto propio, identificado por id. Al cambiar el hueco de un ícono (por expulsión o por restaurar uno del medio), se desliza al nuevo hueco. El ícono expulsado queda como «fantasma»: sube un hueco, se encoge a 0.8 y se desvanece, y después se quita.
- *Destino de minimizar:* el hueco del negocio en la lista nueva, `min(n, 3)`, fijado al empezar. La expulsión y el desplazamiento empiezan a la vez que el minimizado, así que el hueco está libre cuando la hoja llega y los demás nunca saltan.
- *Íconos que llegan sin hoja que viaje* (al reemplazar el negocio abierto, al minimizar en comparación): entran en su hueco con fundido y escala de 0.8 a 1.
- *Restaurar desde la pila* es el minimizado en reversa (`pMin` de 1 a 0 desde ese hueco), y los íconos de abajo suben un lugar.
- *Pruebas:* el orden nuevo en `floating_sheet_controller_test.dart` (más viejo primero, el quinto expulsa al primero); con 2 apilados, minimizar no mueve a los 2; con 4, el primero sale, los otros 3 suben y la hoja aterriza en el hueco 3; el fantasma se quita al terminar.

**E15. Del marcador a la hoja, también el contenido.**
- *Datos:* `SheetOrigin` lleva el aspecto del marcador: radio (mitad de su tamaño), color de fondo, color e ícono (`BusinessMarkerUiModel`). Lo entrega `map_canvas_widget.dart` al tocar.
- *Marco:* en `p = 0` es el círculo del marcador, con su color. El radio va al de la hoja y el relleno pasa del color del marcador a `surface` en `[0, 0.3]`.
- *Contenido:* el ícono del marcador, al tamaño del marcador y centrado en el marco, se desvanece en `[0, 0.25]`; el contenido de la hoja entra en `[0.10, 0.35]` (E12). Los dos llevan blur estático durante el fundido, así que el cambio se mezcla en vez de cortarse, y termina en la primera fracción. El contenido de la hoja después sigue la regla de E12 (el blur se despeja desde 0.62).
- *Cierre:* si el marcador es visible (E10), el marco vuelve a su aspecto en reversa; si no, sale hacia abajo sin el aspecto del marcador.
- *El marcador real* no se oculta: el marco empieza exactamente encima, con su mismo aspecto, y la cámara se mueve después.
- *Otros orígenes:* la fila de búsqueda y el borde inferior usan el aspecto genérico (relleno `surface`, sin contenido de origen); la pila usa el ícono (E14).
- *Pruebas:* en el primer cuadro el marco es un círculo del color del marcador; en `p ≈ 0.15` se ven los dos contenidos; desde `p ≈ 0.35` solo el de la hoja.

**Orden de implementación** (cada paso con sus pruebas, suite completa en verde y revisión en el teléfono antes del siguiente):
1. E14 y E13: orden de la pila, pila animada y relevo sin parpadeo. Cambia el controlador y su prueba de caracterización.
2. E9: scrim.
3. E12: función de blur compartida, presets y trayectoria curva.
4. E10 y E15: `SheetOrigin`, origen vivo y aspecto del marcador.
5. E11: descarte en dos fases.

**Verificación en el teléfono:** marcador → hoja → arrastrar abajo → cerrar, con el marcador visible y con el marcador fuera de la pantalla; minimizar con 0, 2 y 4 apilados; restaurar del medio de la pila y cerrar la hoja restaurada; minimizar desde expandida (scrim); grabar cada caso y revisar los cuadros a 60 fps.

### Ola 5: franja superior, zona y ubicación (6.2–6.6, 9.3)

**Estado:** implementada en `feat/container-transform-w5` (apilada sobre la #113; sin PR ni verificación en el teléfono). Lo construido: `showOurnegoSheet` y `OurnegoSheetSurface` (hoja acoplada al borde, sube desde abajo o crece desde un botón, sigue el dedo al arrastrar hacia abajo y se cierra al soltar pasado el 30 % o con un fling de más de 700 dp/s); la hoja de acceso a ubicación y el selector de zona son una sola hoja (`showLocationFlowSheet`) que cambia de contenido con fundido y altura animada, con los mismos resultados y claves; `MapTopStrip` anima la tarjeta de registro, el banner y el chip en un solo contenedor; el banner de conexión se superpone, pasa a verde en su sitio y se retira solo, sin `SnackBar`; la guarda de arquitectura rechaza `showModalBottomSheet`. El chip de zona sigue abriendo el selector solo (`showZonePickerSheet`) como hoja propia.
**Desviaciones:** (a) el arrastre mueve `p` de la ruta con `controller.value` y no con `didStartUserGesture`, que bloqueaba el `pop` al soltar; (b) la hoja de ubicación sube desde abajo en lugar de crecer desde un botón, porque la abre un listener de estado; el botón «Permitir» del banner podría ser su origen, queda como mejora; (c) la franja usa `AnimatedSize` y `AnimatedSwitcher` con curva, no un resorte.

**Rama:** `feat/container-transform-w5`. **Presets:** `kBottomSheetSpring` y uno in-place para la franja.

**Estado actual.** En `map_screen.dart` (~590-650) la franja bajo la barra muestra la tarjeta «Registra tu negocio» **o** un `Column` con el banner de ubicación y/o el chip de zona (banner y chip pueden verse juntos), con `if` que montan y desmontan sin transición. La hoja de acceso a ubicación y el selector de zona son dos `showModalBottomSheet` (`location_access_sheet_widget.dart` ~26, `zone_picker_sheet_widget.dart` ~37) que se abren uno tras otro desde `_showLocationAccessSheet` (~224), protegidos por `_isLocationModalOpen` y `_isZonePickerOpen`. El banner de conexión (`ournego_offline_banner.dart`) aparece con un `if` en un `Column` (empuja el contenido) y al reconectar muestra un `SnackBar` genérico.

| Caso | Implementación |
| --- | --- |
| Pieza nueva | `showOurnegoSheet<T>`: estrategia edge-docked en `ContainerTransformRoute` (destino pegado al borde inferior, radio 24 solo arriba, `P_MAX = 1`), velo 0.40, arrastre hacia abajo ligado a `p` para cerrar. Mismo `Future<T?>` que `showModalBottomSheet` |
| 6.5 Banner o «Mi ubicación» → hoja de acceso | `showLocationAccessSheet` pasa a `showOurnegoSheet` con el botón del banner (o «Mi ubicación») como origen |
| 6.4 + 6.6 Una sola hoja que muta (D13) | La hoja de acceso y el selector de zona son el mismo contenedor: «Elegir zona» cambia el contenido (cross-fade) y la altura (resorte corto aparte) sin cerrar y reabrir. Hacia fuera se conservan los dos tipos de retorno (`LocationAccessSheetAction`, `ZonePickerResult`) con un resultado interno unificado y adaptadores. Las banderas quedan como protección extra |
| 6.2, 6.3 Franja única | Un solo contenedor in-place que cambia de tamaño y contenido entre tarjeta de registro, banner y chip (cross-fade de contenido, altura con resorte), en vez de montar y desmontar |
| 9.3 Banner de conexión | In-place: el banner rojo se vuelve verde con «Conexión restablecida», se queda un instante y se pliega; sin empujar el layout (superpuesto) y sin el `SnackBar` genérico |
| Guarda | Extender `test/architecture/no_raw_dialogs_test.dart` (o una prueba hermana) para rechazar `showModalBottomSheet` fuera de `container_transform/` |

**Pruebas:** `map_location_access_test.dart` y `map_zone_test.dart` deben seguir verdes con las mismas claves (`zone-picker-*`, `location-access-*`, `zone-chip`, `map-location-banner*`) y tipos de retorno. Nuevas: la hoja no se cierra al pasar de acceso a zona; arrastre para cerrar; la franja no salta de layout al cambiar de contenido; el banner de conexión no empuja el contenido.

**Riesgos:** una hoja que muta con dos contratos distintos; el teclado del buscador de zona dentro de la hoja (recalcular el destino con `viewInsets`).

### Ola 6: panel de negocio (7.1, 7.2, 7.4, 7.7)

**Estado:** implementada en `feat/container-transform-w6` (apilada sobre la #114; sin PR). Verificado en el teléfono con una cuenta de dueño: el editor de ubicación nace del bloque del mapa con sus tiles apareciendo al final, y el editor de teléfono guarda con el diálogo abierto (botón en carga, «Cancelar» apagado), se cierra al terminar, la tarjeta muestra el valor nuevo y aparece «Cambios guardados.». Sin verificar en el teléfono: el error al guardar, identidad y horarios, y la confirmación de borrado (la galería de la cuenta tiene una sola imagen y el botón no aparece). `OurnegoSavingDialog` mantiene abierto el diálogo mientras guarda (botón en carga, atrás y toque fuera bloqueados, un segundo toque no guarda dos veces) y, si falla, conserva lo escrito y muestra el error (`OurnegoFormDialog.errorText`). Identidad, ubicación, teléfono y horarios usan ese patrón; desapareció el overlay a pantalla completa para ellos (la galería lo conserva). El editor de ubicación nace del bloque «Mapa» (encabezado y vista previa) y sus tiles entran con `ContainerTransformFadeIn` en [0.5, 0.9]. Borrar una imagen pide confirmación desde su botón.
**Desviaciones:** (a) los controladores de texto de los editores siguen sin liberarse (ya era así; liberarlos al cerrar el diálogo choca con la animación de cierre); (b) no hay prueba a nivel del panel completo, solo del host de guardado y de los orígenes, porque el panel necesita proveedores de datos de negocio.

**Rama:** `feat/container-transform-w6`. **Preset:** `kDialogSpring`.

**Estado actual.** `business_panel_dashboard_widget.dart`: cada `_edit*` (~63-277) abre el diálogo, espera a que se cierre con `pop(true)` y recién después llama a `_runMutation` (~41), que pone `_isSaving` y un overlay a pantalla completa (~426) sobre el panel. Los orígenes de identidad, teléfono y horarios ya están conectados (ola 2); la ubicación (`_editLocation`, ~153) todavía no. `_deleteGalleryImage` (~311) borra sin confirmación.

| Caso | Implementación |
| --- | --- |
| 7.7 Guardar con el diálogo abierto (D16) | Cada editor guarda **desde dentro**: el botón primario de `OurnegoFormDialog` pasa a `isSaving` (carga), el diálogo no hace `pop` hasta que la mutación termina; si falla, el error se muestra en el diálogo sin perder lo escrito. `PopScope` bloquea el cierre mientras guarda. Se elimina el overlay de `_runMutation` para estos casos (la galería conserva un indicador propio) |
| 7.2 Vista previa del mapa → editor de ubicación | La vista previa (`business_panel_map_preview.dart`) es el origen de `LocationEditorDialog`. Los tiles del mapa no se escalan: entran con fundido en la ventana tardía [0.5, 0.9] |
| 7.1, 7.4 | Con 7.7 resuelto, el cambio aparece en la tile de origen cuando el editor vuelve a ella |
| Borrar imagen (hallazgo) | Confirmación (`OurnegoAlertDialog` desde la miniatura) antes de borrar; fuera del alcance de animación pero se hace evidente con las transiciones |

**Pruebas:** doble envío imposible (botón deshabilitado en carga); atrás bloqueado mientras guarda; error dentro del diálogo conserva el texto; al terminar el diálogo vuelve a la tile y el valor ya es el nuevo; el editor de ubicación nace de la vista previa.

**Riesgos:** cambia la lógica de cada `_edit*` (no solo la animación).

### Ola 7: full-bleed y navegación (3.6, 3.7, 6.1, 7.10, 8.1, 8.2, 8.6)

**Rama:** `feat/container-transform-w7`. **Preset:** `kFullBleedSpring` (ζ = 1, sin velo, radio final = el de la pantalla).

**Estado actual.** Casi todas las rutas usan `MaterialPage` o `NoTransitionPage` (`app_router.dart`). La ruta `auth-selection` (~64) ya elige entre `MaterialPage` y un `CustomTransitionPage` según `state.extra == AuthSelectionRouteSource.onboarding`. A `/auth-selection` se llega desde cinco puertas: favorito sin sesión (`map_screen.dart` ~830), tarjeta de registro (~337), menú de cuenta (`profile_menu_actions.dart` ~36), botón del panel (`business_panel_header.dart` ~51), «Comenzar» de registro (`register_business_widget.dart` ~52), además del onboarding (`onboarding_screen.dart` ~132) y la sesión expirada (`session_expired_listener.dart`, sin origen).

| Caso | Implementación |
| --- | --- |
| Pieza nueva | `ContainerTransformPage` en `lib/core/routing/`: una `Page` cuya ruta usa el mismo reloj de resorte y lee el origen (rect, radio, color) de `state.extra` mediante un objeto tipado (`ContainerTransformRouteExtra`). Sin origen, transición estándar |
| 8.1 Cinco puertas → `/auth-selection` | Cada puerta pasa su rect; una sola ruta, un solo código. Generaliza el caso actual de onboarding |
| 3.6, 3.7 | «Iniciar sesión» y «Mi negocio» del menú usan el traspaso de la ola 2 como origen |
| 6.1, 7.10 | La tarjeta «Registra tu negocio» y el botón «Comenzar» se expanden al formulario; el Nego viaja al encabezado como elemento compartido (precedente: el Nego del onboarding) |
| 8.2 | El botón final del onboarding se expande a la selección de acceso (se navega con `go`: no hay regreso) |
| 8.6 Atrás predictivo | `p` ligado al gesto (back predictivo de Android, deslizar desde el borde en iOS); al soltar, resorte con la velocidad del gesto |
| Fuera de alcance | Los pasos internos del acceso (correo, registro, contraseña, verificación, perfil) mantienen una transición estándar o de eje compartido, no container transform |

**Riesgos:** el router y el gesto de atrás; `state.extra` no sobrevive a una restauración de estado (sin origen → transición estándar); enlaces profundos.

### Ola 8: pulido y degradación dinámica

**Rama:** `feat/container-transform-w8` (o varias PRs pequeñas).

| Caso | Implementación |
| --- | --- |
| 3.2 | El avatar del botón de perfil viaja al encabezado del menú como elemento compartido |
| 3.9 | Feedback por sacudida: ya usa el preset de diálogo desde el centro; revisar |
| 4.6 | Micrófono: la transcripción llega a la barra con un viaje corto del texto (opcional) |
| 5.10, 7.8, 7.9 | Catálogo, reseñas, visor de galería y pantallas de detalle del panel: card → detalle cuando esas pantallas existan (hoy son «próximamente») |
| 5.11 | Horario compacto expandible in-place (si se decide hacerlo expandible) |
| 6.7 | El nombre de la zona viaja de la fila al chip |
| 7.5 | `AnimatedCrossFade` del selector de horas (`business_hours_picker.dart` ~104) → altura con resorte |
| 7.6 | `ExpansionTile` de «Editar mi negocio» (`business_panel_editor_dropdown.dart` ~46) → in-place con resorte |
| 7.11, 7.12 | Sugerencias de dirección (`TypeAheadField`) y selector de categoría (`DropdownButtonFormField`) como popovers |
| 7.13 | Error de validación del formulario desde el botón de enviar |
| 8.3 | «Continuar con correo» → login (opcional; un eje compartido también sirve) |
| 8.5 | Cambio de pestaña (`main_layout_screen.dart`, `TweenAnimationBuilder` de 220 ms): duración y curva desde tokens y desplazamiento según la dirección. No es container transform |
| 9.4 | Snackbars con el mismo resorte de entrada y colocados sobre la hoja flotante cuando está abierta |
| 9.5 | Globo de Nego en la hoja de ubicación como parte de la entrada del contenido |
| Degradación dinámica (D18) | Medir tiempos de fotograma en las primeras aperturas (`FrameTiming`); si hay N fotogramas seguidos por encima del presupuesto, bajar de B a C y recordarlo (`shared_preferences`) |
| Web | Probar el blur de tránsito en Chrome (profile); si es aceptable, quitar `&& !kIsWeb` de `resolveLevel` |
| Fichas | Completar en `docs/development/design/motion/` la ficha de cada preset que haya entrado en uso |

## 6. Rendimiento y verificación

- Cada ola se graba en el teléfono (`screenrecord`, modo profile) y se revisan los cuadros a 60 fps antes de la PR.
- **Pendiente:** no hay cifras de tiempo de fotograma. `dumpsys gfxinfo` no ve Flutter (dibuja en un SurfaceView) y `dumpsys SurfaceFlinger --latency` no devuelve datos en el Android del SM-S921B. Opciones: DevTools en profile, o un `FrameTiming` registrado desde una prueba de integración.
- El dispositivo disponible (SM-S921B) es gama alta; el criterio de gama media o baja (D24) sigue sin cubrirse.
- Sin probar en ninguna ola: tema claro, web, textos de sistema grandes.

---

## 7. Documentación relacionada

- [`docs/development/design/motion/README.md`](../design/motion/README.md): piezas, diferencias con la spec y ficha del preset `dialog`.
- [`docs/development/design/DESIGN_SYSTEM.md`](../design/DESIGN_SYSTEM.md): radios, diálogos flat glass y movimiento.
- `AGENTS.md`: regla de abrir diálogos solo con `showOurnego*`.
