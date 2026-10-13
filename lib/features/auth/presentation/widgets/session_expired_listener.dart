import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/session_expiry_providers.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

/// Shows a non-blocking dialog when the session is lost without a logout.
/// Needs [navigatorKey] because it sits above the router's Navigator.
class SessionExpiredListener extends ConsumerWidget {
  const SessionExpiredListener({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<SessionExpiryStatus>(sessionExpiryProvider, (previous, next) {
      if (next != SessionExpiryStatus.expired) return;
      final navContext = navigatorKey.currentContext;
      if (navContext == null) return;

      final location = GoRouter.of(navContext).state.uri.toString();
      final notifier = ref.read(sessionExpiryProvider.notifier);

      showOurnegoDialog<void>(
        context: navContext,
        barrierDismissible: false,
        builder: (dialogContext) => OurnegoAlertDialog(
          title: 'Tu sesión venció',
          content:
              'Por seguridad, vuelve a iniciar sesión para seguir usando tu cuenta.',
          primaryAction: OurnegoDialogAction(
            label: 'Iniciar sesión',
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(pendingReturnLocationProvider.notifier).set(location);
              GoRouter.of(navContext).go(AuthRoutes.authSelection);
            },
          ),
          secondaryAction: OurnegoDialogAction(
            label: 'Seguir como invitado',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ),
      ).whenComplete(notifier.acknowledge);
    });
    return child;
  }
}
