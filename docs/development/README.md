# Ournego

Ournego is a Flutter application built with feature-based Clean Architecture, Riverpod state management, Supabase backend integration, and centralized GoRouter navigation.

## Quick Start

### 1) Install dependencies

```bash
flutter pub get
```

### 2) Configure environment

Required keys:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `MAPBOX_ACCESS_TOKEN`
- `MAPBOX_USERNAME`
- `MAPBOX_STYLE_ID_DARK`
- `MAPBOX_STYLE_ID_LIGHT`
- `LOCATIONIQ_API_KEY`

Web reads from `web/config.js` (`window.ENV`).
Mobile reads from `.env` and/or `--dart-define`.

### 3) Run app

```bash
flutter run
```

## Architecture

- Feature modules under `lib/features/`
- Clean Architecture dependency flow: `Presentation -> Domain <- Data`
- Centralized routing under `lib/core/routing/`

See:

- `ARCHITECTURE.md` for high-level architecture and dependency rules
- `AGENTS.md` for coding conventions and implementation patterns
- `docs/ui-refactor/README.md` for the UI refactor manual (shared presets, tokens, and migration flow)

## Core Commands

```bash
flutter analyze
flutter test
flutter build web
```
