import 'package:feedback/feedback.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/features/navigation/presentation/pages/main_layout_screen.dart';
import 'package:ournego/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Conditional import for web-specific environment configuration
import 'package:ournego/core/env_config_stub.dart'
    if (dart.library.js_interop) 'package:ournego/core/env_config_web.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Remove all Firebase references if not used
  // await Firebase.initializeApp();

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

    final prefs = await SharedPreferences.getInstance();
    hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;
  } catch (e) {
    print('Error loading environment variables: $e');
    // Continue with default value for hasSeenOnboarding
  }

  runApp(
    BetterFeedback(
      child: ProviderScope(child: MyApp(startOnMap: hasSeenOnboarding)),
    ),
  );
}

class MyApp extends StatelessWidget {
  final bool startOnMap;

  const MyApp({super.key, required this.startOnMap});

  @override
  Widget build(BuildContext context) {
    Widget homeWidget = startOnMap
        ? const MainLayoutScreen()
        : const OnboardingScreen();
    return MaterialApp(
      navigatorObservers: [routeObserver],
      scrollBehavior: MyCustomScrollBehavior(),
      title: 'Ournego',
      theme: OurnegoColors.lightTheme,
      darkTheme: OurnegoColors.darkTheme,
      home: homeWidget,
    );
  }
}

class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
