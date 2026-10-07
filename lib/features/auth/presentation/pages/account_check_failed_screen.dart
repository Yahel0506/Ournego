import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/network/connectivity_providers.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';

/// Shown when a signed-in user's account could not be checked because the
/// network is unavailable. Retries by itself when connectivity returns.
class AccountCheckFailedScreen extends ConsumerWidget {
  const AccountCheckFailedScreen({super.key});

  void _retry(BuildContext context) => context.go(AuthRoutes.authCompletion);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(isOnlineProvider, (previous, next) {
      if (previous == false && next && context.mounted) _retry(context);
    });

    return OurnegoPageLayout(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 20),
          const Text(
            'No pudimos verificar tu cuenta',
            style: OurnegoTextStyles.header,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Revisa tu conexión e inténtalo de nuevo.',
            style: OurnegoTextStyles.bodyCompact,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          OurnegoPrimaryButton(
            buttonKey: const Key('account-check-retry'),
            onPressed: () => _retry(context),
            child: const Text('Reintentar'),
          ),
          const SizedBox(height: 12),
          TextButton(
            key: const Key('account-check-continue'),
            onPressed: () => context.go(MapRoutes.map),
            child: const Text(
              'Continuar al mapa',
              style: OurnegoTextStyles.button,
            ),
          ),
        ],
      ),
    );
  }
}
