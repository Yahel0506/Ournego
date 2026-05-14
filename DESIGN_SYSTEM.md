# Design System

Este documento describe el sistema visual real implementado en Ournego. No propone una identidad nueva: registra tokens existentes, componentes compartidos, patrones repetidos y excepciones detectadas en el codigo actual.

## 1. Design Philosophy

Ournego usa una identidad visual luminosa, suave y local-first: superficies redondeadas, colores aqua/menta, fondos animados organicos, componentes con borde sutil y un mascot procedural (`NegoAvatar`) como elemento de marca. La app favorece interfaces centradas, amigables y de baja friccion para onboarding/auth, y una experiencia mas utilitaria sobre mapa para discovery y negocios.

El lenguaje visual existente se logra con:

- Paleta principal aqua/menta/verde oscuro definida en `OurnegoColorTokens`.
- Superficies claras translúcidas sobre fondos animados en auth, onboarding y formularios.
- Radius alto (`30`) para contenedores, inputs y elementos tipo pill.
- Iconografia Material redondeada (`Icons.*_rounded`) como lenguaje dominante.
- Motion suave y expresivo en onboarding, `NegoAvatar`, bottom navigation y floating sheets.

Debe evitarse cambiar por pantalla a un estilo duro, angular, sobrio corporativo o con colores fuera de la familia aqua/menta, salvo en categorias de mapa o estados semanticos ya existentes.

## 2. Visual Principles

- Jerarquia visual: titulos grandes y simples (`32` en onboarding, `24` en pantallas normales), cuerpo de `16`, acciones principales con altura `50-60`.
- Uso del espacio: pantallas introductorias centradas, con max width `500`; pantallas de formulario usan scroll y padding amplio (`28-32`).
- Color: primario aqua para accion y seleccion; verde/menta para marca y mascota; superficies `surface` con transparencias; texto principal en `noche` o `onSurface`.
- Densidad: onboarding/auth son aireados; mapa y floating sheet son mas densos, con controles compactos y listas.
- Tarjetas: normalmente redondeadas, con fondo `surface` translúcido o solido, borde `outline` alpha `0.3`, y sombra solo en elementos flotantes.
- Redondeo: predominan `30`, `24`, `18`, `14`, `12`, `8` y circular completo.
- Iconografia: Material Icons, preferentemente rounded, con iconos grandes en onboarding/cards y compactos en controles.
- Interaccion: feedback visual por escala, opacity/slide, selected circles, loading spinners y cambios de icono.

## 3. Color System

### Tokens base implementados

Definidos en `lib/core/theme/tokens/ournego_color_tokens.dart` y expuestos por `lib/core/ournego_colors.dart`.

| Token | Hex | Uso actual | Usar para | No usar para |
| --- | --- | --- | --- | --- |
| `OurnegoColorTokens.azulCielo` / `OurnegoColors.azulCielo` | `#3BCFED` | `ColorScheme.primary`, botones primarios, ojos de `Nego`, background de nav seleccionado | Acciones primarias, seleccion, acento principal | Texto pequeno sobre blanco sin revisar contraste |
| `cianClaro` | `#D8F7FD` | `primaryContainer` light | Fondos suaves relacionados con primary | Bordes o texto principal |
| `azulVerde` | `#009ABE` | pressed state de botones primarios, particles, `onPrimaryContainer` | Estado presionado, acento secundario azul | Reemplazar `primary` por defecto |
| `aguamarina` | `#7EEFC2` | `secondary`, blobs de fondo, stroke de Nego | Acciones secundarias positivas/branded | Errores o estados destructivos |
| `verdeMenta` | `#DFFDF1` | `secondaryContainer`, face fill/glow de Nego | Fondos menta suaves, marca | Texto primario |
| `mentaOscuro` | `#3EBF89` | `secondary` dark, particles | Acentos menta en dark/motion | Superficies principales |
| `verdeCastleton` | `#055F46` | `tertiary`, `onSecondary`, blob oscuro, marcador de ubicacion | Texto sobre menta, marcador user location, acento verde oscuro | Fondos grandes sin contraste |
| `verdeBrunswick` | `#034E3A` | `primaryContainer` dark | Contenedores oscuros en dark mode | Estado de error |
| `noche` | `#161616` | texto/foreground, scaffold dark | Texto oscuro, botones neutrales claros | Superficie clara general |
| `blanco` | `#FFFFFF` | scaffold light, foreground dark-mode neutral button | Fondo/base light, texto sobre oscuro | Borde o estado semantico |

### ThemeData y ColorScheme

`lib/core/theme/ournego_theme.dart` define:

- Light:
  - `primary #3BCFED`
  - `onPrimary #FFFFFF`
  - `primaryContainer #D8F7FD`
  - `onPrimaryContainer #009ABE`
  - `secondary #7EEFC2`
  - `onSecondary #055F46`
  - `secondaryContainer #DFFDF1`
  - `tertiary #055F46`
  - `surface #F4FBF9`
  - `onSurface #161616`
  - `error #BA1A1A`
  - `scaffoldBackgroundColor #FFFFFF`
