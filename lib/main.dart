import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, debugPrint;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

// Conditional import for web-specific environment configuration
import 'package:ournego/core/debugging/simulation/debug_restart_scope.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_badge.dart';
import 'package:ournego/core/debugging/simulation/debug_simulation_controller.dart';
import 'package:ournego/core/debugging/simulation/debug_overrides.dart';
import 'package:ournego/core/debugging/simulation/simulated_http_client.dart';
import 'package:ournego/core/debugging/simulation/simulated_startup_failure_banner.dart';
import 'package:ournego/core/debugging/simulation/startup_fault_interceptors.dart';
import 'package:ournego/core/env_config_stub.dart'
    if (dart.library.js_interop) 'package:ournego/core/env_config_web.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/routing/app_router.dart';
import 'package:ournego/core/startup/ournego_splash_animation.dart';
import 'package:ournego/core/startup/startup_controller.dart';
import 'package:ournego/core/startup/startup_gate.dart';
import 'package:ournego/features/auth/presentation/widgets/session_expired_listener.dart';
import 'package:ournego/features/onboarding/data/datasources/local_onboarding_datasource.dart';
import 'package:ournego/shared/widgets/ournego_offline_banner.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Debug builds can simulate startup faults; release builds skip all of it.
  final simulation = kDebugMode
      ? await DebugSimulationController.bootstrap()
      : null;
  final simulatedHttpClient = simulation == null
      ? null
      : SimulatedHttpClient(mode: () => simulation.value.networkMode);

  runApp(
    BetterFeedback(
      child: DebugRestartScope(
        builder: (context) => ProviderScope(
          overrides: [
            if (simulation != null && simulatedHttpClient != null)
              ...debugSimulationOverrides(simulation, simulatedHttpClient),
          ],
          child: StartupGate(
            controller: StartupController.production(
              isWeb: kIsWeb,
              webValue: getWebEnvVariable,
              readOnboarding: LocalOnboardingDatasource().hasSeenOnboarding,
              interceptors: simulation == null
                  ? null
                  : startupInterceptorsFor(
                      simulation.value.startupFault,
                      httpClient: simulatedHttpClient,
                    ),
            ),
            simulatedFailureBannerBuilder: simulation == null
                ? null
                : (context) =>
                      SimulatedStartupFailureBanner(controller: simulation),
            splashBuilder: kIsWeb
                ? null
                : (onAnimationCompleted) => OurnegoSplashAnimation(
                    onAnimationCompleted: onAnimationCompleted,
                  ),
            appBuilder: (startOnMap) {
              final app = MyApp(startOnMap: startOnMap);
              return kIsWeb ? AuthStateListener(child: app) : app;
            },
          ),
        ),
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final bool startOnMap;
  final Stream<dynamic>? authStateChanges;

  const MyApp({super.key, required this.startOnMap, this.authStateChanges});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late final GoRouter _router = createAppRouter(
    startOnMap: widget.startOnMap,
    authStateChanges: widget.authStateChanges,
    navigatorKey: _navigatorKey,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
      builder: (context, child) {
        final content = OurnegoOfflineBanner(
          child: SessionExpiredListener(
            navigatorKey: _navigatorKey,
            child: child ?? const SizedBox.shrink(),
          ),
        );
        if (!kDebugMode) return content;
        return DebugSimulationBadge(child: content);
      },
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Ournego',
      theme: OurnegoColors.lightTheme,
      darkTheme: OurnegoColors.darkTheme,
    );
  }
}

/// Widget que escucha cambios en el estado de autenticación
/// Útil para manejar el callback de OAuth en web
class AuthStateListener extends StatefulWidget {
  final Widget child;

  const AuthStateListener({super.key, required this.child});

  @override
  State<AuthStateListener> createState() => _AuthStateListenerState();
}

class _AuthStateListenerState extends State<AuthStateListener> {
  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      // Escuchar cambios de autenticación para manejar el callback de OAuth
      Supabase.instance.client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        if (session != null && mounted) {
          // Usuario autenticado, verificar si tiene perfil
          _checkAndCreateProfile();
        }
      });
    }
  }

  Future<void> _checkAndCreateProfile() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final userId = user?.id;
      if (userId == null) return;

      final identities = user?.identities ?? const [];
      final hasGoogleIdentity = identities.any(
        (identity) => identity.provider == 'google',
      );

      if (!hasGoogleIdentity) {
        return;
      }

      final data = await Supabase.instance.client
          .from('users')
          .select('has_profile')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // No existe el usuario en la tabla, crearlo
        await Supabase.instance.client.from('users').insert({
          'id': userId,
          'name':
              user?.userMetadata?['full_name'] ?? user?.email?.split('@')[0],
          'has_profile': true,
        });
      }
    } catch (e) {
      debugPrint('Error al verificar/crear perfil: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
