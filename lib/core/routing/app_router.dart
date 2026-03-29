import 'package:flutter/material.dart';

import 'package:go_router/go_router.dart';

import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/features/auth/presentation/pages/complete_profile_screen.dart';
import 'package:ournego/features/auth/presentation/pages/create_password_screen.dart';
import 'package:ournego/features/auth/presentation/pages/login_email_screen.dart';
import 'package:ournego/features/auth/presentation/pages/signup_email_screen.dart';
import 'package:ournego/features/business/presentation/pages/business_form_screen.dart';
import 'package:ournego/features/business/presentation/pages/register_business_screen.dart';
import 'package:ournego/features/navigation/presentation/pages/main_layout_screen.dart';
import 'package:ournego/features/onboarding/presentation/pages/onboarding_screen.dart';

/// Creates the app's GoRouter configuration.
///
/// This is the single source of truth for all navigation in the app.
/// Routes are organized by feature and support:
/// - Initial location based on onboarding state
/// - Shell routes for persistent layouts
/// - Auth guards (to be implemented in Phase 4)
/// - Deep linking support
///
/// Usage in main.dart:
/// ```dart
/// MaterialApp.router(
///   routerConfig: createAppRouter(startOnMap: hasSeenOnboarding),
/// )
/// ```
GoRouter createAppRouter({required bool startOnMap}) {
  return GoRouter(
    // Set initial location based on whether user has seen onboarding
    initialLocation: startOnMap ? MapRoutes.map : AppRoutes.onboarding,

    // Enable debug logging in development
    debugLogDiagnostics: true,

    routes: [
      // |---------------------------------| \\
      // |------- ONBOARDING -------------| \\
      // |---------------------------------| \\
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // |---------------------------------| \\
      // |------- AUTH ROUTES -------------| \\
      // |---------------------------------| \\
      GoRoute(
        path: AuthRoutes.authSelection,
        name: 'auth-selection',
        builder: (context, state) => const AuthSelectionScreen(),
      ),
      GoRoute(
        path: AuthRoutes.loginEmail,
        name: 'login-email',
        builder: (context, state) => const LoginEmailScreen(),
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
          // Email should be passed as extra data when navigating
          final email = state.extra as String?;
          if (email == null) {
            // If no email, redirect to signup
            return const SignupEmailScreen();
          }
          return CreatePasswordScreen(email: email);
        },
      ),
      GoRoute(
        path: AuthRoutes.completeProfile,
        name: 'complete-profile',
        builder: (context, state) => CompleteProfileScreen(),
      ),

      // |---------------------------------| \\
      // |------- MAIN APP SHELL ----------| \\
      // |---------------------------------| \\

      // ShellRoute provides persistent bottom navigation
      // Will be fully implemented in Phase 4
      ShellRoute(
        builder: (context, state, child) {
          // For now, just pass through to MainLayoutScreen
          // In Phase 4, this will be refactored
          return child;
        },
        routes: [
          // Map Screen (Main)
          GoRoute(
            path: MapRoutes.map,
            name: 'map',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MainLayoutScreen(),
            ),
          ),

          // Business Panel
          GoRoute(
            path: BusinessRoutes.panel,
            name: 'business-panel',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MainLayoutScreen(),
            ),
          ),

          // Community
          GoRoute(
            path: AppRoutes.community,
            name: 'community',
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const MainLayoutScreen(),
            ),
          ),

          // Business Panel
          GoRoute(
            path: BusinessRoutes.panel,
            name: 'business-panel',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MainLayoutScreen()),
          ),

          // Community
          GoRoute(
            path: AppRoutes.community,
            name: 'community',
            pageBuilder: (context, state) =>
                const NoTransitionPage(child: MainLayoutScreen()),
          ),

          // Business Panel
          GoRoute(
            path: BusinessRoutes.panel,
            name: 'business-panel',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const MainLayoutScreen()),
          ),

          // Community
          GoRoute(
            path: AppRoutes.community,
            name: 'community',
            pageBuilder: (context, state) =>
                NoTransitionPage(child: const MainLayoutScreen()),
          ),
        ],
      ),

      // |---------------------------------| \\
      // |------- BUSINESS ROUTES ---------| \\
      // |---------------------------------| \\
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

      // Business Details (with parameter)
      GoRoute(
        path: MapRoutes.businessDetails,
        name: 'business-details',
        builder: (context, state) {
          final businessId = state.pathParameters['id'];
          if (businessId == null) {
            // Handle error - redirect to map
            return const MainLayoutScreen();
          }
          // TODO: Create BusinessDetailsScreen in future phases
          return const MainLayoutScreen();
        },
      ),
    ],

    // |---------------------------------| \\
    // |------- ERROR HANDLING ----------| \\
    // |---------------------------------| \\
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
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

    // |---------------------------------| \\
    // |------- REDIRECTS / GUARDS ------| \\
    // |---------------------------------| \\

    // Auth guards will be implemented in Phase 4
    // For now, allow all navigation
    redirect: (context, state) {
      // TODO Phase 4: Add auth guard logic
      // - Check if logged in
      // - Check if has profile
      // - Redirect to appropriate screen
      return null; // null = no redirect, allow navigation
    },
  );
}