- Dark:
  - `primary #3BCFED`
  - `onPrimary #161616`
  - `primaryContainer #034E3A`
  - `onPrimaryContainer #D8F7FD`
  - `secondary #3EBF89`
  - `onSecondary #161616`
  - `secondaryContainer #055F46`
  - `surface #1E2625`
  - `onSurface #E1E3E1`
  - `outline #89938F`
  - `scaffoldBackgroundColor #161616`

### Surface, border and transparency patterns

Implemented and repeated:

- `colorScheme.surface.withValues(alpha: 0.5)` for `OurnegoContentContainer` and input fills.
- `colorScheme.surface.withValues(alpha: 0.6-0.7)` for auth buttons and input decoration variants.
- `colorScheme.outline.withValues(alpha: 0.3)` for standard borders.
- `colorScheme.outline.withValues(alpha: 0.25-0.35)` for dividers, chips and badges.
- `colorScheme.inverseSurface.withValues(alpha: 0.07-0.12)` for tonal action tiles/cards.

### State and semantic colors currently hardcoded

- Error: `Theme.of(context).colorScheme.error #BA1A1A` exists, but many widgets use `Colors.red`.
- Warning: `Colors.orange` in business image requirement.
- Location/map pin: `Colors.red` and `Colors.redAccent`.
- Rating: `Colors.amber`.
- Feedback dialog: `Colors.red` bug, `Colors.blue` question.
- Profile fallback: `Colors.grey.withAlpha(127)` and `Colors.grey`.
- Overlay: `Colors.black` with alpha `0.35-0.5`.

### Gradients and special colors

`DiscoverOnboardingScreen` has a custom glowing orb with hardcoded colors:

- `_orbBase #009ABE`
- `_orbSoft #66EAFF`
- `_orbDeep #006F8F`
- `_orbDarkEdge ARGB(255, 0, 106, 145)`
- `_orbShadow ARGB(255, 0, 104, 149)`
- highlight/core colors `#E6FFFF`, `#82F4FF`, `#8CF6FF` plus white/transparent alphas.

These are implemented as a custom onboarding visual, not general app tokens yet.

### Category marker colors

`BusinessMarkerUiMapper` maps business categories to Material colors and ARGB foregrounds. These are part of the map visual language, but not tokenized. Keep them scoped to map/category markers until formalized.

## 4. Typography System

No custom font family is configured in `pubspec.yaml`; the app uses Flutter/Material default typography. `assets/fonts/MyIcons.ttf` exists but is not registered as a Flutter font and `MyIcons.google` is not used by app code.

### Implemented text styles

Defined in `lib/core/ournego_text_styles.dart`:

- `OurnegoTextStyles.onboardingHeader`: `fontSize: 32`, `fontWeight: FontWeight.bold`.
- `OurnegoTextStyles.header`: `fontSize: 24`, `fontWeight: FontWeight.bold`.
- `OurnegoTextStyles.body`: `fontSize: 16`.
- `OurnegoTextStyles.link`: `fontSize: 16`, underline.
- `OurnegoTextStyles.errorText`: `fontSize: 16`, `Colors.red`.

### Repeated inferred styles

- Compact labels/list metadata: `body.copyWith(fontSize: 12)`.
- Small action tile labels: `TextStyle(fontSize: 10)`.
- Floating sheet description: `fontSize: 15`, `height: 1.35`.
- Floating sheet names: `fontSize: 22`, `fontWeight: FontWeight.w700`.
- Buttons sometimes use `body` (`16`) and sometimes `header` (`24`) for large CTA labels.
- Badges use `fontSize: 11`, `fontWeight: FontWeight.w600`.

### Usage rules

- Use `onboardingHeader` only for first-run onboarding hero copy.
- Use `header` for page titles, major CTA labels and important card titles.
- Use `body` for instructions, form labels and descriptions.
- Use `link` only for tappable text links, not for secondary body emphasis.
- For compact map/list UI, prefer `body.copyWith(fontSize: 12 or 14)` until compact text tokens exist.

## 5. Spacing System

Formal tokens live in `lib/core/theme/tokens/ournego_spacing_tokens.dart`:

| Token | Value | Current usage |
| --- | ---: | --- |
| `xxs` | `4` | Tiny gaps, future-ready |
| `xs` | `8` | Card internals, chip/action gaps |
| `sm` | `12` | Common component gaps |
| `md` | `16` | Section internal spacing |
| `lg` | `24` | Section spacing |
| `xl` | `32` | Information card padding |
| `xxl` | `48` | Large vertical breathing space |

### Repeated hardcoded spacing patterns

