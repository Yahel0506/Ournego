import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dartz/dartz.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/routing/app_router.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/routing/route_sources.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/features/auth/presentation/pages/complete_profile_screen.dart';
import 'package:ournego/features/auth/presentation/pages/verify_email_screen.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';

import '../../fakes/fake_auth_repository.dart';
import '../../fakes/fake_business_repository.dart';
import '../../fakes/fake_map_repository.dart';
import '../../fixtures/mock_users.dart';
import '../../helpers/app_helper.dart';

class _CompletionAuthRepository extends FakeAuthRepository {
  _CompletionAuthRepository({
    this.verified = true,
    this.verificationResult,
    this.profileResult,
    this.googleResult,
    this.onGoogleSuccess,
  }) : super(state: FakeAuthState.authenticatedAsCustomer);

  bool verified;
  bool hasProfile = true;
  Completer<Either<Failure, bool>>? verificationResult;
  Completer<Either<Failure, bool>>? profileResult;
  Either<Failure, void>? googleResult;
  void Function()? onGoogleSuccess;

  @override
  Future<Either<Failure, void>> signInWithGoogle() async {
    onGoogleSuccess?.call();
    return googleResult ?? Left(ServerFailure());
  }

  @override
  Future<Either<Failure, bool>> isEmailVerified() {
    return verificationResult?.future ?? Future.value(Right(verified));
  }

