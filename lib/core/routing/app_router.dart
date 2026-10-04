import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/routing/route_observer.dart';
import 'package:ournego/core/routing/route_sources.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/features/auth/presentation/pages/complete_profile_screen.dart';
import 'package:ournego/features/auth/presentation/pages/create_password_screen.dart';
import 'package:ournego/features/auth/presentation/pages/login_email_screen.dart';
import 'package:ournego/features/auth/presentation/pages/password_recovery_screen.dart';
import 'package:ournego/features/auth/presentation/pages/signup_email_screen.dart';
import 'package:ournego/features/auth/presentation/pages/verify_email_screen.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/presentation/pages/business_form_screen.dart';
import 'package:ournego/features/business/presentation/pages/business_panel_screen.dart';
import 'package:ournego/features/business/presentation/pages/register_business_screen.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/community/presentation/pages/community_screen.dart';
import 'package:ournego/features/map/presentation/pages/map_screen.dart';
import 'package:ournego/features/navigation/presentation/pages/main_layout_screen.dart';
import 'package:ournego/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../debugging/presentation/pages/debug_panel_screen.dart';

GoRouter createAppRouter({
  required bool startOnMap,
  Stream<dynamic>? authStateChanges,
  String? initialLocation,
}) {
  final refreshStream = authStateChanges ?? _defaultAuthStateChanges();

  return GoRouter(
    initialLocation:
        initialLocation ?? (startOnMap ? MapRoutes.map : AppRoutes.onboarding),
    debugLogDiagnostics: false,
    observers: [AppRouteObserver.instance],
    refreshListenable: GoRouterRefreshStream(refreshStream),
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AuthRoutes.authSelection,
        name: 'auth-selection',
        pageBuilder: (context, state) {
          final source = state.extra;
          if (source != AuthSelectionRouteSource.onboarding) {
            return MaterialPage<void>(
              key: state.pageKey,
              child: const AuthSelectionScreen(),
            );
          }

          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const AuthSelectionScreen(isFromOnboarding: true),
            transitionDuration: const Duration(milliseconds: 450),
            reverseTransitionDuration: const Duration(milliseconds: 300),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  final offsetTween = Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  );
                  return SlideTransition(
                    position: animation.drive(
                      offsetTween.chain(CurveTween(curve: Curves.easeOutCubic)),
                    ),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AuthRoutes.loginEmail,
        name: 'login-email',
        builder: (context, state) => const LoginEmailScreen(),
      ),
      GoRoute(
        path: AuthRoutes.passwordRecovery,
        name: 'password-recovery',
        builder: (context, state) {
          final email = state.extra as String?;
          return PasswordRecoveryScreen(initialEmail: email);
        },
      ),
      GoRoute(
        path: AuthRoutes.signupEmail,
        name: 'signup-email',
        builder: (context, state) => const SignupEmailScreen(),
      ),
      GoRoute(
        path: AuthRoutes.createPassword,
        name: 'create-password',
        builder: (context, state) {
          final email = state.extra as String?;

          if (email == null) {
            return const SignupEmailScreen();
          }

          return CreatePasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: AuthRoutes.verifyEmail,
        name: 'verify-email',
        builder: (context, state) {
          final email = state.extra as String?;
          return VerifyEmailScreen(email: email);
        },
      ),
      GoRoute(
        path: AuthRoutes.completeProfile,
        name: 'complete-profile',
        builder: (context, state) => CompleteProfileScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return FeedbackShakeListener(
            child: MainLayoutScreen(navigationShell: navigationShell),
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.community,
                name: 'community',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const CommunityScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: MapRoutes.map,
                name: 'map',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const MapScreen(initialBusinessId: null),
                ),
              ),
              GoRoute(
                path: MapRoutes.negocioDeeplink,
                name: 'negocio-deeplink',
                pageBuilder: (context, state) {
                  final businessId = state.pathParameters['id'];
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: MapScreen(initialBusinessId: businessId),
                  );
                },
              ),
              GoRoute(
                path: MapRoutes.businessDetails,
                name: 'business-details',
                pageBuilder: (context, state) {
                  final businessId = state.pathParameters['id'];
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: MapScreen(initialBusinessId: businessId),
                  );
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: BusinessRoutes.panel,
                name: 'business-panel',
                pageBuilder: (context, state) => NoTransitionPage(
                  key: state.pageKey,
                  child: const _BusinessShellScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: DebuggingRoutes.debugPanel,
                name: 'debug-panel',
                builder: (context, state) => const DebugPanel(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: BusinessRoutes.register,
        name: 'register-business',
        builder: (context, state) => const RegisterBusinessScreen(),
      ),
      GoRoute(
        path: BusinessRoutes.form,
        name: 'business-form',
        builder: (context, state) => const BusinessFormScreen(),
      ),
    ],
    redirect: (context, state) async {
      final path = state.uri.path;
      final container = ProviderScope.containerOf(context, listen: false);
      final isLoggedIn = container.read(authSessionStatusProvider);
      final isPublicAuthRoute =
          path == AuthRoutes.authSelection ||
          path == AuthRoutes.loginEmail ||
          path == AuthRoutes.passwordRecovery ||
          path == AuthRoutes.signupEmail ||
          path == AuthRoutes.createPassword;
      final isVerifyRoute = path == AuthRoutes.verifyEmail;
      final isShellRoute =
          path == AppRoutes.community ||
          path == MapRoutes.map ||
          path == BusinessRoutes.panel ||
          path == DebuggingRoutes.debugPanel ||
          path.startsWith('/negocio/') ||
          path.startsWith('/business/');
      final isGuestAllowedRoute =
          path == AppRoutes.onboarding ||
          path == MapRoutes.map ||
          path == AppRoutes.community ||
          path == BusinessRoutes.panel ||
          path == DebuggingRoutes.debugPanel ||
          path == BusinessRoutes.register ||
          path.startsWith('/negocio/') ||
          path.startsWith('/business/');

      if (!isLoggedIn) {
        if (!isPublicAuthRoute && !isGuestAllowedRoute && !isVerifyRoute) {
          return AuthRoutes.authSelection;
        }

        return null;
      }

      if (isShellRoute) {
        return null;
      }

      final emailVerificationUsecase = container.read(
        emailVerificationUsecaseProvider,
      );
      final isEmailVerifiedResult = await emailVerificationUsecase
          .isEmailVerified();
      final isEmailVerified = isEmailVerifiedResult.fold(
        (_) => false,
        (value) => value,
      );

      if (!isEmailVerified) {
        if (!isVerifyRoute) {
          return AuthRoutes.verifyEmail;
        }

        return null;
      }

      final hasProfileUsecase = container.read(hasProfileUsecaseProvider);
      final hasProfileResult = await hasProfileUsecase.checkHasProfile();
      final hasProfile = hasProfileResult.fold((_) => false, (value) => value);

      if (!hasProfile) {
        if (path != AuthRoutes.completeProfile) {
          return AuthRoutes.completeProfile;
        }

        return null;
      }

      if (isVerifyRoute ||
          isPublicAuthRoute ||
          path == AuthRoutes.completeProfile ||
          path == AppRoutes.onboarding) {
        return MapRoutes.map;
      }

      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: OurnegoColorTokens.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.uri.path}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(MapRoutes.map),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

Stream<dynamic> _defaultAuthStateChanges() {
  try {
    return Supabase.instance.client.auth.onAuthStateChange;
  } catch (_) {
    return const Stream<dynamic>.empty();
  }
}

class _BusinessShellScreen extends ConsumerWidget {
  const _BusinessShellScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOwnerAsync = ref.watch(isOwnerProvider);

    return isOwnerAsync.when(
      data: (isOwner) {
        if (isOwner) {
          return const BusinessPanelScreen();
        }

        return const RegisterBusinessScreen();
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const RegisterBusinessScreen(),
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