- `8`: icon/text gaps, chip gaps, action button gaps.
- `10`: label-to-input spacing, compact content gaps.
- `12`: dialog/action row gaps, role card internals.
- `14`: floating sheet padding and search overlay padding.
- `16`: form label-to-input gap, map overlay padding, button icon gap.
- `18`: auth/onboarding horizontal padding, responsive container padding.
- `20`: dialog action padding.
- `24`: section spacing in onboarding/business forms.
- `28`: standard onboarding/layout padding and `OurnegoContentContainer` desktop horizontal padding.
- `30`: auth/form vertical gaps.
- `32`: register business screen padding and information card padding.
- `48`: large onboarding/form gaps.
- `56`: button heights and hours picker header height.
- `72`: bottom nav height, onboarding top spacing.
- `90-120`: large page layout offsets and map nav clearance.

### Layout spacing rules

- New feature screens should start with existing tokens where possible.
- Use `24` for section-to-section spacing.
- Use `16` for label/input and image/button adjacency.
- Use `8-12` for inline icon/text and controls.
- Use `28-32` for page padding when matching existing full-screen forms.
- Avoid introducing new arbitrary values unless tied to a responsive calculation.

## 6. Radius System

Formal tokens in `lib/core/theme/tokens/ournego_radius_tokens.dart`:

| Token | Value | Usage |
| --- | ---: | --- |
| `sm` | `8` | Small icon/control buttons |
| `md` | `12` | Action tiles, minimized sheet icons |
| `lg` | `14` | Image thumbnails and inner cards |
| `xl` | `30` | Inputs, content containers, large cards |
| `full` | `1000` | Avatars/circles |

### Implemented and repeated radii

- `30`: `OurnegoContentContainer`, inputs, search/top bar items, role cards, business image/map selector.
- `24`: neutral primary button default, search overlay container.
- `18`: floating business sheet and comparison sheets.
- `16`: map control buttons.
- `14`: floating sheet images/cards/wide buttons.
- `12`: action tiles, minimized stack icon, compact action buttons.
- `10`: compact dropdowns.
- `8`: sheet control icon buttons.
- `999/1000`: badges/pills and circular profile avatar.

Usage rule: do not invent new radius levels. Pick the nearest existing level and document exceptions.

## 7. Elevation, Shadows and Depth

The app is mostly flat. Depth is reserved for floating UI above map or navigation.

### Implemented shadows/elevation

- `OurnegoPrimaryButton`: elevation `0`.
- `OurnegoNeutralPrimaryButton`: default elevation `6`.
- Auth filled surface button: elevation `2`.
- Circular surface buttons and tonal card buttons: elevation `0`.
- Bottom navigation: `BoxShadow(color: #26000000, blurRadius: 10, spreadRadius: 0.2)`.
- Map controls: `Material` elevation `5`, `shadowColor: Colors.black alpha 0.2`.
- Floating sheets: black alpha `0.35`, `blurRadius: 24`, `spreadRadius: -4`, `offset: Offset(0, 8)`.
- User location marker: green shadow alpha `150`, `spreadRadius: 1`, `blurRadius: 5`.
- `AnimatedBackground`: blurred colored circles with `ImageFilter.blur` sigma `80`.
- `OurnegoContentContainer` optional blur: `BackdropFilter` sigma `10`.
- `NegoAvatar`: glow via `MaskFilter.blur` `40 * scale`, happy pulse blur `8 * scale`.

### Depth logic

- Background depth comes from animated blurred blobs/particles.
- Content containers usually stay flat with border, not shadow.
- Navigation and map controls float with shadow because they sit above map content.
- Dialogs use transparent `Dialog`/`AlertDialog` plus blurred `OurnegoContentContainer`.

## 8. Layout Patterns

### Global app shell

- `MaterialApp.router` uses `OurnegoColors.lightTheme` and `darkTheme`.
- Main authenticated shell uses `StatefulShellRoute.indexedStack`.
- `MainLayoutScreen` sets `extendBody: true`, `resizeToAvoidBottomInset: false`, and animates branch changes with opacity `0.75 -> 1` and horizontal offset `8 -> 0` over `220ms`.

### Auth/layout wrapper

`OurnegoPageLayout`:

- `Scaffold` with `Stack`.
- `AnimatedBackground` behind content.
- Centered `ConstrainedBox(maxWidth: 500)`.
- Default padding `horizontal: 30`, `vertical: 120`.
- `resizeToAvoidBottomInset` defaults false.

Use this for centered auth-style pages.

### Onboarding

- `Scaffold` surface background plus `AnimatedBackground`.
- Centered `PageView` with max width `500`.
- Shared `NegoAvatar` overlays page content and interpolates size/alignment/offset.
- `OnboardingResponsiveLayout` uses `SafeArea`, padding `28` by default, and switches to scroll below height `680-720`.

### Map

