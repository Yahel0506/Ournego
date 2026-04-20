import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, this.email});

  final String? email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  static const int _resendCooldownSeconds = 30;
  int _secondsRemaining = 0;

  void _startCooldown() {
    setState(() {
      _secondsRemaining = _resendCooldownSeconds;
    });

    Future<void>.delayed(const Duration(seconds: 1), _tickCooldown);
  }

  void _tickCooldown() {
    if (!mounted || _secondsRemaining <= 0) {
      return;
    }

    setState(() {
      _secondsRemaining -= 1;
    });

    if (_secondsRemaining > 0) {
      Future<void>.delayed(const Duration(seconds: 1), _tickCooldown);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(emailVerificationStatusProvider, (
      previous,
      next,
    ) {
      if (previous?.value == true) {
        return;
      }

      if (next.value == true && context.mounted) {
        context.go(AuthRoutes.completeProfile);
      }
    });

    final verificationStatus = ref.watch(emailVerificationStatusProvider);
    final errorMessages = ref.watch(authErrorMessagesProvider);
    final emailVerificationUsecase = ref.read(emailVerificationUsecaseProvider);
    final currentUserEmail = Supabase.instance.client.auth.currentUser?.email;
    final targetEmail = widget.email ?? currentUserEmail;
    final isCoolingDown = _secondsRemaining > 0;

    return OurnegoPageLayout(
      child: Column(
        children: [
          Text(
            'Revisa tu correo',
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          const Spacer(),
          const Icon(Icons.mark_email_unread_outlined, size: 72),
          const SizedBox(height: 20),
          Text(
            'Te enviamos un enlace de verificacion a: ${targetEmail ?? 'tu correo'}',
            style: OurnegoTextStyles.body,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          verificationStatus.when(
            data: (verified) {
              if (verified) {
                return Text(
                  'Correo verificado. Redirigiendo...',
                  style: OurnegoTextStyles.body,
                  textAlign: TextAlign.center,
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Esperando verificacion...',
                    style: OurnegoTextStyles.body,
                  ),
                ],
              );
            },
            loading: () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 10),
                Text('Comprobando estado...', style: OurnegoTextStyles.body),
              ],
            ),
            error: (_, _) => Text(
              'No pudimos comprobar el estado de verificacion.',
              style: OurnegoTextStyles.body,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 30),
          OurnegoPrimaryButton(
            onPressed: targetEmail == null || isCoolingDown
                ? null
                : () async {
                    _startCooldown();

                    final result = await emailVerificationUsecase
                        .resendVerificationEmail(targetEmail);

                    result.fold(
                      (failure) {
                        if (_secondsRemaining > 0 && mounted) {
                          setState(() {
                            _secondsRemaining = 0;
                          });
                        }

                        final message = errorMessages.getErrorMessage(failure);
                        ScaffoldMessenger.of(context).showSnackBar(
                          OurnegoSnackbars.error(context, message),
                        );
                      },
                      (_) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          OurnegoSnackbars.info(
                            'Correo de verificacion reenviado.',
                          ),
                        );
                      },
                    );
                  },
            child: Text(
              isCoolingDown
                  ? 'Reenviar en ${_secondsRemaining}s'
                  : 'Reenviar correo',
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
