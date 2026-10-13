import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/nego/nego_avatar.dart';
import 'package:ournego/shared/widgets/nego/nego_mood.dart';
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
                child: OurnegoButton.secondary(
                  size: OurnegoButtonSize.compact,
                  expanded: true,
                  label: 'Feedback',
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
                ),
              ),
              const SizedBox(width: OurnegoSpacingTokens.sm),
              Expanded(
                child: OurnegoButton.primary(
                  size: OurnegoButtonSize.compact,
                  expanded: true,
                  label: 'Entiendo',
                  onPressed: () => Navigator.of(dialogContext).pop(),
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
                NegoAvatar(size: 180, mood: NegoMood.happy),
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
                OurnegoButton.primary(
                  size: OurnegoButtonSize.large,
                  minWidth: 200,
                  label: 'Comenzar',
                  showNego: true,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