- `MapScreen` is a `Scaffold`/`Stack`.
- `MapCanvasWidget` is the base layer.
- `TopNavigationBarWidget` floats at `fromLTRB(16, 40, 16, 0)`.
- Search overlay appears below measured top bar height.
- Map controls float as a vertical column.
- `OurnegoFloatingSheet` floats from bottom with dynamic collapsed/expanded heights and max width.
- Bottom nav overlays the map body.

### Business form

- `Scaffold`/`Stack` with `AnimatedBackground`.
- `Padding(all: 28)`.
- `ListView` form with centered labels, `OurnegoInputField`, dividers, image preview, map selector, dropdowns and submit button.

## 9. Component System

### Primary button

- Class: `OurnegoPrimaryButton` in `lib/shared/widgets/ournego_buttons.dart`.
- Visual: full-width default, min size `double.infinity x 50`, primary background, pressed `azulVerde`, foreground `noche`, elevation `0`.
- Use for primary submit/continue actions in auth and location onboarding.
- Avoid custom primary buttons unless a feature already uses Material `FilledButton` and needs Material defaults.

### Neutral primary button

- Class: `OurnegoNeutralPrimaryButton`.
- Visual: black-on-white or white-on-black depending brightness, min size `56` high, radius `24`, elevation `6`.
- Used in early onboarding CTAs.
- Use when CTA should feel branded and high contrast over animated backgrounds.

### Auth buttons

- `OurnegoButtonStyles.authOutlinedOnSurface`: `surface alpha 0.7`, outline alpha `0.3`, onSurface alpha `0.9`.
- `authFilledOnSurface`: white background, `noche` foreground, elevation `2`.
- Existing auth rows use icon/image left, centered text, `Spacer`s, height `50`.

### Circular surface buttons

- `OurnegoButtonStyles.circularSurface`: `CircleBorder`, min `52 x 52`, surface alpha default `0.6`, elevation `0`.
- Used in top map mic/profile controls.
- Icons are `26-40` depending content.

### Tonal card buttons

- `OurnegoButtonStyles.tonalCardButton`: inverseSurface alpha `0.12`, outline alpha `0.28`, radius passed by caller.
- Used inside floating sheet actions.

### Content container/card

- Class: `OurnegoContentContainer`.
- Visual: `surface alpha 0.5`, outline alpha `0.3`, border width `1`, radius default `30`, optional blur sigma `10`.
- Responsive padding:
  - width `< 360`: horizontal `14`, vertical `20`
  - width `< 420`: horizontal `18`, vertical `18`
  - otherwise: horizontal `28`, vertical `24`
- Use for auth cards, information dialogs, role cards and branded prompt containers.
- Avoid nesting multiple card-like surfaces unless one is a real dialog/action region.

### Information card

- Class: `InformationCardWidget`.
- Visual: image asset `250` high, centered `header` title, body description at onSurface alpha `0.7`, padding `32`, bottom breathing space `48`.
- Can be wrapped in `OurnegoContentContainer` or rendered flat.
- Used for coming-soon, location/map errors and informational dialogs.

### Inputs

- Class: `OurnegoInputField`; helper `OurnegoInputDecorations.filled`.
- Visual: filled `surface alpha 0.5`, radius `30`, enabled outline alpha `0.3`, focused outline width `1.2`.
- Use `OurnegoLabeledInputSection` for label + input with default spacing `10`.
- Avoid plain `TextFormField` for new app forms.

### Search bars

- Top map search: `SearchBar` inside `_CrystalItemContainer`, min height `52`, background `surface alpha 0.35`, elevation `0`, leading search icon.
- Floating catalog search: height `42`, background `surface alpha 0.85`, leading icon `18`.
- Search overlay dropdowns: height `32`, radius `10`, border outline alpha `0.3`.

### Chips and badges

- `FilterChip` for search filter "Abiertos", compact density.
- Floating sheet type/rating badges: pill radius `999`, padding `horizontal 8-10`, `vertical 4`, primary alpha `0.14` or inverseSurface alpha `0.08`, border outline alpha `0.35`, text `11/600`.

### Cards and sheets

- Floating sheet: surface background, radius `18`, border outline alpha `0.3`, shadow black alpha `0.35`, padding `14/12/14/14`.
- Comparison cards use the same sheet styling.
- Inner action/contact/catalog cards: inverseSurface alpha `0.1`, radius `14`, border outline alpha `0.28`, padding `12`.
- Action tiles: radius `12`, padding `10`, inverseSurface alpha `0.07`, border alpha `0.12`.

### Navigation bar

- Class: `AppNavigationBar`.
- Visual: transparent `BottomAppBar`, fixed height `72`, outer margin `fromLTRB(48, 0, 48, 4)`, pill radius `100`, surface fill, outline alpha `0.3`, subtle shadow.
- Wide screens cap width at `400`.
- Selected item: circular fill primary, icon color surface, icon size `40`; unselected icon size `38`, onSurface.

