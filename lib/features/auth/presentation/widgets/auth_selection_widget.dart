import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthSelectionWidget extends ConsumerWidget {
  final VoidCallback? onSuccess;

  const AuthSelectionWidget({super.key, required this.onSuccess});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    final String themedImagePath = isDarkMode
        ? 'assets/images/ournego_white.png'
        : 'assets/images/ournego.png';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 108.0),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
          border: BoxBorder.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              const Spacer(),
              // Logo de Ournego
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Image(image: AssetImage(themedImagePath)),
              ),
              const SizedBox(height: 30),
              // Título de la Sección
              Text('Empieza a crecer.', style: OurnegoTextStyles.header),
              const SizedBox(height: 30),
              // Columna de botones
              Column(
                children: [
                  GoogleLoginButton(config: this),
                  const SizedBox(height: 15),
                  MailLoginButton(config: this),
                  const SizedBox(height: 15),
                  // PhoneLoginButton(config: this),
                  const SizedBox(height: 30),
                  GuestAccessButton(config: this),
                ],
              ),
              const SizedBox(height: 60),
              // Términos y condiciones
              TermsRichText(config: this),
              const Spacer(),
            ],
          ),
        ),
      ),
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
          text: 'Al continuar, aceptas nuestros ',
          style: OurnegoTextStyles.body.merge(
            TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          ),
          children: [
            TextSpan(
              text: 'Términos y Condiciones',
              style: OurnegoTextStyles.link,
              recognizer: TapGestureRecognizer()
                ..onTap = () => launchTermsUrl(
                  'https://www.ournego.com/terms-and-conditions',
                ),
            ),
            TextSpan(text: ' y '),
            TextSpan(
              text: 'Política de Privacidad',
              style: OurnegoTextStyles.link,
              recognizer: TapGestureRecognizer()
                ..onTap = () =>
                    launchTermsUrl('https://www.ournego.com/privacy-policy'),
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
    final setHasSeenOnboarding = ref.read(setHasSeenOnboardingUsecaseProvider);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        key: const ValueKey('guestAccessButton'),
        onPressed: () async {
          await setHasSeenOnboarding();

          if (config.onSuccess != null) {
            config.onSuccess!();
          }
        },
        style: OurnegoButtonStyles.authOutlinedOnSurface(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.person, size: 25),
            const Spacer(),
            Text('Continuar como invitado'),
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
        style: OurnegoButtonStyles.authOutlinedOnSurface(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.phone, size: 25),
            const Spacer(),
            Text('Continuar con número telefónico'),
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
        key: const ValueKey('emailAccessButton'),
        onPressed: () {
          context.push(AuthRoutes.loginEmail);
        },
        style: OurnegoButtonStyles.authOutlinedOnSurface(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.email, size: 25),
            const Spacer(),
            Text('Continuar con correo'),
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
    final setHasSeenOnboarding = ref.read(setHasSeenOnboardingUsecaseProvider);

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () async {
          await setHasSeenOnboarding();
          final googleSignIn = await ref.read(
            signInWithGoogleUsecaseProvider,
          )();
          googleSignIn.fold(
            (failure) {
              ScaffoldMessenger.of(context).showSnackBar(
                OurnegoSnackbars.info('Error: ${failure.toString()}'),
              );
            },
            (_) async {
              if (config.onSuccess != null) {
                config.onSuccess!();
              }
            },
          );
        },
        style: OurnegoButtonStyles.authFilledOnSurface(context),
        child: Row(
          children: [
            // Asegúrate de que esta imagen exista
            Image.asset('assets/images/google.png', width: 25),
            const Spacer(),
            Text('Continuar con Google'),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
