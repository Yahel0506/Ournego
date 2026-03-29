import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/presentation/pages/business_form_screen.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';

import '../../../feedback/presentation/widgets/feedback_dialog_widget.dart';

class RegisterBusinessWidget extends ConsumerWidget {
  const RegisterBusinessWidget({super.key});

  Future<void> _showSessionErrorDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const InformationCardWidget(
                  title: 'No se pudo verificar tu sesion',
                  description:
                      'Intenta de nuevo en unos segundos. Si el problema continua, envianos feedback.',
                  imagePath: 'assets/images/generic_error.png',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.of(dialogContext).pop();
                            if (ref.read(isFeedbackDialogOpenProvider)) {
                              return;
                            }
                            ref
                                .read(isFeedbackDialogOpenProvider.notifier)
                                .setIsOpen();
                            await showDialog<void>(
                              context: context,
                              builder: (_) => const FeedbackDialogWidget(),
                            );
                            ref
                                .read(isFeedbackDialogOpenProvider.notifier)
                                .setIsClosed();
                          },
                          child: const Text('Feedback'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          child: const Text('Entiendo'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: Image.asset('assets/images/register_business.png'),
          ),
          const SizedBox(height: 24),
          const Text('Registra tu negocio', style: OurnegoTextStyles.header),
          SizedBox(height: 8),
          const Text(
            'Comienza a crecer creando tu negocio en Ournego, y desbloquea grandes funcionalidades.',
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              try {
                final isLogged = ref.read(authSessionStatusProvider);
                if (!context.mounted) return;

                if (isLogged) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const BusinessFormScreen(),
                    ),
                  );
                } else {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AuthSelectionScreen(),
                      settings: const RouteSettings(name: '/authSelection'),
                    ),
                  );
                }
              } catch (_) {
                if (!context.mounted) return;
                await _showSessionErrorDialog(context, ref);
              }
              /*final isLoggedInResult = await CheckIfLoggedUsecase(repository)();

              isLoggedInResult.fold(
                (failure) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Ha habido un error. Por favor, inténtalo de nuevo.',
                        style: OurnegoTextStyles.errorText,
                      ),
                    ),
                  );
                },
                (isLoggedIn) {
                  if (isLoggedIn) {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => BusinessFormScreen(),
                      ),
                    );
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AuthSelectionScreen(),
                        settings: RouteSettings(name: '/authSelection'),
                      ),
                    );
                  }
                },
              );*/
            },
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.secondary,
              ),
              foregroundColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.onSecondary,
              ),
              overlayColor: WidgetStatePropertyAll(
                Theme.of(context).colorScheme.secondaryContainer,
              ),
              fixedSize: WidgetStatePropertyAll(const Size(200, 60)),
            ),
            child: const Text('Comenzar', style: OurnegoTextStyles.header),
          ),
        ],
      ),
    );
  }
}
