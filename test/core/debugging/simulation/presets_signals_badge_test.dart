import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/debugging/simulation/debug_restart_scope.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_badge.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/core/debugging/simulation/presets_section.dart';
import 'package:ournego/core/debugging/simulation/real_signals.dart';
import 'package:ournego/core/debugging/simulation/real_signals_card.dart';
import 'package:ournego/core/debugging/simulation/session_expiry_simulator.dart';
import 'package:ournego/core/debugging/simulation/simulation_presets.dart';
import 'package:ournego/core/location/location_access_status.dart';

SessionExpirySimulator _simulator({
  bool hasSession = true,
  void Function()? onRefresh,
}) {
  var session = hasSession;
  return SessionExpirySimulator(
    hasSession: () => session,
    refresh: (_) async {
      onRefresh?.call();
      session = false;
      throw Exception('revoked');
    },
  );
}

Widget _host({
  required DebugSimulationController controller,
  required Widget Function() child,
  required void Function() onBuild,
  RealSignalsReader? reader,
}) {
  return DebugRestartScope(
    builder: (_) {
      onBuild();
      return ProviderScope(
        overrides: [
          debugSimulationControllerProvider.overrideWithValue(controller),
          if (reader != null)
            realSignalsReaderProvider.overrideWithValue(reader),
        ],
        child: MaterialApp(
          home: Scaffold(body: SingleChildScrollView(child: child())),
        ),
      );
    },
  );
}

void main() {
  test('the six presets cover the OUR-140 matrix', () {
    expect(simulationPresets.map((p) => p.id), [
      'config',
      'session',
      'offline-open',
      'offline-use',
      'no-location',
      'google',
    ]);
    expect(
      simulationPresets.firstWhere((p) => p.id == 'config').simulation,
      const DebugSimulation(startupFault: StartupFault.configuration),
    );
    expect(
      simulationPresets.firstWhere((p) => p.id == 'session').expiresSession,
      isTrue,
    );
    expect(simulationPresets.every((p) => p.expected.isNotEmpty), isTrue);
  });

  group('presets section', () {
    testWidgets(
      'a preset replaces any previous simulation and restarts startup only when needed',
      (tester) async {
        final controller = DebugSimulationController(
          initial: const DebugSimulation(
            googleOutcome: GoogleOutcome.network,
            locationMode: LocationMode.denied,
          ),
        );
        var builds = 0;
        await tester.pumpWidget(
          _host(
            controller: controller,
            onBuild: () => builds++,
            child: () => SimulationPresetsSection(simulator: _simulator()),
          ),
        );

        await tester.ensureVisible(
          find.byKey(const ValueKey('debugPreset-offline-use')),
        );
        await tester.tap(find.byKey(const ValueKey('debugPreset-offline-use')));
        await tester.pump();
        expect(
          controller.value,
          const DebugSimulation(networkMode: NetworkMode.offline),
        );
        expect(builds, 1);

        await tester.ensureVisible(
          find.byKey(const ValueKey('debugPreset-config')),
        );
        await tester.tap(find.byKey(const ValueKey('debugPreset-config')));
        await tester.pump();
        expect(controller.value.startupFault, StartupFault.configuration);
        expect(controller.value.networkMode, NetworkMode.real);
        expect(builds, 2);
      },
    );

    testWidgets('the session preset revokes the session', (tester) async {
      final controller = DebugSimulationController();
      var refreshed = 0;
      await tester.pumpWidget(
        _host(
          controller: controller,
          onBuild: () {},
          child: () => SimulationPresetsSection(
            simulator: _simulator(onRefresh: () => refreshed++),
          ),
        ),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('debugPreset-session')),
      );
      await tester.tap(find.byKey(const ValueKey('debugPreset-session')));
      await tester.pump();
      await tester.pump();
      expect(refreshed, 1);
      expect(
        find.text('Sesión vencida: debería verse el aviso.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'reset clears everything and restarts only if startup was faulted',
      (tester) async {
        final controller = DebugSimulationController(
          initial: const DebugSimulation(startupFault: StartupFault.timeout),
        );
        var builds = 0;
        await tester.pumpWidget(
          _host(
            controller: controller,
            onBuild: () => builds++,
            child: () => SimulationPresetsSection(simulator: _simulator()),
          ),
        );
        final reset = find.byKey(const ValueKey('debugResetAll'));
        await tester.ensureVisible(reset);
        await tester.tap(reset);
        await tester.pump();
        expect(controller.value.isActive, isFalse);
        expect(builds, 2);
      },
    );
  });

  group('real signals card', () {
    Future<RealSignals> reader() async => const RealSignals(
      supabaseReady: true,
      hasSession: false,
      deviceOnline: true,
      location: LocationAccessStatus.granted,
    );

    testWidgets('shows the real values and flags what is simulated', (
      tester,
    ) async {
      final controller = DebugSimulationController(
        initial: const DebugSimulation(
          networkMode: NetworkMode.offline,
          locationMode: LocationMode.deniedForever,
        ),
      );
      await tester.pumpWidget(
        _host(
          controller: controller,
          onBuild: () {},
          reader: reader,
          child: () => const RealSignalsCard(),
        ),
      );
      await tester.pump();
      expect(find.textContaining('con red'), findsOneWidget);
      expect(find.textContaining('≠ simulado: Sin conexión'), findsOneWidget);
      expect(find.textContaining('concedida'), findsOneWidget);
      expect(
        find.textContaining('≠ simulado: Permiso denegado para siempre'),
        findsOneWidget,
      );
      expect(find.textContaining('sin sesión'), findsOneWidget);
      expect(find.textContaining('≠ simulado: Cancelado'), findsNothing);
    });

    testWidgets('refresh reads the signals again', (tester) async {
      var reads = 0;
      await tester.pumpWidget(
        _host(
          controller: DebugSimulationController(),
          onBuild: () {},
          reader: () {
            reads++;
            return reader();
          },
          child: () => const RealSignalsCard(),
        ),
      );
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('debugRefreshSignals')));
      await tester.pump();
      expect(reads, 2);
    });
  });

  group('global badge', () {
    Widget app(DebugSimulationController controller, VoidCallback onTap) =>
        ProviderScope(
          overrides: [
            debugSimulationControllerProvider.overrideWithValue(controller),
          ],
          child: MaterialApp(
            home: DebugSimulationBadge(
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    key: const ValueKey('underBadge'),
                    onPressed: onTap,
                    child: const Text('app'),
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('is hidden without a simulation and appears when one starts', (
      tester,
    ) async {
      final controller = DebugSimulationController();
      await tester.pumpWidget(app(controller, () {}));
      const badge = ValueKey('debugSimulationBadge');
      expect(find.byKey(badge), findsNothing);
      expect(find.text('app'), findsOneWidget);

      controller.update(
        const DebugSimulation(googleOutcome: GoogleOutcome.network),
      );
      await tester.pump();
      expect(find.byKey(badge), findsOneWidget);

      controller.update(const DebugSimulation());
      await tester.pump();
      expect(find.byKey(badge), findsNothing);
    });

    testWidgets('never blocks the controls underneath', (tester) async {
      var taps = 0;
      final controller = DebugSimulationController(
        initial: const DebugSimulation(locationMode: LocationMode.denied),
      );
      await tester.pumpWidget(app(controller, () => taps++));
      expect(
        find.byKey(const ValueKey('debugSimulationBadge')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('underBadge')));
      expect(taps, 1);
    });
  });
}
