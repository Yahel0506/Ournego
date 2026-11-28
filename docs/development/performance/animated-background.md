# Animated background performance (OUR-157)

`AnimatedBackground` (`lib/shared/widgets/animated_background.dart`) is the soft
drifting blob gradient behind the auth, onboarding and business form screens.
It made the app drop frames when a new screen opened. This page records what was
measured, what caused it and what changed.

## Cause

The old widget drew three colored circles and put a full-screen
`BackdropFilter(ImageFilter.blur(sigma: 80))` on top of them. A backdrop filter
has to read back and blur **everything painted below it**, every frame, at full
screen size. Combined with that:

- the three circles moved with `AnimatedPositioned` (layout + build every frame);
- there was no `RepaintBoundary`, so nothing was cached between frames;
- during a route push/pop or a dialog opening over a page, the blur kept
  re-running every frame (the frame-time numbers below point to this; the
  control run without the background confirms that the rest of the UI is not
  the part that changed).

On the test phone (below) the blur was the dominant cost, not the Dart side
(build time was already ~0.5-3 ms).

## Change

- The blur is **baked into each blob**: a small (160 px) image of a disc blurred
  with a Gaussian of `blurSigma` (numeric integral of the Gaussian over the
  disc), tinted with the blob color and opacity, rendered once with
  `Picture.toImageSync` and drawn scaled up with bilinear filtering. The look is
  the same soft blob (sigma `80` is still the default); only the cost moved from
  "every frame" to "once".
- One `AnimationController` drives a single `CustomPainter` (`repaint:` the
  animation). Nothing is rebuilt or re-laid-out per frame.
- The painter lives in its own `RepaintBoundary` + `IgnorePointer`.
- Same drift as before: new random centers every `kBackgroundDriftDuration`
  (4 s), `Curves.easeInOut`, starting from where the blobs currently are.
- The drift stops while the screen is covered by another route
  (`RouteAware`), while the app is in the background and with reduced motion
  (`MediaQuery.disableAnimations`). With reduced motion the blobs are now static
  *soft* blobs (before, they were hard-edged circles because the blur was
  switched off).

Rejected: a pre-recorded video or a static image (the procedural version is now
cheap enough, and keeps resolution independence and the drift), a lower frame
rate for the background only (the cost was not per drawn frame but the blur
during transitions), and per-frame multi-stop `RadialGradient` shaders: tried
first and measured *worse* than the blur on this GPU (idle raster ~20 ms,
about 3 full-screen-size gradient fills), which is why the blobs are images.

## Method

`tool/perf/background_bench.dart` is a small app that mounts the real
`OurnegoPageLayout`/`AnimatedBackground`, the blurred
`OurnegoContentContainer` and `OurnegoDialogSurface` (through the real
`showOurnegoDialog`), and runs a scripted route with no backend:

| Phase | What it does |
|---|---|
| `idle` | 12 s on one screen (three drift steps) |
| `push_pop` | 8 × push a page over the background, then pop it |
| `dialog` | 8 × open and close a dialog over the background |
| `page_swipe` | onboarding-style `PageView` swipe, 8 × 600 ms |

Frame numbers come from the engine's `FrameTiming` (build and raster time per
frame), the same data DevTools shows. The result is printed as one
`BENCH_RESULT {...}` JSON line. To repeat it:

```bash
flutter run --profile -d <device> -t tool/perf/background_bench.dart \
  --dart-define=BENCH_LABEL=<name> --dart-define-from-file=.env
# add --dart-define=BENCH_NO_BG=true for the control run without the background
```

(or `flutter build apk --profile -t ...`, install, launch, and read
`adb logcat -s flutter | grep BENCH_RESULT`). It always runs in profile mode;
debug numbers are meaningless.

Measured: 3 passes per variant, median of the passes. The screen was on and the
device idle between runs; nothing else of the user's was touched.

## Device

**Xiaomi M2103K19PG**, SoC MediaTek MT6833 (Dimensity 700), Android 13
(SDK 33), ~5.5 GB RAM, 1080x2400, display up to 90 Hz (the app rendered at
60 Hz in these runs). This is a mid/low-end phone. **Low-end verification was
done on this one device only**; a weaker or older phone was not available and could behave worse.

## Results (Xiaomi M2103K19PG, profile mode, median of 3 passes)

Frames "over 16.7 ms" are frames whose build+raster span exceeded the 60 Hz
budget. "No background" is a control: the same pages and glass without
`AnimatedBackground` (2 passes), i.e. the floor of the rest of the UI.

| Phase | Metric | Before | After | No background |
|---|---|---|---|---|
| idle | raster mean / p99 | 4.5 / 13.6 ms | 3.4 / 6.3 ms | – |
| idle | worst raster | 21.6 ms | 7.5 ms | – |
| idle | frames > 16.7 ms | 8 (one pass: 727, cold start) | 0 | – |
| push/pop | raster mean | 8.2 ms | 5.1 ms | 8.4 ms |
| push/pop | raster p90 | 15.1 ms | 9.0 ms | 16.5 ms |
| push/pop | raster p99 | 34.6 ms | 35.6 ms | 30.9 ms |
| push/pop | frames > 16.7 ms | 192 of 1,116 (17 %) | 108 of 1,137 (9.5 %) | 94 of 437 |
| dialog | raster mean | 10.2 ms | 8.5 ms | 7.7 ms |
| dialog | raster p99 | 23.3 ms | 21.1 ms | 23.5 ms |
| dialog | frames > 16.7 ms | 418 of 985 (42 %) | 193 of 754 (26 %) | 91 of 672 |
| page swipe | raster p99 | 21.5 ms | 16.6 ms | 16.6 ms |
| page swipe | frames > 16.7 ms | 19 of 657 | 16 of 661 | 13 of 351 |

(Frame counts differ between variants because a frame is only produced when
something changes; with the animated background something changes every frame.)

Build time was never the problem (p99 about 6 ms or less in all variants).

## Reading the numbers

- **Idle** is now clean: no frame over budget, worst raster 7.5 ms.
- **Dialogs**: frames over budget halved (418 → 193) and mean raster dropped
  from 10.2 to 8.5 ms.
- **Page push/pop**: mean raster 8.2 → 5.1 ms, p90 15.1 → 9.0 ms, frames over
  budget 17 % → 9.5 %.
- What is left in push/pop and dialogs is **not the background**: with the
  background removed the same pages show the same raster p99 (31 vs 35 ms) and a
  similar count of slow frames. Those frames come from the rest of the
  transition (page transition itself, the `hasBlur` content container with its
  sigma-10 `BackdropFilter`, and the dialog's container transform). The target
  of "60 FPS consistent" is therefore **not fully reached on this phone during
  transitions**, but the animated background is no longer a measurable part of
  the cost. A follow-up could look at those pieces (see below).
- Visual check: the old and new backgrounds were compared on screenshots from
  the phone; the blobs keep the same soft, diffuse look and colors. Up close the
  new one is smooth (no banding or grid from the upscaled sprites).

## Not verified

- Only one low/mid-range device; no weaker phone, no iOS, no Impeller-vs-Skia
  comparison beyond what the phone uses by default.
- The numbers come from the bench app, not from the real screens with real data
  (onboarding with Nego, business sheet, tab switch), which add their own cost
  on top; the background's share of it is what changed.
- Battery impact was not measured (expected lower: no per-frame blur).

## Follow-up candidates

The remaining slow frames during transitions come from other glass pieces
(`OurnegoContentContainer(hasBlur: true)`, page transitions, container
transform). Measure them with the same bench (the control run isolates them)
before changing anything.