### Top map navigation

- Class: `TopNavigationBarWidget`.
- Visual: horizontal row with circular mic, search, circular profile/login. Each item has surface fill, border outline alpha `0.3`, radius `30`.
- Voice listening state changes icon from `mic_none_rounded` to `mic_rounded` and color to primary.

### Dialogs and bottom sheets

- `OurnegoAlertDialog`: wraps transparent `AlertDialog` in blurred `OurnegoContentContainer`, constrained `300 x 400`.
- `OurnegoInformationDialog`: transparent `Dialog`, max width default `460`, content as `InformationCardWidget` plus action row.
- Location errors in `MapScreen` use `showModalBottomSheet` with `InformationCardWidget` and action row.
- Feedback uses raw `AlertDialog` with `ListTile`s and Material default styling.

### Empty, loading and error states

- Empty/coming-soon: `InformationCardWidget`.
- Loading: `CircularProgressIndicator(strokeWidth: 2)` for inline/auth states; `LinearProgressIndicator(minHeight: 2)` for search results.
- Error: `OurnegoSnackbars.error`, `OurnegoAlertDialog`, `OurnegoInformationDialog`, and some inline red text/icons.

## 10. Iconography

Icon library: Flutter Material Icons. Common style is rounded:

- Navigation: icons from navigation datasource, large `38-40`.
- Map controls: `22`.
- Top bar mic: `26`; profile fallback: `40`.
- Floating sheet controls: `18`; action tiles: `22`; wide action buttons: `24`.
- Onboarding role cards: large `72`.
- Information fallback icon: `Icons.info_outline`, size `96`.
- Location/error icons: `48-72`.

Rules:

- Prefer `Icons.*_rounded` where available.
- Pair icons with text in action buttons unless the control is a known map/navigation affordance.
- Use custom image asset for Google login (`assets/images/google.png`) instead of `MyIcons.google`.
- Use category icons only through `BusinessMarkerUiMapper`.

## 11. Imagery and Media

### Assets in use

- Brand: `assets/images/ournego.png`, `ournego_white.png`, `ournego_logo.png`.
- Auth provider: `assets/images/google.png`.
- Empty/error illustrations: `generic_error.png`, `location_error.png`, `waiting_clock.png`, `waiting_telescope.png`, `register_business.png`.
- Map attribution: `mapbox-logo-black.png`, `mapbox-logo-white.png`.
- Icons/app assets under `assets/icons/`.

### Treatment

- Brand logo switches between dark/light asset based on platform brightness.
- Information cards use asset image height `250`, centered, with icon fallback.
- Profile images are circular with radius `1000`, size `150 x 150`.
- Business images:
  - Upload preview: height `300`, full width, radius `30`, `BoxFit.cover`.
  - Floating sheet carousel: `180 x 180`, radius `14`, `BoxFit.cover`.
  - Minimized stack icon: `48 x 48`, radius `12/11`, `BoxFit.cover`.
- Map tiles fill available map canvas; map attribution logos are small and semi-transparent.

## 12. Motion and Animation

### Formal motion tokens

`lib/core/ournego_motion.dart`:

- `kEaseOutExpo = Cubic(0.16, 1.0, 0.3, 1.0)`.
- `kSheetTransitionDuration = 420ms`.

### Implemented motion patterns

- Floating sheet: `AnimatedSwitcher`, `AnimatedPositioned`, `AnimatedOpacity`, `AnimatedScale`, `AnimatedContainer`; duration `420ms`, curve `kEaseOutExpo`.
- Map controls: pressed scale `0.94` over `140ms`.
- Main shell branch switch: opacity/translate over `220ms`, `Curves.easeInOut`.
- Bottom nav selected item: `TweenAnimationBuilder`, `120ms`, `Curves.easeOut`, scale + circle fill.
- Auth/onboarding route from onboarding: slide up transition `450ms`, reverse `300ms`, `Curves.easeOutCubic`.
- Onboarding pages: page animation `600ms`, `Curves.easeOutQuart`.
- Onboarding back arrow: opacity `220ms`, `Curves.easeOut`.
- Exit onboarding: title/description slide+fade `1000ms`, `Cubic(0.22, 1, 0.36, 1)`, timers at `300ms`, `900ms`, finish at `3200ms`.
- Discover orb: custom 28-second repeating animation.
- Animated background blobs: position changes every `4s`, `Curves.easeInOut`, blur sigma `80`.
- Animated particles: continuous long-running controller, paused by route/lifecycle.
- Business hours picker: `AnimatedCrossFade` `200ms`.
- Address focus scroll: `300ms`, `Curves.linear`.
- Map animateTo curves include `Curves.easeIn`, `Curves.bounceInOut`.

### Nego motion

`NegoTokens` defines:

