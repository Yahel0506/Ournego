import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/presentation/pages/login_email_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthSelectionWidget extends ConsumerWidget {
  final String title;
  final String imagePath;
  final String darkImagePath;
  final String googleLogin;
  final String emailLogin;
  final String phoneLogin;
  final String guestAccess;
  final String termsText1;
  final String termsText2;
  final String termsText3;
  final String termsText4;
  final VoidCallback? onSuccess;

  const AuthSelectionWidget({
    super.key,
    required this.title,
    required this.imagePath,
    required this.darkImagePath,
    required this.googleLogin,
    required this.emailLogin,
    required this.phoneLogin,
    required this.guestAccess,
    required this.termsText1,
    required this.termsText2,
    required this.termsText3,
    required this.termsText4,
    required this.onSuccess,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    final String themedImagePath = isDarkMode ? darkImagePath : imagePath;

    return Column(
      children: [
        const Spacer(),
        // Logo de Ournego
        SizedBox(
          height: 60,
          width: 300,
          child: Image(image: AssetImage(themedImagePath)),
        ),
        const SizedBox(height: 50),
        // Título de la Sección
        Text(title, style: OurnegoTextStyles.header),
        const SizedBox(height: 30),
        // Columna de botones
        SizedBox(
          width: 300,
          height: 280,
          child: Column(
            children: [
              GoogleLoginButton(config: this),
              const SizedBox(height: 15),
              MailLoginButton(config: this),
              const SizedBox(height: 15),
              PhoneLoginButton(config: this),
              const SizedBox(height: 30),
              GuestAccessButton(config: this),
            ],
          ),
        ),
        const SizedBox(height: 60),
        // Términos y condiciones
        TermsRichText(config: this),
        const Spacer(),
      ],
    );
  }
}

// -----------------------------------------------------------
// SUB-WIDGETS (Refactorizados para recibir la configuración)
// -----------------------------------------------------------

class TermsRichText extends StatelessWidget {
  const TermsRichText({super.key, required this.config});

  final AuthSelectionWidget config;

  @override
  Widget build(BuildContext context) {
    Future<void> launchTermsUrl(String urlString) async {
      final Uri url = Uri.parse(urlString);
      if (!await launchUrl(url)) {
        throw Exception('Could not launch $url');
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: config.termsText1,
          style: OurnegoTextStyles.body.merge(
            TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          children: [
            TextSpan(
              text: config.termsText2,
              style: OurnegoTextStyles.link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchTermsUrl('https://ournego.framer.website/terms-and-conditions'),
            ),
            TextSpan(text: config.termsText3),
            TextSpan(
              text: config.termsText4,
              style: OurnegoTextStyles.link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchTermsUrl('https://ournego.framer.website/privacy-policy'),
            ),
          ],
        ),
      ),
    );
  }
}

class GuestAccessButton extends ConsumerWidget {
  const GuestAccessButton({super.key, required this.config});

  final AuthSelectionWidget config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('hasSeenOnboarding', true);

          if (config.onSuccess != null) {
            config.onSuccess!();
          }
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            width: 3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 25),
            const Spacer(),
            Text(config.guestAccess),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class PhoneLoginButton extends ConsumerWidget {
  const PhoneLoginButton({super.key, required this.config});
  final AuthSelectionWidget config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {},
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            width: 3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone, size: 25),
            const Spacer(),
            Text(config.phoneLogin),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class MailLoginButton extends ConsumerWidget {
  const MailLoginButton({super.key, required this.config});
  final AuthSelectionWidget config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute<void>(builder: (context) => LoginEmailScreen()),
          );
        },
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            width: 3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          foregroundColor: Theme.of(context).colorScheme.onSurface,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 25),
            const Spacer(),
            Text(config.emailLogin),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

class GoogleLoginButton extends ConsumerWidget {
  const GoogleLoginButton({super.key, required this.config});
  final AuthSelectionWidget config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () {
          // ref.read(authControllerProvider.notifier).loginWithGoogle();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.onSurface,
          foregroundColor: Theme.of(context).colorScheme.surface,
        ),
        child: Row(
          children: [
            // Asegúrate de que esta imagen exista
            Image.asset('assets/images/google.png', width: 25),
            const Spacer(),
            Text(config.googleLogin),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
