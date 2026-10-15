# Container transform

Windows that open from an element (menus, dialogs, popovers, sheets, detail
screens) grow out of that element and return to it when they close. The
reference is the container-transform spec; this document records what Ournego
adopted and where it differs. One card per preset lives next to this file; add
the card when a preset gets its first consumer.

## Character

Calm. Opening springs sit at zeta 0.85 to 0.90, closing springs are critically
damped (zeta 1). Flat glass never visibly overshoots in size: the transform
clock is bounded to [0, 1] (`P_MAX = 1`), so nothing grows past its destination.
The strong rebound of `kOurnegoSpring` stays exclusive to the lip buttons.

The one deliberate exception is the path. A window does not travel in a straight
line: its vertical position follows its own smooth curve over the whole path
(`kWindowVerticalPath`, `Cubic(0.5, 0.2, 0.7, 1.25)`). It leans ahead of the
horizontal position by up to about 20 % of the travel, passes its destination by
about 3.5 % at 90 % of the way and settles back with a gentle slope, while the
horizontal position and the size follow the plain route. It is one continuous
curve, not a kick, and the same curve is used to open and to close, so reversing
mid-way never jumps. `OurnegoSpringPreset.verticalPath` sets it, or removes it
(null).

## Pieces

| Piece | File | What it does |
| --- | --- | --- |
| Tokens | `lib/core/ournego_motion.dart` | `OurnegoSpringPreset` (spring, content window, scrim, blur) and one constant per preset |
| Windows | `lib/core/motion/motion_window.dart` | `seg(p, a, b, curve)`: each property reads the shared clock `p` through its own window |
| Level | `lib/core/motion/ournego_motion_level.dart` | `OurnegoMotion.resolveLevel`: B (blur), C (no blur) or R (reduced motion); the global switch |
| Clock in the tree | `lib/core/motion/spring_clock.dart` | Interruptible spring clock for surfaces that are not routes (search panel, floating sheet) |
| Trigger | `shared/widgets/container_transform/container_transform_origin.dart` | `ContainerTransformTrigger` measures the element, steps aside while its window exists and ignores touches meanwhile |
| Destination | `.../container_transform_destination.dart` | Marks the visible surface of a window; lays it out once at final size and grows a clip from the trigger |
| Route | `.../container_transform_route.dart` | `PopupRoute` whose clock is a `SpringSimulation` |
| API | `.../show_ournego_window.dart` | `showOurnegoDialog`, `showOurnegoMenu`, `showOurnegoPopover` |
| Handoff | `.../container_transform_origin.dart` | `ContainerTransformHandoff`: carries the rect of a tapped element (a menu item) to the window that follows |
| Popover | `.../container_transform_anchored_position.dart`, `shared/widgets/ournego_popover_surface.dart` | Places a small window below its anchor (flips above, never leaves the screen, start/end aware) and draws it on the flat glass with the small radius |

Open dialogs only with `showOurnegoDialog` / `showOurnegoMenu`;
`test/architecture/no_raw_dialogs_test.dart` rejects `showDialog`.

## Windows that start somewhere else

- **Static origin and return** (`showOurnegoDialog(staticOrigin:, returnOrigin:)`).
  A window can grow out of a rect that has no trigger behind it (an item of a
  menu that already closed) and, when it closes, go back to a different trigger
  (the button that opened the menu). While it closes, the return trigger steps
  aside as any trigger does; it is not hidden while the window opens.
- **Handoff.** The profile menu's items measure themselves when tapped
  (`ContainerTransformHandoff.capture`: rect, largest corner, brick color) and
  `openProfileMenu` passes the result to the next window. Feedback and the
  log-out confirmation grow out of the tapped brick and return to the profile
  button.
- **Popover** (`showOurnegoPopover`). Anchored-grow for chips, notices and other
  small windows: no scrim, the anchor steps aside, a tap outside closes it. The
  content goes in a `ContainerTransformAnchoredPosition` on an
  `OurnegoPopoverSurface` (flat glass, radius `lg` = 14, no blur: level C by
  design). The anchor is read once when it opens, so it does not jump while it
  closes. `kPopoverSpring` follows the same criteria as the dialog (open k 320,
  close k 380, content `[0.10, 0.45]`) without blur or vertical path.

## How a window opens

1. The trigger's rect, radius and color are measured once, when the route is
   created.
