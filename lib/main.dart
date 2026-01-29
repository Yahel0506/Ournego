import 'package:feedback/feedback.dart';
import 'package:flutter/gestures.dart';

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

final RouteObserver<ModalRoute<void>> routeObserver =
    RouteObserver<ModalRoute<void>>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Remove all Firebase references if not used
  // await Firebase.initializeApp();

  await dotenv.load(fileName: ".env");

  await Supabase.initialize(
    url:
        dotenv.env['SUPABASE_URL'] ??
        (throw Exception('SUPABASE_URL not found in environment (.env)')),
    anonKey:
        dotenv.env['SUPABASE_ANON_KEY'] ??
        (throw Exception('SUPABASE_ANON_KEY not found in environment (.env)')),
  );

  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool('hasSeenOnboarding') ?? false;

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
