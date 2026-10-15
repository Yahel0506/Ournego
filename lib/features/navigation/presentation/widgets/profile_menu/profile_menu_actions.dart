import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/location/open_app_location_settings.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_flow.dart';
import 'package:ournego/features/navigation/presentation/widgets/profile_menu/profile_menu_dialog_widget.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

/// Opens the profile menu from [context] and performs the chosen entry.
///
/// Every screen that offers the profile button calls this, so the menu and what
/// its entries do stay the same everywhere.
Future<void> openProfileMenu(
  BuildContext context,
  WidgetRef ref, {
  ProfileMenuOrigin origin = ProfileMenuOrigin.map,
  ContainerTransformOriginController? trigger,
}) async {
  final handoff = ContainerTransformHandoff();
  final action = await showProfileMenuDialog(
    context,
    origin: origin,
    trigger: trigger,
    handoff: handoff,
  );
  if (action == null || !context.mounted) return;

  switch (action) {
    case ProfileMenuAction.logIn:
      context.push(AuthRoutes.authSelection);
    case ProfileMenuAction.businessPanel:
      context.go(BusinessRoutes.panel);
    case ProfileMenuAction.locationPermissions:
      final opened = await openAppLocationSettings();
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(OurnegoSnackbars.info(webLocationPermissionHelp));
      }
    case ProfileMenuAction.reportProblem:
      // Grows out of the tapped item and, once the item is gone, goes back to
      // the profile button.
      await openFeedbackDialog(
        context,
        ref,
        from: handoff.data,
        returnTo: trigger,
      );
    case ProfileMenuAction.debugPanel:
      context.go(DebuggingRoutes.debugPanel);
    case ProfileMenuAction.logOut:
      await _confirmLogOut(context, ref, from: handoff.data, returnTo: trigger);
  }
}

Future<void> _confirmLogOut(
  BuildContext context,
  WidgetRef ref, {
  ContainerTransformOriginData? from,
  ContainerTransformOriginController? returnTo,
}) {
  final logOutUsecase = ref.read(logOutUsecaseProvider);

  return showOurnegoDialog<void>(
    context: context,
    staticOrigin: from,
    returnOrigin: returnTo,
    builder: (dialogContext) {
      return OurnegoAlertDialog(
        title: 'Cerrar sesión',
        content: '¿Estás seguro de que quieres cerrar sesión?',
        primaryAction: OurnegoDialogAction(
          key: const ValueKey('confirmLogoutButton'),
          label: 'Cerrar sesión',
          isDestructive: true,
          onPressed: () async {
            await logOutUsecase();
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
              dialogContext.go(MapRoutes.map);
            }
          },
        ),
        secondaryAction: OurnegoDialogAction(
          label: 'Cancelar',
          onPressed: () {
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    },
  );
}
