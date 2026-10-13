import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/onboarding/presentation/providers/onboarding_providers.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';
import 'package:url_launcher/url_launcher.dart';

class AuthSelectionWidget extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;
  final bool isFromOnboarding;

  const AuthSelectionWidget({
    super.key,
    required this.onSuccess,
    this.isFromOnboarding = false,
  });

  @override
  ConsumerState<AuthSelectionWidget> createState() =>
      _AuthSelectionWidgetState();
}

class _AuthSelectionWidgetState extends ConsumerState<AuthSelectionWidget> {
  @override
  Widget build(BuildContext context) {
    final Brightness brightness = MediaQuery.of(context).platformBrightness;
    final bool isDarkMode = brightness == Brightness.dark;

    final String themedImagePath = isDarkMode
        ? 'assets/images/ournego_white.png'
        : 'assets/images/ournego.png';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 108.0),
      child: OurnegoContentContainer(
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
                GoogleLoginButton(config: widget),
                const SizedBox(height: 15),
                MailLoginButton(config: widget),
                const SizedBox(height: 15),
                // PhoneLoginButton(config: this),
                if (widget.isFromOnboarding) ...[
                  const SizedBox(height: 30),
                  GuestAccessButton(config: widget),
                ],
              ],
            ),
            const SizedBox(height: 60),
            // Términos y condiciones
            TermsRichText(config: widget),
            const Spacer(),
          ],
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

    return OurnegoSocialButton(
      key: const ValueKey('guestAccessButton'),
      leading: const Icon(Icons.person_rounded),
      label: 'Continuar como invitado',
      onPressed: () async {
        await setHasSeenOnboarding();
        if (!context.mounted) return;
        context.go(MapRoutes.map);
      },
    );
  }
}

class PhoneLoginButton extends ConsumerWidget {
  const PhoneLoginButton({super.key, required this.config});

  final AuthSelectionWidget config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Disabled on purpose: phone login does not exist yet.
    return const OurnegoSocialButton(
      leading: Icon(Icons.call_rounded),
      label: 'Continuar con número telefónico',
      badge: 'Pronto',
      onPressed: null,
    );
  }
}

class MailLoginButton extends ConsumerWidget {
  const MailLoginButton({super.key, required this.config});

  final AuthSelectionWidget config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OurnegoSocialButton(
      key: const ValueKey('emailAccessButton'),
      leading: const Icon(Icons.mail_rounded),
      label: 'Continuar con correo',
      onPressed: () {
        context.push(AuthRoutes.loginEmail);
      },
    );
  }
}

class GoogleLoginButton extends ConsumerWidget {
  const GoogleLoginButton({super.key, required this.config});

  final AuthSelectionWidget config;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setHasSeenOnboarding = ref.read(setHasSeenOnboardingUsecaseProvider);

    return OurnegoSocialButton.google(
      onPressed: () async {
        await setHasSeenOnboarding();
        if (!context.mounted) return;
        final googleSignIn = await ref.read(signInWithGoogleUsecaseProvider)();
        if (!context.mounted) return;
        googleSignIn.fold(
          (failure) {
            ScaffoldMessenger.of(context).showSnackBar(
              OurnegoSnackbars.info('Error: ${failure.toString()}'),
            );
          },
          (_) async {
            if (!kIsWeb && config.onSuccess != null) {
              config.onSuccess!();
            }
          },
        );
      },
    );
  }
}
