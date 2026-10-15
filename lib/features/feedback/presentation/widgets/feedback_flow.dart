import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_information_dialog.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';

const String _genericErrorImage = 'assets/images/generic_error.png';

/// Opens the feedback dialog unless one is already open, so a shake, the
/// profile menu and an error dialog can never stack two of them.
///
/// [from] makes it grow out of a rect with no trigger behind it (the item of the
/// profile menu that was tapped) and [returnTo] is the trigger it goes back to
/// when it closes.
Future<void> openFeedbackDialog(
  BuildContext context,
  WidgetRef ref, {
  ContainerTransformOriginData? from,
  ContainerTransformOriginController? returnTo,
}) async {
  if (ref.read(isFeedbackDialogOpenProvider)) return;

  ref.read(isFeedbackDialogOpenProvider.notifier).setIsOpen();
  await showOurnegoDialog<void>(
    context: context,
    staticOrigin: from,
    returnOrigin: returnTo,
    builder: (_) => const FeedbackDialogWidget(),
  );
  if (!context.mounted) return;
  ref.read(isFeedbackDialogOpenProvider.notifier).setIsClosed();
}

/// An error dialog with the two usual ways out: "Entiendo" closes it, and
/// "Feedback" closes it and opens the feedback dialog.
Future<void> showErrorWithFeedbackDialog(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String description,
  String imagePath = _genericErrorImage,
}) {
  return showOurnegoDialog<void>(
    context: context,
    builder: (dialogContext) {
      return OurnegoInformationDialog(
        title: title,
        description: description,
        imagePath: imagePath,
        actions: Row(
          children: [
            Expanded(
              child: OurnegoButton.secondary(
                size: OurnegoButtonSize.compact,
                expanded: true,
                label: 'Feedback',
                onPressed: () async {
                  Navigator.of(dialogContext).pop();
                  if (!context.mounted) return;
                  await openFeedbackDialog(context, ref);
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

/// The error shown when the session could not be verified.
Future<void> showSessionErrorDialog(BuildContext context, WidgetRef ref) {
  return showErrorWithFeedbackDialog(
    context,
    ref,
    title: 'No se pudo verificar tu sesion',
    description:
        'Intenta de nuevo en unos segundos. Si el problema continua, envianos feedback.',
  );
}
