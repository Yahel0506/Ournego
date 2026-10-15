# Debug simulation

Debug-only simulator for startup, network, session, location and Google
sign-in. It feeds the app a faulty *input* and lets the production code react,
so the screens, dialogs and failure mapping you see are the real ones. See
`docs/development/plans/our-110-debug-simulation.md`.

## Rules

- Everything is guarded by `kDebugMode`; release builds never construct it.
- Simulate the input (HTTP error, datasource answer, SDK event), never the
  reaction.
- Anything simulated must be visible as such: the global badge, the startup
  error banner and the "Señales reales" card.
- Saved values apply to one cold start only, so the app can never get stuck.

## Adding a simulated variable

1. Add an enum and a field to `DebugSimulation` (`copyWith`, JSON, `isActive`).
2. Add the seam: a datasource decorator or an interceptor, and install it from
   `debug_overrides.dart` (providers) or `startup_fault_interceptors.dart`
   (startup).
3. Add a panel section and, if it is a scenario, a preset in
   `simulation_presets.dart`.
4. Show the real value in `real_signals_card.dart`.
5. Add tests under `test/core/debugging/simulation/`.