2. The route's controller is driven by `createSimulation`, so it starts from the
   current value and velocity on every push and pop. Closing half way through
   opening continues from where it was.
3. `p` drives, through its own window each: the container's rect (linear in `p`
   horizontally and in size, `kWindowVerticalPath` vertically; the spring is the
   rest of the curve), its radius (trigger radius to 24), its fill, the content's
   alpha and blur, and the scrim. The content travels with the container, with
   its center on the container's center, and the container's clip shows as much
   of it as fits; it is not revealed in place.
   The content appears early and **fully blurred**, with a static blur (12 dp,
   level B) that does not change while the container travels. Over the last
   stretch (`blurClearStart`, `p` from 0.62) the blur clears, slowly at first and
   faster toward the end (`easeInQuad`; the spring's tail is slow, so a linear
   fade would look sharp well before the container stops), and it is exactly 0
   when the container's animation ends (`p = 1`). Items respond to touches from
   `blurClearStart`.
4. The trigger is hidden (it keeps its layout) once the container covers it, at
   `p = 0.12`, and comes back at the same point on the way out.
5. The origin is measured again when closing starts. If the trigger is gone, the
   window shrinks around its own center instead.

A window that has no `ContainerTransformDestination` still fades in and out.

## Differences from the spec

- The trigger's icon is not drawn inside the growing container. The container
  fills in over the first 12 % of `p` (`seg(p, 0, 0.12)`) and the trigger steps
  aside at that point, which reads as the same dissolve.
- The vertical path is a curve with a small overshoot (the spec has a straight
  path), see Character above.
- The blur (level B) is applied to the whole content of the window, not to each
  item, and never to the surface itself (`ContainerTransformBlur` sits inside
  `OurnegoDialogSurface`), so the flat face and the contour stay crisp. It is
  static then clearing at the end, instead of easing out during the travel.
- No stagger in the account menu (decision D10).
- The future of `showOurnegoDialog` completes when the pop starts, like
  `showDialog`'s, so a caller can chain the next window while this one animates
  out.
- While a window closes, Flutter lets touches through the barrier; the trigger
  ignores them for as long as its window exists, so a quick second tap cannot
  stack another window. Reopening waits for the close (about 0.27 s).

## Reduced motion

`MediaQuery.disableAnimationsOf`, or the global switch turned off (debug panel):
no travel, scale or blur. The window appears at its final rect with a 120 ms
fade, and so does the scrim. The trigger is not hidden.

## Card: `dialog` preset

```
ANIMATION: dialog / account menu        TYPE: dialog (menu variant)
Trigger: profile button, 52 dp circle (radius 26) on the map, 44 dp (22) in the business panel
Destination strategy: center-expand; the content rides the container's center
Destination: measured, centered, max width 360 (menu) / 320 (alert) / 460 (information)
P_MAX: 1 (size and X); Y passes by ~3.5 % and settles

SPRING        k     zeta   ~ settle
  open       170   0.9     ~0.35 s
  close      185   1.0     ~0.4 s

LAYER / PROPERTY      FROM -> TO                      WINDOW (in p)   CURVE
  container rect X    trigger -> destination          g = clamp(p, 0, 1)   linear
  container rect Y    trigger -> destination (+3.5 %)  [0, 1]         kWindowVerticalPath
  container size      trigger -> destination          g               linear
  container radius    trigger radius -> 24            [0, 1]          easeOut
  container fill      trigger color -> surface        [0, 0.5]        easeOut
  container fill a    0 -> 1 -> 0                     [0, 0.12] then [0.45, 1]
  input               blocked until the blur starts to clear  p >= 0.62
  content position    rides the container's center    [0, 1]
  content alpha       0 -> 1                          [0.05, 0.30]    easeOut
  content blur        12 dp static, then 12 -> 0      [0.62, 1]       easeInQuad (level B only)
  scrim alpha         0 -> 0.30 (menu) / 0.50         [0, 0.6]        linear

CLOSE: the same curve and windows in reverse; its own spring (k 185, zeta 1)
REDUCED MOTION: final rect, 120 ms fade, no hiding of the trigger
BLUR LEVELS: B blur of content; C none (web); R fade only
FOCUS: Navigator restores focus to the previous node on close
EDGE CASES: interruption (velocity kept), trigger gone on close, keyboard (the
form dialog avoids it itself), no trigger (grows 0.92 -> 1 around its center)
```