- Idle float `3200ms`, active float `2200ms`.
- Eye transitions `180-280ms`.
- Motion transition `220ms`, glow `350ms`.
- Happy pulse `650ms`, temporary happy `850ms`.
- Blink close `60ms`, open `120ms`, hold `60ms`, random delay `1400-5000ms`.
- Curves: `easeInOut`, `easeOut`, `Cubic(0.16, 1.0, 0.3, 1.0)`.

Respect `TickerMode` and `MediaQuery.disableAnimationsOf(context)` patterns when adding motion.

## 13. Interaction States

- Default: surface fill, onSurface text/icon, subtle outline.
- Pressed: primary buttons switch from `azulCielo` to `azulVerde`; map controls scale to `0.94`.
- Focused: inputs increase border width to `1.2`; focus color is outline/onSurface depending widget.
- Disabled: Material disabled state is used implicitly for null `onPressed`; no custom disabled token exists.
- Selected: bottom nav uses primary circular fill; search filter chip uses Material selected state; favorite uses primary alpha background and primary icon.
- Active/listening: mic icon changes and primary color is applied.
- Loading: spinner inside button or inline row; search overlay uses thin linear progress.
- Success: business upload button icon switches from upload to check; snackbar text/info is used for success.
- Error: red text/icons, error snackbar, alert/information dialog with generic error image.
- Empty: information card or search overlay text.

## 14. Forms and Inputs

Form pattern:

- Centered question/label in `OurnegoTextStyles.body`.
- `SizedBox(height: 10 or 16)` before input.
- `OurnegoInputField` for text fields.
- `SizedBox(height: 24 or 30)` between sections.
- Primary submit action at end.

Input details:

- Radius `30`.
- Filled surface alpha `0.5`.
- Enabled border outline alpha `0.3`.
- Focused border outline full/alpha with width `1.2`.
- Error border uses `colorScheme.error` in theme input style, but `OurnegoInputField` does not explicitly override error border.
- Hints sometimes use `body` with onSurface alpha via `withAlpha(150)` or `withValues(alpha: 0.6)`.
- Prefix/suffix icons are allowed through `icon` and `suffixIcon`.
- Password rules use small `Icons.check` or `Icons.panorama_fish_eye`, size `12`, red for unmet rules.

Dropdown pattern:

- `DropdownButtonFormField` uses `OurnegoInputDecorations.filled`.
- Compact map dropdowns use custom containers instead of form field decoration.

## 15. Navigation Design

### Bottom navigation

- Three primary branches: community, map, business panel/register.
- `AppNavigationBar` is a floating pill over the body.
- Selected state is visual-only circular fill; no labels.
- Wide layout keeps nav at width `400`.

### App bars and top bars

- Standard `AppBar` is only used in debug panel.
- Map uses a custom top navigation bar, not Material `AppBar`.
- Auth/onboarding pages usually have no app bar; onboarding uses a conditional back arrow.

### Route transitions

- Most shell/map routes use `NoTransitionPage`.
- Auth selection from onboarding slides up.
- Main shell branch changes use subtle opacity/translate.

### Back patterns

- Onboarding back arrow visible only on pages `1..totalPages-2`.
- Dialogs/bottom sheets close with `Navigator.pop`.
- Auth completion often pops when possible, otherwise navigates to `MapRoutes.map`.

## 16. Screen Patterns

### Onboarding

Structure: animated background, max-width page view, big title `32`, `NegoAvatar` overlay, large neutral/primary CTA, responsive scroll fallback. Use custom animated visuals only if they reinforce discovery/location/role selection and respect reduced motion.

### Auth selection

Structure: animated background, centered `OurnegoContentContainer`, logo, title, stacked auth buttons, terms rich text. Buttons are height `50`, full width, with icon + centered label.

### Email auth forms

Structure: `OurnegoPageLayout`, header at top, spacer, content container with form fields, primary button, bottom link if needed.

### Map/home discovery

Structure: full-screen map, floating top search/profile/mic controls, optional search overlay, floating map controls, bottom navigation, and business floating sheet. New map UI should integrate into this stack and account for top/nav measured heights.

### Business detail/floating sheet

Structure: floating surface card, drag handle, category/rating badges, control icon buttons, title, collapsed action row or expanded scroll content. Use radius `18`, shadow black alpha `0.35`, padding `14`.

### Business registration CTA

Structure: centered `NegoAvatar`, title/body, secondary-colored CTA button. Map promo variants use `OurnegoContentContainer` plus compact `NegoAvatar`.

### Business form

Structure: animated background, `ListView`, centered questions, fields, upload button/preview, map selector card, category dropdown, hours picker, submit. It is a dense vertical wizard-like form rather than one card wrapping the full page.

### Empty/coming soon

Structure: `InformationCardWidget`, usually in `SafeArea` with `SizedBox.expand`. Community uses flat version; business panel wraps in content container by default.

