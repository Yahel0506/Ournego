import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/features/navigation/presentation/pages/main_layout_screen.dart';
import 'package:ournego/features/onboarding/presentation/pages/onboarding_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();
// TODO: (Security) Move Supabase URL and anonKey to secure storage or
// environment variables. Avoid committing secrets into source control.
// Perspective: Add a config loader that reads from `.env` or platform
// secure storage and fail loudly if keys are missing.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await Supabase.initialize(
    // TODO: load these values from secure config (not hardcoded)
    url: 'https://qixuodrtemljgppdlmvc.supabase.co',
    anonKey: 'sb_secret_t9Axhc3n2DDnyYvmsiypnA_mBEYlBxH',
  );

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

  runApp(ProviderScope(child: MyApp(startOnMap: hasSeenOnboarding)));
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
      title: 'Ournego',
      theme: OurnegoColors.lightTheme,
      darkTheme: OurnegoColors.darkTheme,
      home: homeWidget,
    );
  }
}
