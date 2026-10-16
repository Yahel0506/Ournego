import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/routing/container_transform_page.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/nego/nego_avatar.dart';
import 'package:ournego/shared/widgets/nego/nego_mood.dart';

import 'package:ournego/features/feedback/presentation/widgets/feedback_flow.dart';

/// Measured when "Comenzar" is tapped, so the next page grows out of the button.
final _startButtonKey = GlobalKey(debugLabel: 'registerStartButton');
final _registerNegoKey = GlobalKey(debugLabel: 'registerNego');

class RegisterBusinessWidget extends ConsumerWidget {
  const RegisterBusinessWidget({super.key});

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
                NegoAvatar(
                  key: _registerNegoKey,
                  size: 180,
                  mood: NegoMood.happy,
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
                OurnegoButton.primary(
                  key: _startButtonKey,
                  size: OurnegoButtonSize.large,
                  minWidth: 200,
                  label: 'Comenzar',
                  showNego: true,
                  onPressed: () async {
                    try {
                      final isLogged = ref.read(authSessionStatusProvider);
                      if (!context.mounted) return;

                      final buttonContext = _startButtonKey.currentContext;
                      final from = buttonContext == null
                          ? null
                          : ContainerTransformRouteExtra.measure(
                              buttonContext,
                              radius: 24,
                              color: Theme.of(context).colorScheme.primary,
                              // The big mascot flies to the form's header.
                              sharedFrom:
                                  isLogged &&
                                      _registerNegoKey.currentContext != null
                                  ? globalRectOf(
                                      _registerNegoKey.currentContext!,
                                    )
                                  : null,
                            );
                      if (isLogged) {
                        context.push(BusinessRoutes.form, extra: from);
                      } else {
                        context.push(AuthRoutes.authSelection, extra: from);
                      }
                    } catch (_) {
                      if (!context.mounted) return;
                      await showSessionErrorDialog(context, ref);
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
