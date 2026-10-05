import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/startup/startup_controller.dart';

const _validConfig = SupabaseStartupConfig(
  url: 'https://example.supabase.co',
  anonKey: 'public-test-key',
);

StartupController _controller({
  StartupConfigResolver? resolve,
  StartupPreparation? prepare,
  StartupSdkInitializer? initialize,
  StartupOnboardingReader? onboarding,
  Duration timeout = const Duration(seconds: 5),
}) => StartupController(
  resolveConfig: resolve ?? () async => _validConfig,
  prepare: prepare ?? () async {},
  initializeSdk: initialize ?? (_) async {},
  readOnboarding: onboarding ?? () async => false,
  timeout: timeout,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('resolveStartupConfig', () {
    test(
      'uses per-field dotenv fallback while preserving supplied define',
      () async {
        var loads = 0;
        final config = await resolveStartupConfig(
          isWeb: false,
          urlDefine: '  https://defined.example  ',
          anonKeyDefine: '',
          webValue: (_) => '',
          loadDotenv: () async => loads++,
          dotenvValues: () => {
            'SUPABASE_URL': 'https://fallback.example',
            'SUPABASE_ANON_KEY': 'fallback-key',
          },
        );

        expect(loads, 1);
        expect(config.url, 'https://defined.example');
        expect(config.anonKey, 'fallback-key');
      },
    );

    test('rejects missing fields and malformed/non-HTTP URLs', () async {
      for (final url in ['', 'ftp://example.com', 'https:///missing-host']) {
        await expectLater(
          resolveStartupConfig(
            isWeb: true,
            urlDefine: '',
            anonKeyDefine: '',
            webValue: (key) => key == 'SUPABASE_URL' ? url : 'key',
          ),
          throwsA(isA<StartupConfigurationException>()),
        );
      }
      await expectLater(
        resolveStartupConfig(
          isWeb: true,
          urlDefine: '',
          anonKeyDefine: '',
          webValue: (_) => '  ',
        ),
        throwsA(isA<StartupConfigurationException>()),
      );
    });
  });

  group('StartupController', () {
    test(
      'permits one manual retry only for preparation channel-error',
      () async {
        var preparations = 0;
        var sdkCalls = 0;
        final controller = _controller(
          prepare: () async {
            preparations++;
            if (preparations == 1) {
              throw PlatformException(code: 'channel-error');
            }
          },
          initialize: (_) async => sdkCalls++,
          onboarding: () async => true,
        );

        controller.start();
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.failure?.canRetry, isTrue);
        expect(sdkCalls, 0);

        controller.retry();
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.isReady, isTrue);
        expect(controller.state.startOnMap, isTrue);
        expect(preparations, 2);
        expect(sdkCalls, 1);
        controller.dispose();
      },
    );

    test(
      'real SharedPreferences getInstance retries after channel-error and retains onboarding',
      () async {
        const channel = MethodChannel('plugins.flutter.io/shared_preferences');
        SharedPreferences.resetStatic();
        var reads = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (call) async {
              if (call.method != 'getAll') return true;
              reads++;
              if (reads == 1) throw PlatformException(code: 'channel-error');
              return <String, Object>{'flutter.hasSeenOnboarding': true};
            });
        var sdkCalls = 0;
        final controller = _controller(
          prepare: () async => SharedPreferences.getInstance(),
          onboarding: () async =>
              (await SharedPreferences.getInstance()).getBool(
                'hasSeenOnboarding',
              ) ??
              false,
          initialize: (_) async => sdkCalls++,
        );

        controller.start();
        await Future<void>.delayed(Duration.zero);
        expect(controller.state.failure?.canRetry, isTrue);
        expect(sdkCalls, 0);
        controller.retry();
        await Future<void>.delayed(Duration.zero);

        expect(reads, 2);
        expect(sdkCalls, 1);
        expect(controller.state.isReady, isTrue);
        expect(controller.state.startOnMap, isTrue);
        controller.dispose();
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
        SharedPreferences.resetStatic();
      },
    );

    test('persistent channel-error cannot produce a third attempt', () async {
      var preparations = 0;
      final controller = _controller(
        prepare: () async {
          preparations++;
          throw PlatformException(code: 'channel-error');
        },
      );
      controller.start();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.failure?.canRetry, isTrue);
      controller.retry();
      await Future<void>.delayed(Duration.zero);
      expect(preparations, 2);
      expect(controller.state.failure?.canRetry, isFalse);
      controller.retry();
      expect(preparations, 2);
      controller.dispose();
    });

    test('duplicate manual retry calls share one in-flight attempt', () async {
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
      controller.start();
      await Future<void>.delayed(Duration.zero);
      controller.retry();
      controller.retry();
      await Future<void>.delayed(Duration.zero);
      expect(preparations, 2);
      expect(sdkCalls, 0);

      retryPreparation.complete();
      await Future<void>.delayed(Duration.zero);
      expect(preparations, 2);
      expect(sdkCalls, 1);
      expect(controller.state.isReady, isTrue);
      controller.dispose();
    });

    test(
      'MissingPluginException and unknown platform codes are non-retryable',
      () async {
        for (final error in <Object>[
          MissingPluginException(),
          PlatformException(code: 'permission-denied'),
          StateError('local error'),
        ]) {
          final controller = _controller(prepare: () async => throw error);
          controller.start();
          await Future<void>.delayed(Duration.zero);
          expect(controller.state.failure?.canRetry, isFalse);
          controller.retry();
          expect(controller.state.isStarting, isFalse);
          controller.dispose();
        }
      },
    );

    test(
      'SDK failure blocks future retries after a partial initialization',
      () async {
        var calls = 0;
        final controller = _controller(
          initialize: (_) async {
            calls++;
            throw StateError('partial client');
          },
        );
        controller.start();
        await Future<void>.delayed(Duration.zero);
        controller.retry();
        expect(controller.state.failure?.kind, StartupErrorKind.initialization);
        expect(calls, 1);
        controller.dispose();
      },
    );

    test('late preparation after timeout never enters SDK', () async {
      final prepared = Completer<void>();
      var sdkCalls = 0;
      final controller = _controller(
        prepare: () => prepared.future,
        initialize: (_) async => sdkCalls++,
        timeout: const Duration(milliseconds: 10),
      );
      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.state.failure?.kind, StartupErrorKind.timeout);
      prepared.complete();
      await Future<void>.delayed(Duration.zero);
      expect(sdkCalls, 0);
      expect(controller.state.isReady, isFalse);
      controller.dispose();
    });

    test('late SDK success after timeout never releases ready state', () async {
      final sdk = Completer<void>();
      final controller = _controller(
        initialize: (_) => sdk.future,
        timeout: const Duration(milliseconds: 10),
      );
      controller.start();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(controller.state.failure?.kind, StartupErrorKind.timeout);
      sdk.complete();
      await Future<void>.delayed(Duration.zero);
      expect(controller.state.isReady, isFalse);
      controller.dispose();
    });

    test('dispose ignores late async completion', () async {
      final prepared = Completer<void>();
      var sdkCalls = 0;
      final controller = _controller(
        prepare: () => prepared.future,
        initialize: (_) async => sdkCalls++,
      );
      controller.start();
      controller.dispose();
      prepared.complete();
      await Future<void>.delayed(Duration.zero);
      expect(sdkCalls, 0);
      expect(controller.state.isStarting, isTrue);
    });
  });
}
