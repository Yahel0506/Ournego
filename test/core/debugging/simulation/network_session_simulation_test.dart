import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:ournego/core/debugging/presentation/pages/debug_panel_screen.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_providers.dart';
import 'package:ournego/core/debugging/simulation/session_expiry_simulator.dart';
import 'package:ournego/core/debugging/simulation/session_simulation_section.dart';
import 'package:ournego/core/debugging/simulation/simulated_connectivity.dart';
import 'package:ournego/core/debugging/simulation/simulated_http_client.dart';
import 'package:ournego/core/debugging/simulation/startup_fault_interceptors.dart';
import 'package:ournego/core/network/network_error_classifier.dart';

DebugSimulationController _controller(NetworkMode mode) =>
    DebugSimulationController(initial: DebugSimulation(networkMode: mode));

void main() {
  group('SimulatedHttpClient', () {
    var reached = 0;
    final inner = MockClient((request) async {
      reached++;
      return http.Response('ok', 200);
    });
    setUp(() => reached = 0);

    test('real passes requests through', () async {
      final client = SimulatedHttpClient(
        mode: () => NetworkMode.real,
        inner: inner,
      );
      expect((await client.get(Uri.parse('https://x.test'))).body, 'ok');
      expect(reached, 1);
    });

    for (final mode in [NetworkMode.offline, NetworkMode.serverUnreachable]) {
      test('${mode.name} fails like a real network error', () async {
        final client = SimulatedHttpClient(mode: () => mode, inner: inner);
        Object? error;
        try {
          await client.get(Uri.parse('https://x.test'));
        } catch (e) {
          error = e;
        }
        expect(error, isA<http.ClientException>());
        expect(isNetworkError(error!), isTrue);
        expect(reached, 0);
      });
    }

    test('slow delays the request and still completes it', () async {
      final client = SimulatedHttpClient(
        mode: () => NetworkMode.slow,
        inner: inner,
        slowDelay: const Duration(milliseconds: 50),
      );
      final watch = Stopwatch()..start();
      await client.get(Uri.parse('https://x.test'));
      expect(watch.elapsedMilliseconds, greaterThanOrEqualTo(45));
      expect(reached, 1);
    });

    test('mode is read on every request, so changes apply live', () async {
      var mode = NetworkMode.real;
      final client = SimulatedHttpClient(mode: () => mode, inner: inner);
      await client.get(Uri.parse('https://x.test'));
      mode = NetworkMode.offline;
      expect(
        client.get(Uri.parse('https://x.test')),
        throwsA(isA<http.ClientException>()),
      );
    });
  });

  group('simulated connectivity', () {
    late StreamController<bool> device;
    late List<bool> emitted;
    late List<NetworkMode> modeChanges;
    late List<void Function()> disposers;

    Stream<bool> combine(DebugSimulationController controller) {
      final stream = combineConnectivity(
        device.stream,
        controller,
        onModeChanged: modeChanges.add,
        registerDispose: disposers.add,
      );
      stream.listen(emitted.add);
      return stream;
    }

    setUp(() {
      device = StreamController<bool>.broadcast();
      emitted = [];
      modeChanges = [];
      disposers = [];
    });
    tearDown(() {
      for (final dispose in disposers) {
        dispose();
      }
      device.close();
    });

    test(
      'offline forces false and going back restores the device state',
      () async {
        final controller = _controller(NetworkMode.real);
        combine(controller);
        device.add(true);
        await pumpEventQueue();

        controller.update(
          const DebugSimulation(networkMode: NetworkMode.offline),
        );
        await pumpEventQueue();
        controller.update(const DebugSimulation());
        await pumpEventQueue();

        expect(emitted, [true, false, true]);
        expect(modeChanges, [NetworkMode.offline, NetworkMode.real]);
      },
    );

    test('serverUnreachable keeps the device online', () async {
      final controller = _controller(NetworkMode.real);
      combine(controller);
      device.add(true);
      controller.update(
        const DebugSimulation(networkMode: NetworkMode.serverUnreachable),
      );
      await pumpEventQueue();
      expect(emitted, [true]);
      expect(modeChanges, [NetworkMode.serverUnreachable]);
    });

    test('a real device drop still wins while the simulation is off', () async {
      combine(_controller(NetworkMode.real));
      device.add(true);
      device.add(false);
      await pumpEventQueue();
      expect(emitted, [true, false]);
    });

    test('starts offline when the simulation was saved for startup', () async {
      combine(_controller(NetworkMode.offline));
      device.add(true);
      await pumpEventQueue();
      expect(emitted, [false]);
    });
  });

  group('SessionExpirySimulator', () {
    test('reports noSession without calling the SDK', () async {
      var calls = 0;
      final simulator = SessionExpirySimulator(
        hasSession: () => false,
        refresh: (_) async => calls++,
      );
      expect(await simulator.expireNow(), SessionExpiryOutcome.noSession);
      expect(calls, 0);
    });

    test(
      'expires when the SDK drops the session on a failed refresh',
      () async {
        var session = true;
        String? tokenSent;
        final simulator = SessionExpirySimulator(
          hasSession: () => session,
          refresh: (token) async {
            tokenSent = token;
            session = false;
            throw Exception('refresh_token_not_found');
          },
        );
        expect(await simulator.expireNow(), SessionExpiryOutcome.expired);
        expect(tokenSent, isNotEmpty);
      },
    );

    test('reports notExpired when the refresh failure was retryable', () async {
      final simulator = SessionExpirySimulator(
        hasSession: () => true,
        refresh: (_) async => throw http.ClientException('offline'),
      );
      expect(await simulator.expireNow(), SessionExpiryOutcome.notExpired);
    });
  });

  group('startup interceptors', () {
    test('hand the simulated client to the SDK even without a fault', () {
      final client = MockClient((_) async => http.Response('', 200));
      expect(
        startupInterceptorsFor(
          StartupFault.none,
          httpClient: client,
        )?.httpClient,
        same(client),
      );
      expect(startupInterceptorsFor(StartupFault.none), isNull);
    });
  });

  group('persistence', () {
    test('network mode survives a JSON round trip', () {
      const simulation = DebugSimulation(networkMode: NetworkMode.slow);
      expect(
        DebugSimulation.fromJson(simulation.toJson()).networkMode,
        NetworkMode.slow,
      );
      expect(simulation.isActive, isTrue);
    });
  });

  group('panel sections', () {
    testWidgets('network mode is chosen from the panel and applies live', (
      tester,
    ) async {
      final controller = DebugSimulationController();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            debugSimulationControllerProvider.overrideWithValue(controller),
          ],
          child: const MaterialApp(home: DebugPanel()),
        ),
      );
      final tile = find.byKey(const ValueKey('debugNetworkMode-offline'));
      await tester.ensureVisible(tile);
      await tester.tap(tile);
      await tester.pump();
      expect(controller.value.networkMode, NetworkMode.offline);
    });

    testWidgets('the session button runs the simulator and reports back', (
      tester,
    ) async {
      var session = true;
      final simulator = SessionExpirySimulator(
        hasSession: () => session,
        refresh: (_) async {
          session = false;
          throw Exception('revoked');
        },
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: SessionSimulationSection(simulator: simulator),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('debugExpireSession')));
      await tester.pump();
      await tester.pump();
      expect(
        find.text('Sesión vencida: debería verse el aviso.'),
        findsOneWidget,
      );
      expect(session, isFalse);
    });
  });
}
