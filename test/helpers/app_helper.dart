import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/routing/app_router.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';

import '../fakes/fake_manual_zone_repository.dart';

Widget buildTestApp(
  List<Override> overrides, {
  required bool startOnMap,
  String? initialLocation,
  Stream<dynamic>? authStateChanges,
  String? Function()? currentSessionUserId,
  GoRouter? router,
  Widget? testOverlay,
  Size? testMediaQuerySize,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp.router(
      routerConfig:
          router ??
          createAppRouter(
            startOnMap: startOnMap,
            initialLocation: initialLocation,
            authStateChanges: authStateChanges ?? const Stream<bool>.empty(),
            currentSessionUserId: currentSessionUserId,
          ),
      title: 'Ournego',
      theme: OurnegoColors.lightTheme,
      darkTheme: OurnegoColors.darkTheme,
      builder: (context, child) {
        final app = testOverlay == null
            ? child!
            : Stack(
                children: [
                  child!,
                  IgnorePointer(child: testOverlay),
                ],
              );
        if (testMediaQuerySize == null) return app;
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            size: testMediaQuerySize,
            textScaler: const TextScaler.linear(0.8),
          ),
          child: app,
        );
      },
      scrollBehavior: const _TestScrollBehavior(),
    ),
  );
}

Future<void> resetAppState() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  try {
    const secureStorage = FlutterSecureStorage();
    await secureStorage.deleteAll();
  } on MissingPluginException {
    // Ignored for targets where secure storage plugin is unavailable.
  } on PlatformException {
    // Ignored for targets where secure storage backend is unavailable.
  }
}

List<Override> onboardingOverrides(
  OnboardingRepository repository, {
  bool enforceLocationPermission = false,
}) {
  return [
    onboardingRepositoryProvider.overrideWith((ref) => repository),
    onboardingEnforceLocationPermissionProvider.overrideWith(
      (ref) => enforceLocationPermission,
    ),
  ];
}

List<Override> authOverrides(
  AuthRepository repository, {
  Stream<bool>? sessionStream,
  bool initialSessionStatus = false,
}) {
  Stream<bool> buildAuthSessionStream() async* {
    yield initialSessionStatus;
    if (sessionStream != null) {
      yield* sessionStream;
    }
  }

  return [
    authRepositoryProvider.overrideWith((ref) => repository),
    authSessionProvider.overrideWith((ref) => buildAuthSessionStream()),
    authSessionStatusProvider.overrideWith((ref) {
      final authState = ref.watch(authSessionProvider);
      return authState.maybeWhen(
        data: (isLoggedIn) => isLoggedIn,
        orElse: () => initialSessionStatus,
      );
    }),
  ];
}

List<Override> businessOverrides(BusinessRepository repository) {
  return [businessRepositoryProvider.overrideWith((ref) => repository)];
}

List<Override> mapOverrides(
  MapRepository repository, {
  bool mapTilesEnabled = false,
}) {
  return [
    mapRepositoryProvider.overrideWith((ref) => repository),
    manualZoneRepositoryProvider.overrideWith(
      (ref) => FakeManualZoneRepository(),
    ),
    mapTilesEnabledProvider.overrideWith((ref) => mapTilesEnabled),
  ];
}

class _TestScrollBehavior extends MaterialScrollBehavior {
  const _TestScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