  @override
  Future<Either<Failure, bool>> checkHasProfile() {
    return profileResult?.future ?? Future.value(Right(hasProfile));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.loadFromString(envString: 'MAPBOX_ACCESS_TOKEN=test-token');
    await Supabase.initialize(
      url: 'https://example.supabase.co',
      anonKey: 'test-anon-key',
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'completion routes using the live session while Riverpod auth is stale',
    (tester) async {
      _setTallViewport(tester);
      String? liveUserId = 'user-1';
      final repository = _CompletionAuthRepository();
      final mapRepository = FakeMapRepository();
      addTearDown(mapRepository.dispose);

      await tester.pumpWidget(
        buildTestApp(
          [
            ...authOverrides(repository, initialSessionStatus: false),
            ...mapOverrides(mapRepository),
          ],
          startOnMap: false,
          initialLocation: AuthRoutes.authCompletion,
          currentSessionUserId: () => liveUserId,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);
    },
  );

  testWidgets('email login replaces the shell and auth route stack', (
    tester,
  ) async {
    _setTallViewport(tester);
    await _completeEmailLoginFromShell(tester, hasSeenOnboarding: true);
  });

  testWidgets('first email login marks onboarding seen and reaches the map', (
    tester,
  ) async {
    _setTallViewport(tester);
    await _completeEmailLoginFromShell(tester, hasSeenOnboarding: false);
  });

  testWidgets('Google mobile success from community completes to map', (
    tester,
  ) async {
    _setTallViewport(tester);
    String? liveUserId;
    final repository = _CompletionAuthRepository(
      googleResult: const Right(null),
      onGoogleSuccess: () => liveUserId = 'google-user',
    );
    final mapRepository = FakeMapRepository();
    addTearDown(mapRepository.dispose);
    final router = createAppRouter(
      startOnMap: false,
      initialLocation: AppRoutes.community,
      authStateChanges: const Stream<bool>.empty(),
      currentSessionUserId: () => liveUserId,
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      buildTestApp(
        [
          ...authOverrides(repository, initialSessionStatus: false),
          ...mapOverrides(mapRepository),
        ],
        startOnMap: false,
        router: router,
        testMediaQuerySize: const Size(800, 1200),
      ),
    );
    await tester.pump();
    router.push<void>(AuthRoutes.authSelection);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(find.text('Continuar con Google'));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(liveUserId, 'google-user');
    expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);
    expect(find.byKey(const ValueKey('authSelectionScreen')), findsNothing);
    expect(router.canPop(), isFalse);
  });

  testWidgets(
    'Google failure stays on selector and guest onboarding reaches map',
    (tester) async {
      _setTallViewport(tester);
      final mapRepository = FakeMapRepository();
      addTearDown(mapRepository.dispose);
      final router = createAppRouter(
        startOnMap: false,
        initialLocation: AuthRoutes.authSelection,
        authStateChanges: const Stream<bool>.empty(),
        currentSessionUserId: () => null,
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        buildTestApp(
          [
            ...authOverrides(
              _CompletionAuthRepository(),
              initialSessionStatus: false,
            ),
            ...mapOverrides(mapRepository),
          ],
          startOnMap: false,
          router: router,
          testMediaQuerySize: const Size(800, 1200),
        ),
      );
      await tester.pump();
      await tester.tap(find.text('Continuar con Google'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(find.byType(AuthSelectionScreen), findsOneWidget);
      expect(
        router.routeInformationProvider.value.uri.path,
        AuthRoutes.authSelection,
      );
      expect(find.byKey(const ValueKey('guestAccessButton')), findsNothing);

      router.go(
        AuthRoutes.authSelection,
        extra: AuthSelectionRouteSource.onboarding,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const ValueKey('guestAccessButton')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('guestAccessButton')));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);
      expect(router.routeInformationProvider.value.uri.path, MapRoutes.map);
      expect(router.canPop(), isFalse);
    },
  );

  testWidgets('manual back from email login returns to selector', (
    tester,
  ) async {
    _setTallViewport(tester);
    final router = createAppRouter(
      startOnMap: false,
      initialLocation: AuthRoutes.authSelection,
      authStateChanges: const Stream<bool>.empty(),
      currentSessionUserId: () => null,
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      buildTestApp(
        authOverrides(_CompletionAuthRepository(), initialSessionStatus: false),
        startOnMap: false,
        router: router,
        testMediaQuerySize: const Size(800, 1200),
      ),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('emailAccessButton')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('loginEmailScreen')), findsOneWidget);

    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(AuthSelectionScreen), findsOneWidget);
  });

  testWidgets('completion returns to selector when there is no live session', (
    tester,
  ) async {
    _setTallViewport(tester);
    final repository = _CompletionAuthRepository();

    await tester.pumpWidget(
      buildTestApp(
        authOverrides(repository, initialSessionStatus: true),
        startOnMap: false,
        initialLocation: AuthRoutes.authCompletion,
        currentSessionUserId: () => null,
      ),
    );
    await tester.pump();

    expect(find.byType(AuthSelectionScreen), findsOneWidget);
  });

  testWidgets('completion preserves verification and profile prerequisites', (
    tester,
  ) async {
    _setTallViewport(tester);
    String? liveUserId = 'user-1';
    final repository = _CompletionAuthRepository(verified: false);

    await tester.pumpWidget(
      buildTestApp(
        authOverrides(repository, initialSessionStatus: false),
        startOnMap: false,
        initialLocation: AuthRoutes.authCompletion,
        currentSessionUserId: () => liveUserId,
      ),
    );
    await tester.pump();
    expect(find.byType(VerifyEmailScreen), findsOneWidget);

    repository.verified = true;
    repository.hasProfile = false;
    liveUserId = 'user-2';
    await tester.pumpWidget(
      buildTestApp(
        authOverrides(repository, initialSessionStatus: false),
        startOnMap: false,
        initialLocation: AuthRoutes.authCompletion,
        currentSessionUserId: () => liveUserId,
      ),
    );
    await tester.pump();
    expect(find.byType(CompleteProfileScreen), findsOneWidget);
  });

  testWidgets('signout during verification cannot use the old result', (
    tester,
  ) async {
    _setTallViewport(tester);
    String? liveUserId = 'user-1';
    final verification = Completer<Either<Failure, bool>>();
    final repository = _CompletionAuthRepository(
      verificationResult: verification,
    );

    await tester.pumpWidget(
      buildTestApp(
        authOverrides(repository, initialSessionStatus: false),
        startOnMap: false,
        initialLocation: AuthRoutes.authCompletion,
        currentSessionUserId: () => liveUserId,
      ),
    );
    await tester.pump();

    liveUserId = null;
    verification.complete(const Right(true));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AuthSelectionScreen), findsOneWidget);
  });

  testWidgets('user change during profile lookup cannot use old result', (
    tester,
  ) async {
    _setTallViewport(tester);
    String? liveUserId = 'user-1';
    final profile = Completer<Either<Failure, bool>>();
    final repository = _CompletionAuthRepository(profileResult: profile);

    await tester.pumpWidget(
      buildTestApp(
        authOverrides(repository, initialSessionStatus: false),
        startOnMap: false,
        initialLocation: AuthRoutes.authCompletion,
        currentSessionUserId: () => liveUserId,
      ),
    );
    await tester.pump();

    liveUserId = 'user-2';
    profile.complete(const Right(true));
    await tester.pump();
    await tester.pump();

    expect(find.byType(AuthSelectionScreen), findsOneWidget);
  });

  testWidgets('eligible user remains on business registration routes', (
    tester,
  ) async {
    _setTallViewport(tester);
    for (final path in [BusinessRoutes.register, BusinessRoutes.form]) {
      final router = createAppRouter(
        startOnMap: false,
        initialLocation: path,
        authStateChanges: const Stream<bool>.empty(),
        currentSessionUserId: () => 'user-1',
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        buildTestApp(
          [
            ...authOverrides(
              _CompletionAuthRepository(),
              initialSessionStatus: true,
            ),
            ...businessOverrides(FakeBusinessRepository()),
          ],
          startOnMap: false,
          initialLocation: path,
          router: router,
          currentSessionUserId: () => 'user-1',
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(router.routeInformationProvider.value.uri.path, path);
      expect(find.byKey(const ValueKey('mapScreen')), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}

void _setTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _completeEmailLoginFromShell(
  WidgetTester tester, {
  required bool hasSeenOnboarding,
}) async {
  SharedPreferences.setMockInitialValues({
    'hasSeenOnboarding': hasSeenOnboarding,
  });
  String? liveUserId;
  final authStateChanges = StreamController<bool>.broadcast();
  addTearDown(authStateChanges.close);
  final repository = FakeAuthRepository(
    state: FakeAuthState.authenticatedAsCustomer,
    onLogin: (_) {
      liveUserId = MockUsers.customer.uid;
      authStateChanges.add(true);
    },
  );
  final mapRepository = FakeMapRepository();
  addTearDown(mapRepository.dispose);
  final router = createAppRouter(
    startOnMap: true,
    authStateChanges: authStateChanges.stream,
    currentSessionUserId: () => liveUserId,
  );
  addTearDown(router.dispose);

  await tester.pumpWidget(
    buildTestApp(
      [
        ...authOverrides(
          repository,
          sessionStream: authStateChanges.stream,
          initialSessionStatus: false,
        ),
        ...mapOverrides(mapRepository),
      ],
      startOnMap: true,
      router: router,
      currentSessionUserId: () => liveUserId,
      testOverlay: const _AuthStatusProbe(),
      testMediaQuerySize: const Size(800, 1200),
    ),
  );
  await tester.pump();
  router.push<void>(AuthRoutes.authSelection);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.tap(find.byKey(const ValueKey('emailAccessButton')));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));

  await tester.enterText(
    find.byKey(const ValueKey('loginEmailInput')),
    MockCredentials.validEmail,
  );
  expect(find.byKey(const ValueKey('loginPasswordInput')), findsOneWidget);
  await tester.enterText(
    find.byKey(const ValueKey('loginPasswordInput')),
    MockCredentials.validPassword,
  );
  await tester.tap(find.byKey(const ValueKey('loginSubmitButton')));
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(liveUserId, MockUsers.customer.uid);
  expect(find.byKey(const ValueKey('mapScreen')), findsOneWidget);
  expect(find.byKey(const ValueKey('authSelectionScreen')), findsNothing);
  expect(find.byKey(const ValueKey('loginEmailScreen')), findsNothing);
  expect(router.canPop(), isFalse);
  expect(find.text('authenticated'), findsOneWidget);
  expect(
    (await SharedPreferences.getInstance()).getBool('hasSeenOnboarding'),
    isTrue,
  );
}

class _AuthStatusProbe extends ConsumerWidget {
  const _AuthStatusProbe();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAuthenticated = ref.watch(authSessionStatusProvider);
    return Text(
      isAuthenticated ? 'authenticated' : 'anonymous',
      key: const ValueKey('authStatusProbe'),
    );
  }
}
