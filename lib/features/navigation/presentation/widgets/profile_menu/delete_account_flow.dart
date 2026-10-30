import 'package:flutter/material.dart';

import 'package:url_launcher/url_launcher.dart';

import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

/// Verifiable deletion request (OUR-108): the person confirms from a link sent
/// to the account's email, so the request is made on the web, not in the app.
final Uri deleteAccountUrl = Uri.parse(
  'https://www.ournego.com/delete-account',
);

/// Grace period before the deletion runs. Keep in sync with
/// `DELETION_GRACE_PERIOD_DAYS` in `/privacy-policy` (section 13.2).
const int deleteAccountGracePeriodDays = 30;

/// What the dialog tells the person before sending them to the web. Mirrors
/// the "Eliminación de cuenta" section of `/privacy-policy`.
const String deleteAccountNotice =
    'Para comprobar que la cuenta es tuya, te enviaremos un enlace a tu correo '
    'desde la web de Ournego; la solicitud solo se registra cuando la '
    'confirmas desde ese enlace.\n\n'
    'Al confirmar, tus negocios dejan de mostrarse y la eliminación queda '
    'programada con un plazo de gracia de $deleteAccountGracePeriodDays días. '
    'Para cancelarla, inicia sesión en la app antes de que venza el plazo.\n\n'
    'Pasado el plazo se elimina tu perfil, tus negocios, reseñas y mensajes, '
    'y no se puede recuperar.';

/// Warns what will happen and, on confirmation, opens the verifiable deletion
/// flow in the browser.
Future<void> openDeleteAccountDialog(
  BuildContext context, {
  ContainerTransformOriginData? from,
  ContainerTransformOriginController? returnTo,
  Future<bool> Function(Uri url)? launch,
}) {
  final open =
      launch ??
      (Uri url) => launchUrl(url, mode: LaunchMode.externalApplication);
  final messenger = ScaffoldMessenger.of(context);

  return showOurnegoDialog<void>(
    context: context,
    staticOrigin: from,
    returnOrigin: returnTo,
    builder: (dialogContext) {
      return OurnegoAlertDialog(
        title: 'Eliminar cuenta',
        content: deleteAccountNotice,
        primaryAction: OurnegoDialogAction(
          key: const ValueKey('confirmDeleteAccountButton'),
          label: 'Continuar en la web',
          isDestructive: true,
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            final opened = await open(deleteAccountUrl);
            if (!opened && context.mounted) {
              messenger.showSnackBar(
                OurnegoSnackbars.info(
                  context,
                  'No pudimos abrir el navegador. Visita ournego.com/delete-account.',
                ),
              );
            }
          },
        ),
        secondaryAction: OurnegoDialogAction(
          label: 'Cancelar',
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      );
    },
  );
}
