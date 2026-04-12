# Test Module Guide

This document explains how testing is organized in Ournego and how to run each test type locally.

## Scope

The test module currently includes:

- unit tests (`test/features/...`)
- integration/UI automation tests with Patrol (`integration_test/...`)
- reusable test infrastructure:
  - fakes (`test/fakes/...`)
  - fixtures (`test/fixtures/...`)
  - app bootstrap helpers (`test/helpers/app_helper.dart`)

## Test Stack

- `flutter_test` for standard Flutter testing
- `patrol` for integration/native UI automation
- `mocktail` for mocking support
- Riverpod provider overrides for deterministic app wiring

## Prerequisites

1. Flutter SDK installed (project uses Flutter `3.41.4`)
2. Dependencies installed
3. Patrol CLI version compatible with the project
4. Device/emulator attached for Patrol tests

### 1) Install dependencies

```bash
flutter pub get
```

### 2) Install compatible Patrol CLI

The project currently uses Patrol package `3.x`, so install a compatible CLI (for this repo, `3.11.0` is known to work):

```bash
dart pub global activate patrol_cli 3.11.0
```

If `patrol` is not found, add pub executables to `PATH`:

```bash
export PATH="$PATH:$HOME/.pub-cache/bin"
```

### 3) Verify Patrol environment

```bash
patrol doctor
```

If Android checks fail, set your Android SDK variables (example):

```bash
export ANDROID_HOME="$HOME/Android/Sdk"
export PATH="$ANDROID_HOME/platform-tools:$PATH"
```

## Run Tests

## A) Unit tests

Run all unit tests under `test/`:

```bash
flutter test
```

Run a single unit test file:

```bash
flutter test test/features/feedback/domain/usecases/send_feedback_usecase_test.dart
```

## B) Integration tests (Patrol)

Important: Patrol requires at least one connected device/emulator.

Run full Patrol suite:

```bash
patrol test
```

Run only auth-tagged scenarios:

```bash
patrol test --tags auth
```

Run one integration file:

```bash
patrol test integration_test/auth_test.dart
```

## C) Static analysis (recommended before/after test changes)

```bash
flutter analyze
```

## Existing Integration Scenarios

### `integration_test/onboarding_test.dart`

- new user completes onboarding and persists `hasSeenOnboarding`
- returning user skips onboarding
- active valid session enters app without login
- expired token redirects to login without infinite spinner/crash
- onboarding interruption behavior covered as current-state test
- manual logout requires credentials on next opening

### `integration_test/auth_test.dart`

- customer login -> map/home
- owner with business -> business dashboard
- owner without business -> register business screen
- invalid credentials -> readable error
- no connection -> controlled error
- suspended-account path documented with TODO for future model support

### `integration_test/core_flow_test.dart`

- location permission granted -> business markers load
- location permission denied -> no crash, stable state
- no businesses in radius -> current behavior covered (TODO for explicit empty state)
- tapping business marker -> business detail/name shown (TODO for distance rendering)
- business stream update reflects updated name without manual reload

## Deterministic Test Design

Tests avoid real backend/network coupling by using provider overrides from `test/helpers/app_helper.dart`:

- `authOverrides(...)`
- `onboardingOverrides(...)`
- `businessOverrides(...)`
- `mapOverrides(...)`

Shared app state reset is done via:

- `resetAppState()` clearing SharedPreferences and secure storage

Fake repositories are under `test/fakes/` and deterministic user fixtures under `test/fixtures/mock_users.dart`.

## Common Failures and Fixes

- `No devices attached`:
  - Start emulator or connect physical device.
- Patrol CLI/package incompatibility warning:
  - Reinstall compatible CLI version (`3.11.0` for current repo state).
- Permission-dialog flakiness:
  - Ensure emulator allows automation of permission dialogs.
- Assertion mismatch against TODO behavior:
  - Check if app feature now exists and update the scenario accordingly.

## Recommended Workflow for QA/CI

1. `flutter pub get`
2. `flutter analyze`
3. `flutter test`
4. `patrol test --tags auth`
5. `patrol test`

If running in CI, ensure the runner provides:

- Flutter SDK
- Android SDK/platform-tools
- a booted emulator/device for Patrol