### Feedback

Structure: Material `AlertDialog` with two `ListTile` options. Visual style is less custom than the rest of the app.

## 17. Do and Don't

### Do

- Use `OurnegoColorTokens`, `OurnegoColors`, `Theme.of(context).colorScheme`, `OurnegoSpacingTokens` and `OurnegoRadiusTokens`.
- Reuse `OurnegoPrimaryButton`, `OurnegoNeutralPrimaryButton`, `OurnegoInputField`, `OurnegoContentContainer`, `InformationCardWidget` and `OurnegoInformationDialog`.
- Keep large surfaces rounded (`30`) and bordered with outline alpha around `0.3`.
- Use `AnimatedBackground` for auth/onboarding/form-like branded screens.
- Use Material rounded icons and existing icon sizes.
- Match map UI density when working inside `MapScreen`.
- Respect dark mode by using `colorScheme`, not hardcoded black/white.

### Don't

- Do not hardcode new brand colors.
- Do not introduce new radius values when an existing token/value fits.
- Do not add shadows to normal content cards without a clear floating-layer reason.
- Do not mix unrelated visual styles by feature.
- Do not create new custom text scales before checking `OurnegoTextStyles`.
- Do not use non-rounded/outlined icon styles inconsistently unless Material only offers that icon.
- Do not place new map controls without checking overlap with top bar, bottom nav and floating sheet.

## 18. AI Interface Generation Rules

When an AI agent creates or modifies Ournego UI:

1. Read this document first.
2. Inspect the closest existing screen/component before editing.
3. Prefer shared widgets over new styling.
4. Use existing color, spacing and radius tokens where possible.
5. Do not invent colors, fonts, shadows or motion curves.
6. If a repeated value is missing as a token, mention it as a candidate before adding a new magic number.
7. Keep `OurnegoContentContainer` as the default card/surface primitive.
8. Keep form fields on `OurnegoInputField`.
9. Keep primary actions on `OurnegoPrimaryButton` or the feature's existing Material button pattern.
10. For map UI, account for `TopNavigationBarWidget`, `AppNavigationBar`, search overlay and floating sheet.
11. For onboarding, respect `MediaQuery.disableAnimationsOf(context)` and `TickerMode`.
12. Explain which tokens/components were reused in the implementation summary.

## 19. Current Inconsistencies

- `lib/core/theme/ournego_button_styles.dart` defines theme button styles, but `OurnegoTheme` does not apply `elevatedButtonTheme`, `outlinedButtonTheme` or input theme.
- There are two `OurnegoButtonStyles` classes: one in `lib/core/theme/ournego_button_styles.dart` and one in `lib/shared/widgets/ournego_buttons.dart`.
- `OurnegoTextStyles.errorText` and many screens use `Colors.red` instead of `colorScheme.error`.
- `OurnegoTextStyles` has only five styles; compact labels (`10/11/12/14/15`), sheet titles (`22/700`) and button labels are hardcoded.
- Spacing tokens exist, but many screens use hardcoded `10`, `14`, `18`, `20`, `28`, `30`, `56`, `72`, `108`, `120`.
- Radius tokens exist, but many components hardcode `30`, `24`, `18`, `16`, `14`, `12`, `10`, `8`, `999`.
- `OurnegoInputStyles.inputDecorationTheme` exists but is not wired into `ThemeData`; `OurnegoInputField` repeats much of the decoration manually.
- Feedback dialog uses raw Material `AlertDialog` and `ListTile` styling, unlike `OurnegoInformationDialog`.
- Some buttons use `ElevatedButton`, some `FilledButton`, some custom shared buttons, with inconsistent heights/foreground colors.
- Top navigation `_CrystalItemContainer` uses `BackdropFilter` with blur sigma `0`, so it is visually just a bordered surface.
- Business form map style selection appears inverted by variable name: `isDarkModeOn ? styleIdLight : styleIdDark`.
- `pubspec.yaml` includes `assets/fonts/MyIcons.ttf` as a file asset but not as a registered font; `MyIcons.google` is unused.
- Category marker colors are hardcoded Material colors, not semantic/category tokens.
- Status colors (`orange`, `amber`, `redAccent`, `grey`) are hardcoded.

## 20. Recommended Future Tokens

Only based on repeated existing patterns:

