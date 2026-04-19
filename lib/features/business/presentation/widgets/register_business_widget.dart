import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/shared/widgets/ournego_information_dialog.dart';

import '../../../feedback/presentation/widgets/feedback_dialog_widget.dart';

class RegisterBusinessWidget extends ConsumerWidget {
  const RegisterBusinessWidget({super.key});

  Future<void> _showSessionErrorDialog(BuildContext context, WidgetRef ref) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return OurnegoInformationDialog(
          title: 'No se pudo verificar tu sesion',
          description:
              'Intenta de nuevo en unos segundos. Si el problema continua, envianos feedback.',
          imagePath: 'assets/images/generic_error.png',
          actions: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    if (ref.read(isFeedbackDialogOpenProvider)) {
                      return;
                    }
                    ref.read(isFeedbackDialogOpenProvider.notifier).setIsOpen();
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 180,
                  child: Image.asset('assets/images/register_business.png'),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Registra tu negocio',
                  style: OurnegoTextStyles.header,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Comienza a crecer creando tu negocio en Ournego, y desbloquea grandes funcionalidades.',
                  style: OurnegoTextStyles.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final isLogged = ref.read(authSessionStatusProvider);
                      if (!context.mounted) return;

                      if (isLogged) {
                        context.push(BusinessRoutes.form);
                      } else {
                        context.push(AuthRoutes.authSelection);
                      }
                    } catch (_) {
                      if (!context.mounted) return;
                      await _showSessionErrorDialog(context, ref);
                    }
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
                  child: const Text(
                    'Comenzar',
                    style: OurnegoTextStyles.header,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
