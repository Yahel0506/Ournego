import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/debugging/presentation/pages/debug_panel_screen.dart';
import 'package:ournego/core/debugging/simulation/debug_restart_scope.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_store.dart';
import 'package:ournego/core/debugging/simulation/simulated_startup_failure_banner.dart';
import 'package:ournego/core/debugging/simulation/startup_fault_interceptors.dart';
import 'package:ournego/core/startup/startup_controller.dart';
import 'package:ournego/core/startup/startup_gate.dart';

const _config = SupabaseStartupConfig(
  url: 'https://example.supabase.co',
  anonKey: 'public-test-key',
);

class _Calls {
  int prepare = 0;
  int sdk = 0;
}

/// A real [StartupController] whose steps pass through the interceptors.
StartupController _controller(StartupFault fault, _Calls calls) {
  final interceptors = startupInterceptorsFor(fault);
  StartupConfigResolver resolve = () async => _config;
  StartupPreparation prepare = () async => calls.prepare++;
  StartupSdkInitializer sdk = (_) async => calls.sdk++;
  resolve = interceptors?.resolveConfig?.call(resolve) ?? resolve;
  prepare = interceptors?.prepare?.call(prepare) ?? prepare;
  sdk = interceptors?.initializeSdk?.call(sdk) ?? sdk;
  return StartupController(
    resolveConfig: resolve,
    prepare: prepare,
    initializeSdk: sdk,
    readOnboarding: () async => false,
    timeout: interceptors?.timeout ?? const Duration(seconds: 20),
    wasSimulated: interceptors?.wasSimulated,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('startup fault interceptors', () {
    test('none injects nothing', () {
      expect(startupInterceptorsFor(StartupFault.none), isNull);
    });

    test(
      'configuration fails without retry and never touches the SDK',
      () async {
        final calls = _Calls();
        final controller = _controller(StartupFault.configuration, calls)
          ..start();
        await pumpEventQueue();
        final failure = controller.state.failure!;
        expect(failure.kind, StartupErrorKind.configuration);
        expect(failure.canRetry, isFalse);
        expect(failure.simulated, isTrue);
        expect(calls.sdk, 0);
      },
    );

    test('retryable preparation recovers on the single retry', () async {
      final calls = _Calls();
      final controller = _controller(StartupFault.preparationRetryable, calls)
        ..start();
      await pumpEventQueue();
      expect(controller.state.failure!.kind, StartupErrorKind.preparation);
      expect(controller.state.failure!.canRetry, isTrue);
      expect(controller.state.failure!.simulated, isTrue);

      controller.retry();
      await pumpEventQueue();
      expect(controller.state.isReady, isTrue);
      expect(calls.prepare, 1);
      expect(calls.sdk, 1);
    });

    test('persistent preparation stops after the single retry', () async {
      final calls = _Calls();
      final controller = _controller(StartupFault.preparationPersistent, calls)
        ..start();
      await pumpEventQueue();
      controller.retry();
      await pumpEventQueue();
      expect(controller.state.failure!.canRetry, isFalse);
      expect(controller.state.failure!.simulated, isTrue);
      expect(calls.sdk, 0);
    });

    test('initialization fault fails without retry', () async {
      final calls = _Calls();
      final controller = _controller(StartupFault.initialization, calls)
        ..start();
      await pumpEventQueue();
      expect(controller.state.failure!.kind, StartupErrorKind.initialization);
      expect(controller.state.failure!.canRetry, isFalse);
      expect(controller.state.failure!.simulated, isTrue);
    });

    test('a real failure is never flagged as simulated', () async {
      final controller = StartupController(
        resolveConfig: () async => throw StartupConfigurationException(),
        prepare: () async {},
        initializeSdk: (_) async {},
        readOnboarding: () async => false,
      )..start();
      await pumpEventQueue();
      expect(controller.state.failure!.simulated, isFalse);
    });

    testWidgets('timeout fault expires after five seconds', (tester) async {
      final controller = _controller(StartupFault.timeout, _Calls())..start();
      await tester.pump(const Duration(seconds: 4));
      expect(controller.state.isStarting, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(controller.state.failure!.kind, StartupErrorKind.timeout);
      expect(controller.state.failure!.simulated, isTrue);
      controller.dispose();
    });
  });

  group('DebugSimulation', () {
    test('survives a JSON round trip and ignores unknown values', () {
      const simulation = DebugSimulation(startupFault: StartupFault.timeout);
      expect(
        DebugSimulation.fromJson(simulation.toJson()).startupFault,
        StartupFault.timeout,
      );
      expect(
        DebugSimulation.fromJson({'startupFault': 'gone'}).startupFault,
        StartupFault.none,
      );
    });

    test('a saved startup fault applies to one cold start only', () async {
      final store = DebugSimulationStore();
      await store.save(
        const DebugSimulation(startupFault: StartupFault.configuration),
      );

      final first = await DebugSimulationController.bootstrap(store: store);
      expect(first.value.startupFault, StartupFault.configuration);

      final second = await DebugSimulationController.bootstrap(store: store);
      expect(second.value.isActive, isFalse);
    });

    test('update saves for the next cold start', () async {
      final store = DebugSimulationStore();
      final controller = await DebugSimulationController.bootstrap(
        store: store,
      );
      controller.update(
        const DebugSimulation(startupFault: StartupFault.initialization),
      );
      await pumpEventQueue();
      expect((await store.load()).startupFault, StartupFault.initialization);
    });
  });

  group('banner on the real error screen', () {
    Widget gate(DebugSimulationController controller, StartupFault fault) =>
        StartupGate(
          controller: _controller(fault, _Calls()),
          simulatedFailureBannerBuilder: (_) =>
              SimulatedStartupFailureBanner(controller: controller),
          appBuilder: (_) => const MaterialApp(home: Text('app')),
        );

    testWidgets('appears for a simulated failure and restarts clean', (
      tester,
    ) async {
      final controller = DebugSimulationController(
        initial: const DebugSimulation(
          startupFault: StartupFault.configuration,
        ),
      );
      await tester.pumpWidget(
        DebugRestartScope(
          builder: (_) => gate(controller, controller.value.startupFault),
        ),
      );
      await tester.pump();
      const banner = ValueKey('simulatedStartupFailureBanner');
      expect(find.byKey(banner), findsOneWidget);
      expect(find.text('Ournego no puede iniciar'), findsOneWidget);

      await tester.tap(find.text('Desactivar simulación y reiniciar'));
      await tester.pump();
      await tester.pump();
      expect(controller.value.isActive, isFalse);
      expect(find.byKey(banner), findsNothing);
      expect(find.text('app'), findsOneWidget);
    });

    testWidgets('is absent for a real failure', (tester) async {
      final controller = DebugSimulationController();
      await tester.pumpWidget(
        StartupGate(
          controller: StartupController(
            resolveConfig: () async => throw StartupConfigurationException(),
            prepare: () async {},
            initializeSdk: (_) async {},
            readOnboarding: () async => false,
          ),
          simulatedFailureBannerBuilder: (_) =>
              SimulatedStartupFailureBanner(controller: controller),
          appBuilder: (_) => const SizedBox.shrink(),
        ),
      );
      await tester.pump();
      expect(find.text('Ournego no puede iniciar'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('simulatedStartupFailureBanner')),
        findsNothing,
      );
    });
  });

  testWidgets('panel selects a fault and restarts the startup flow', (
    tester,
  ) async {
    final controller = DebugSimulationController();
    var builds = 0;
    await tester.pumpWidget(
      DebugRestartScope(
        builder: (_) {
          builds++;
          return ProviderScope(
            overrides: [
              debugSimulationControllerProvider.overrideWithValue(controller),
            ],
            child: const MaterialApp(home: DebugPanel()),
          );
        },
      ),
    );
    final fault = find.byKey(
      const ValueKey('debugStartupFault-initialization'),
    );
    await tester.ensureVisible(fault);
    await tester.tap(fault);
    await tester.pump();
    expect(controller.value.startupFault, StartupFault.initialization);

    final restart = find.byKey(const ValueKey('debugRestartStartup'));
    await tester.ensureVisible(restart);
    await tester.tap(restart);
    await tester.pump();
    expect(builds, 2);
  });
}
