# UI Refactor Manual (Shared Styles & Presets)

## Purpose
This document is the implementation manual for the ongoing UI refactor that standardizes visual behavior across Ournego using reusable tokens, theme primitives, and shared widgets.

The objective is to avoid per-screen inline styling and move to a predictable, maintainable system with minimal visual drift.

## Scope and Current Status
- Refactor approach: incremental by feature, preserving existing UX and visual intent.
- Foundation completed: theme/tokens and shared style building blocks.
- Migration in progress: Auth, Business, Onboarding, Community, and Map (partial) now use shared presets in key paths.

## Design Rules
- Prefer reusable style presets over inline `styleFrom`, `InputDecoration`, `SnackBar`, and `AlertDialog` definitions.
- Keep visual changes conservative during migration; refactor structure first, then tune visuals in dedicated passes.
- Keep UI strings in Spanish and code comments in English (project convention).
- Use route constants for cross-feature navigation; avoid direct screen imports.

## Core Building Blocks

### Theme and Tokens
- `lib/core/theme/ournego_theme.dart`: centralized light/dark `ThemeData` and `ColorScheme`.
- `lib/core/theme/tokens/ournego_color_tokens.dart`: color token palette.
- `lib/core/theme/tokens/ournego_spacing_tokens.dart`: spacing scale (`xxs` to `xxl`).
- `lib/core/theme/tokens/ournego_radius_tokens.dart`: radius scale (`sm`, `md`, `lg`, `xl`, `full`).
- `lib/core/theme/ournego_input_styles.dart`: base `InputDecorationTheme`.

### Shared UI Presets
- `lib/shared/widgets/ournego_page_layout.dart`: common page scaffold/background/max width pattern.
- `lib/shared/widgets/ournego_inputs.dart`:
  - `OurnegoInputField`
  - `OurnegoLabeledInputSection`
  - `OurnegoInputDecorations.filled(...)`
- `lib/shared/widgets/buttons/` (barrel `buttons.dart`): `OurnegoButton`, `OurnegoIconButton`, `OurnegoSocialButton`, `OurnegoRowButton`, `OurnegoActionButton`/`OurnegoActionTile`, `OurnegoChip`, `OurnegoGlassIconButton`, `OurnegoGlassSurface`, `OurnegoGlassChip` and `OurnegoNavBar`. See `docs/development/design/BUTTONS_SPEC.md`.
- `lib/shared/widgets/ournego_snackbars.dart`: `OurnegoSnackbars.info(...)` and `OurnegoSnackbars.error(...)`.
- `lib/shared/widgets/ournego_alert_dialog.dart`: common alert with `primaryAction` + optional `secondaryAction` (`OurnegoDialogAction`).
- `lib/shared/widgets/ournego_information_dialog.dart`: image + description + action area dialog preset.

## Migration Workflow

### Phase 0 - Foundation
1. Introduce tokens and theme primitives.
2. Ensure app compiles and visuals stay equivalent.
3. Add base shared widgets for common controls.

### Phase 1 - Feature Migration (Current)
1. Pick a feature and identify repeated style patterns.
2. Replace inline styles with shared presets first.
3. Only add new shared presets when at least 2 call-sites justify reuse.
4. Validate with targeted analysis.

### Phase 2 - Consolidation
1. Remove dead/duplicated style code.
2. Align remaining edge cases to tokens.
3. Document adopted patterns in each feature README.

## How to Apply the Refactor in New Code
1. Start from shared widgets/tokens, not raw Material defaults.
2. For inputs, prefer `OurnegoInputField` or `OurnegoInputDecorations.filled(...)`.
3. For buttons, use the `lib/shared/widgets/buttons/` family and pick `tone`, `size` and `icon`; raw Material buttons are blocked by `test/architecture/no_raw_material_buttons_test.dart`.
4. For dialogs/snackbars, use `OurnegoAlertDialog`, `OurnegoInformationDialog`, and `OurnegoSnackbars`.
5. For spacing/radius values, consume token constants instead of hardcoded magic numbers when practical.

## Refactor Checklist (Per Screen)
- Replace inline input decoration.
- Replace inline button style.
- Replace inline alert/snackbar.
- Replace repeated spacing/radius constants with tokens when it improves consistency.
- Run targeted analysis for edited files.
- Verify behavior and visual parity manually in affected flows.

## Validation Commands
```bash
flutter analyze
flutter test
```

For focused edits, analyze only touched files first, then run full analysis as needed.

## Feature Adoption Snapshot
- Auth: high adoption of shared layout/input/button/snackbar patterns.
- Business: partial-to-high adoption (form and dialog flows migrated in key paths).
- Onboarding: dialog path migrated to `OurnegoInformationDialog`.
- Community: uses shared information card pattern for coming soon state.
- Map: ongoing migration; top bar and floating sheet partially migrated, remaining inline decorations still pending cleanup.

## Known Pending Work
- Finish Map cleanup for remaining inline `BoxDecoration` and repeated presentation styles.
- Continue extending shared presets only where repetition is proven.
- Keep this manual and feature READMEs synchronized after each migration block.
