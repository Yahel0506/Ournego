import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/startup/ournego_splash_animation.dart';
import 'package:ournego/core/startup/startup_controller.dart';
import 'package:ournego/core/startup/startup_gate.dart';

const _config = SupabaseStartupConfig(
  url: 'https://example.supabase.co',
  anonKey: 'public-test-key',
);

StartupController _controller({
  StartupPreparation? prepare,
  StartupSdkInitializer? initialize,
  Duration timeout = const Duration(seconds: 5),
}) => StartupController(
  resolveConfig: () async => _config,
  prepare: prepare ?? () async {},
  initializeSdk: initialize ?? (_) async {},
  readOnboarding: () async => false,
  timeout: timeout,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'app builder stays blocked until full SDK initialization succeeds',
    (tester) async {
      final sdk = Completer<void>();
      final controller = _controller(initialize: (_) => sdk.future);
      var appBuilds = 0;
      await tester.pumpWidget(
        StartupGate(
          controller: controller,
          appBuilder: (startOnMap) {
            appBuilds++;
            return const MaterialApp(home: Text('routed feature'));
          },
        ),
      );
      expect(find.text('routed feature'), findsNothing);
      expect(appBuilds, 0);

      sdk.complete();
      await tester.pump();
      expect(find.text('routed feature'), findsOneWidget);
      expect(appBuilds, 1);
    },
  );

  testWidgets('late SDK success after timeout never builds the app', (
    tester,
  ) async {
    final sdk = Completer<void>();
    final controller = _controller(
      initialize: (_) => sdk.future,
      timeout: const Duration(milliseconds: 10),
    );
    var appBuilds = 0;
    await tester.pumpWidget(
      StartupGate(
        controller: controller,
        appBuilder: (_) {
          appBuilds++;
          return const MaterialApp(home: Text('routed feature'));
        },
      ),
    );
    await tester.pump(const Duration(milliseconds: 20));
    sdk.complete();
    await tester.pump();
    expect(find.text('routed feature'), findsNothing);
    expect(appBuilds, 0);
    expect(find.text('No pudimos iniciar Ournego'), findsOneWidget);
  });

  testWidgets('invalid configuration blocks SDK and routed app without retry', (
    tester,
  ) async {
    var sdkCalls = 0;
    var appBuilds = 0;
    final controller = StartupController(
      resolveConfig: () async => throw StartupConfigurationException(),
      prepare: () async {},
      initializeSdk: (_) async => sdkCalls++,
      readOnboarding: () async => false,
    );
    await tester.pumpWidget(
      StartupGate(
        controller: controller,
        appBuilder: (_) {
          appBuilds++;
          return const MaterialApp(home: Text('routed feature'));
        },
      ),
    );
    await tester.pump();

    expect(find.text('Ournego no puede iniciar'), findsOneWidget);
    expect(
      find.text('Esta instalación necesita una corrección para funcionar.'),
      findsOneWidget,
    );
    expect(find.text('routed feature'), findsNothing);
    expect(find.text('Reintentar'), findsNothing);
    expect(find.text('Ver ayuda'), findsOneWidget);
    expect(appBuilds, 0);
    expect(sdkCalls, 0);
  });

  testWidgets(
    'duplicate retry taps cannot start concurrent preparation calls',
    (tester) async {
      var preparations = 0;
      var sdkCalls = 0;
      final retryPreparation = Completer<void>();
      final controller = _controller(
        prepare: () async {
          preparations++;
          if (preparations == 1) {
            throw PlatformException(code: 'channel-error');
          }
          return retryPreparation.future;
        },
        initialize: (_) async => sdkCalls++,
      );
      await tester.pumpWidget(
        StartupGate(
          controller: controller,
          appBuilder: (_) => const MaterialApp(home: Text('routed feature')),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Reintentar'));
      await tester.tap(find.text('Reintentar'));
      await tester.pump();

      expect(preparations, 2);
      expect(sdkCalls, 0);
      expect(find.text('Reintentar'), findsNothing);
      retryPreparation.complete();
      await tester.pump();
      await tester.pump();
      expect(sdkCalls, 1);
      expect(find.text('routed feature'), findsOneWidget);
    },
  );

  for (final launcherResult in <Object>[false, StateError('private detail')]) {
    testWidgets('support launcher failure keeps safe local help', (
      tester,
    ) async {
      final controller = _controller(
        prepare: () async => throw StateError('safe preparation category'),
      );
      await tester.pumpWidget(
        StartupGate(
          controller: controller,
          appBuilder: (_) => const MaterialApp(home: Text('routed feature')),
          supportLauncher: (_) async {
            if (launcherResult is Error) throw launcherResult;
            return launcherResult as bool;
          },
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Ver ayuda'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Contactar soporte'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No pudimos abrir el canal de consultas'),
        findsOneWidget,
      );
      expect(find.textContaining('private detail'), findsNothing);
    });
  }

  testWidgets(
    'startup error fits small screen with large text in both themes',
    (tester) async {
      tester.view.physicalSize = const Size(320, 480);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final brightness in Brightness.values) {
        tester.platformDispatcher.platformBrightnessTestValue = brightness;
        final controller = _controller(
          prepare: () async {
            throw StateError('configuration details stay private');
          },
        );
        await tester.pumpWidget(
          MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: StartupGate(
              controller: controller,
              appBuilder: (_) =>
                  const MaterialApp(home: Text('routed feature')),
            ),
          ),
        );
        await tester.pump();
        expect(tester.takeException(), isNull);
        expect(find.text('No pudimos iniciar Ournego'), findsOneWidget);
        await tester.pumpWidget(const SizedBox.shrink());
        tester.platformDispatcher.clearPlatformBrightnessTestValue();
      }
    },
  );

  group('splash', () {
    const splashKey = Key('fake-splash');
    const hold = Duration(milliseconds: 500);
    const exit = Duration(milliseconds: 900);

    late VoidCallback completeAnimation;
    Widget fakeSplash(VoidCallback onAnimationCompleted) {
      completeAnimation = onAnimationCompleted;
      return const SizedBox(key: splashKey);
    }

    testWidgets(
      'app is built under the splash and revealed only after the animation '
      'and the minimum hold, keeping its state',
      (tester) async {
        var appBuilds = 0;
        await tester.pumpWidget(
          StartupGate(
            controller: _controller(),
            splashBuilder: fakeSplash,
            appBuilder: (_) {
              appBuilds++;
              return const MaterialApp(home: Text('routed feature'));
            },
          ),
        );
        await tester.pump();
        // Startup is ready, but the app waits for the animation to finish.
        expect(appBuilds, 0);
        expect(find.byKey(splashKey), findsOneWidget);

        completeAnimation();
        await tester.pump();
        // Built under the static logo, which still covers it.
        expect(appBuilds, 1);
        expect(find.byKey(splashKey), findsOneWidget);
        await tester.pump(hold - const Duration(milliseconds: 2));
        expect(find.byKey(splashKey), findsOneWidget);

        await tester.pump(const Duration(milliseconds: 2));
        await tester.pump(exit ~/ 2);
        expect(find.byKey(splashKey), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.byKey(splashKey), findsNothing);
        expect(find.text('routed feature'), findsOneWidget);
        expect(appBuilds, 1);
      },
    );

    testWidgets('logo holds until slow startup finishes', (tester) async {
      final sdk = Completer<void>();
      await tester.pumpWidget(
        StartupGate(
          controller: _controller(initialize: (_) => sdk.future),
          splashBuilder: fakeSplash,
          appBuilder: (_) => const MaterialApp(home: Text('routed feature')),
        ),
      );
      completeAnimation();
      await tester.pump(const Duration(seconds: 3));
      expect(find.byKey(splashKey), findsOneWidget);
      // No "starting" status screen behind the splash.
      expect(find.text('Preparando Ournego'), findsNothing);

      sdk.complete();
      await tester.pumpAndSettle();
      expect(find.byKey(splashKey), findsNothing);
      expect(find.text('routed feature'), findsOneWidget);
    });

    testWidgets('fast startup still waits for the whole animation', (
      tester,
    ) async {
      await tester.pumpWidget(
        StartupGate(
          controller: _controller(),
          splashBuilder: fakeSplash,
          appBuilder: (_) => const MaterialApp(home: Text('routed feature')),
        ),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(find.byKey(splashKey), findsOneWidget);
    });

    testWidgets('startup failure is revealed after the splash', (tester) async {
      await tester.pumpWidget(
        StartupGate(
          controller: _controller(
            prepare: () async => throw StateError('boom'),
          ),
          splashBuilder: fakeSplash,
          appBuilder: (_) => const MaterialApp(home: Text('routed feature')),
        ),
      );
      completeAnimation();
      await tester.pump(hold);
      expect(find.byKey(splashKey), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.byKey(splashKey), findsNothing);
      expect(find.text('No pudimos iniciar Ournego'), findsOneWidget);
    });

    testWidgets('missing splash asset never blocks startup', (tester) async {
      var completed = false;
      await tester.pumpWidget(
        OurnegoSplashAnimation(
          asset: 'assets/splash/missing.webp',
          onAnimationCompleted: () => completed = true,
        ),
      );
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
      expect(completed, isTrue);
    });
  });
}