- `AppSpacing.xxxs = 6` only if action tile label gaps remain common; otherwise keep `xs`.
- `AppSpacing.formLabelGap = 10`.
- `AppSpacing.controlGap = 8`.
- `AppSpacing.section = 24`.
- `AppSpacing.formSection = 30`.
- `AppSpacing.pagePadding = 28`.
- `AppSpacing.pagePaddingLarge = 32`.
- `AppRadius.input = 30`.
- `AppRadius.contentContainer = 30`.
- `AppRadius.sheet = 18`.
- `AppRadius.innerCard = 14`.
- `AppRadius.actionTile = 12`.
- `AppRadius.iconButton = 8`.
- `AppRadius.pill = 999`.
- `AppColors.surfaceSoft = colorScheme.surface alpha 0.5`.
- `AppColors.surfaceRaised = colorScheme.surface`.
- `AppColors.borderSubtle = outline alpha 0.3`.
- `AppColors.borderMuted = outline alpha 0.25`.
- `AppColors.tonalSurface = inverseSurface alpha 0.1`.
- `AppColors.warning = Colors.orange` replacement.
- `AppColors.rating = Colors.amber` replacement.
- `AppColors.locationPin = Colors.red/Colors.redAccent` replacement.
- `AppShadows.navigation = #26000000 blur 10 spread 0.2`.
- `AppShadows.mapControl = black alpha 0.2 elevation 5`.
- `AppShadows.floatingSheet = black alpha 0.35 blur 24 spread -4 offset 0,8`.
- `AppMotion.fast = 120-140ms easeOut`.
- `AppMotion.standard = 220ms easeInOut/easeOut`.
- `AppMotion.sheet = 420ms kEaseOutExpo`.
- `AppMotion.onboardingPage = 600ms easeOutQuart`.
- `AppTextStyles.compact = 12`.
- `AppTextStyles.badge = 11/600`.
- `AppTextStyles.sheetTitle = 22/700`.
- `AppTextStyles.sheetBody = 15 height 1.35`.
- `AppCategoryColors.*` for `BusinessMarkerUiMapper`.

## 21. References

Theme and tokens:

- `lib/main.dart`
- `lib/core/ournego_colors.dart`
- `lib/core/ournego_text_styles.dart`
- `lib/core/ournego_motion.dart`
- `lib/core/theme/ournego_theme.dart`
- `lib/core/theme/ournego_button_styles.dart`
- `lib/core/theme/ournego_input_styles.dart`
- `lib/core/theme/tokens/ournego_color_tokens.dart`
- `lib/core/theme/tokens/ournego_spacing_tokens.dart`
- `lib/core/theme/tokens/ournego_radius_tokens.dart`

Shared visual widgets:

- `lib/shared/widgets/animated_background.dart`
- `lib/shared/widgets/animated_particles.dart`
- `lib/shared/widgets/ournego_buttons.dart`
- `lib/shared/widgets/ournego_inputs.dart`
- `lib/shared/widgets/ournego_content_container.dart`
- `lib/shared/widgets/ournego_page_layout.dart`
- `lib/shared/widgets/information_card_widget.dart`
- `lib/shared/widgets/ournego_alert_dialog.dart`
- `lib/shared/widgets/ournego_information_dialog.dart`
- `lib/shared/widgets/ournego_snackbars.dart`
- `lib/shared/widgets/nego/README.md`
- `lib/shared/widgets/nego/nego_avatar.dart`
- `lib/shared/widgets/nego/nego_tokens.dart`
- `lib/shared/widgets/nego/nego_painter.dart`
- `lib/shared/widgets/nego/nego_motion_controller.dart`

Representative screens/components:

- `lib/features/onboarding/presentation/pages/onboarding_screen.dart`
- `lib/features/onboarding/presentation/pages/components/*.dart`
- `lib/features/auth/presentation/widgets/auth_selection_widget.dart`
- `lib/features/auth/presentation/pages/login_email_screen.dart`
- `lib/features/auth/presentation/pages/signup_email_screen.dart`
- `lib/features/auth/presentation/pages/create_password_screen.dart`
- `lib/features/auth/presentation/pages/complete_profile_screen.dart`
- `lib/features/map/presentation/pages/map_screen.dart`
- `lib/features/map/presentation/widgets/top_navigation_bar_widget.dart`
- `lib/features/map/presentation/widgets/map_canvas_widget.dart`
- `lib/features/map/presentation/widgets/map_controls_widget.dart`
- `lib/features/map/presentation/widgets/map_search_overlay_widget.dart`
- `lib/features/map/presentation/widgets/floating_sheet/ournego_floating_sheet.dart`
- `lib/features/map/presentation/widgets/floating_sheet/components/*.dart`
- `lib/features/map/presentation/mappers/business_marker_ui_mapper.dart`
- `lib/features/navigation/presentation/widgets/navigation_bar_widget.dart`
- `lib/features/navigation/presentation/pages/main_layout_screen.dart`
- `lib/features/business/presentation/widgets/register_business_widget.dart`
- `lib/features/business/presentation/pages/business_form_screen.dart`
- `lib/features/business/presentation/pages/components/business_hours_picker.dart`
- `lib/features/community/presentation/widgets/community_coming_soon_widget.dart`
- `lib/features/business/presentation/widgets/business_panel_coming_soon_widget.dart`
- `lib/features/feedback/presentation/widgets/feedback_dialog_widget.dart`
