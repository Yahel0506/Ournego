import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Conditional import for web-specific environment configuration
import 'package:ournego/core/env_config_stub.dart'
    if (dart.library.js_interop) 'package:ournego/core/env_config_web.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/routing/app_router.dart';
import 'package:ournego/features/onboarding/data/datasources/local_onboarding_datasource.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool hasSeenOnboarding = false;

  try {
    String supabaseUrl;
    String supabaseAnonKey;

    if (kIsWeb) {
      // For web, get variables from window.ENV (loaded from config.js)
      supabaseUrl = getWebEnvVariable('SUPABASE_URL');
      supabaseAnonKey = getWebEnvVariable('SUPABASE_ANON_KEY');
    } else {
      // For mobile/desktop, use String.fromEnvironment or flutter_dotenv
      supabaseUrl = const String.fromEnvironment('SUPABASE_URL');
      supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');

      // If not provided via --dart-define, try loading from .env file
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        await dotenv.load(fileName: '.env');
        supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      }
    }

    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      throw Exception('Supabase credentials not found in environment');
    }

    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

    final onboardingDatasource = LocalOnboardingDatasource();
    hasSeenOnboarding = await onboardingDatasource.hasSeenOnboarding();
  } catch (e) {
    print('Error loading environment variables: $e');
    // Continue with default value for hasSeenOnboarding
  }

  runApp(
    BetterFeedback(
      child: ProviderScope(
        child: kIsWeb
            ? AuthStateListener(child: MyApp(startOnMap: hasSeenOnboarding))
            : MyApp(startOnMap: hasSeenOnboarding),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool startOnMap;

  const MyApp({super.key, required this.startOnMap});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: createAppRouter(startOnMap: startOnMap),
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
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await Supabase.instance.client
          .from('users')
          .select('has_profile')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        // No existe el usuario en la tabla, crearlo
        final user = Supabase.instance.client.auth.currentUser;
        await Supabase.instance.client.from('users').insert({
          'id': userId,
          'name':
              user?.userMetadata?['full_name'] ?? user?.email?.split('@')[0],
          'has_profile': true,
        });
      }
    } catch (e) {
      print('Error al verificar/crear perfil: $e');
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
