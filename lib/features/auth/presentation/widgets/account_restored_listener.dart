import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/account_restore_providers.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

/// Routes the profile guard always redirects away from once the user is
/// signed in. The notice waits until the router leaves them, so a redirect
/// (to the map or to complete the profile) never tears the dialog down.
const _transientRoutes = {
  AppRoutes.onboarding,
  AuthRoutes.authSelection,
  AuthRoutes.authCompletion,
  AuthRoutes.loginEmail,
  AuthRoutes.passwordRecovery,
  AuthRoutes.signupEmail,
  AuthRoutes.createPassword,
  AuthRoutes.verifyEmail,
  AuthRoutes.accountCheckFailed,
};

@visibleForTesting
bool isSettledLocationForAccountNotice(String path) =>
    !_transientRoutes.contains(path);

/// Tells the user their scheduled account deletion was cancelled when they
/// signed in. Needs [router] and [navigatorKey] because it sits above the
/// router's Navigator.
class AccountRestoredListener extends ConsumerStatefulWidget {
  const AccountRestoredListener({
    super.key,
    required this.router,
    required this.navigatorKey,
    required this.child,
  });

  final GoRouter router;
  final GlobalKey<NavigatorState> navigatorKey;
  final Widget child;

  @override
  ConsumerState<AccountRestoredListener> createState() =>
      _AccountRestoredListenerState();
}

class _AccountRestoredListenerState
    extends ConsumerState<AccountRestoredListener> {
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    widget.router.routerDelegate.addListener(_scheduleShow);
  }

  @override
  void didUpdateWidget(AccountRestoredListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.router != widget.router) {
      oldWidget.router.routerDelegate.removeListener(_scheduleShow);
      widget.router.routerDelegate.addListener(_scheduleShow);
    }
  }

  @override
  void dispose() {
    widget.router.routerDelegate.removeListener(_scheduleShow);
    super.dispose();
  }

  // Router notifications can arrive mid-build; open the dialog after the frame.
  void _scheduleShow() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
  }

  void _maybeShow() {
    if (!mounted || _showing) return;
    if (ref.read(accountRestoreProvider) != AccountRestoreStatus.restored) {
      return;
    }
    final navContext = widget.navigatorKey.currentContext;
    if (navContext == null) return;
    final path = widget.router.state.uri.path;
    if (!isSettledLocationForAccountNotice(path)) return;

    _showing = true;
    showOurnegoDialog<void>(
      context: navContext,
      builder: (dialogContext) => OurnegoAlertDialog(
        title: 'Restauramos tu cuenta',
        content:
            'Tu cuenta estaba programada para eliminarse; la restauramos. '
            'Tus datos y negocios siguen como los dejaste.',
        primaryAction: OurnegoDialogAction(
          key: const ValueKey('account-restored-ok'),
          label: 'Entendido',
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ),
    ).whenComplete(() {
      _showing = false;
      if (mounted) ref.read(accountRestoreProvider.notifier).acknowledge();
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AccountRestoreStatus>(accountRestoreProvider, (previous, next) {
      if (next == AccountRestoreStatus.restored) _scheduleShow();
    });
    return widget.child;
  }
}
