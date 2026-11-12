import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/listing_check.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';
import 'package:ournego/shared/widgets/ournego_inputs.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';

/// Confirms (approve) or asks for the reason (reject, withdraw) and applies the
/// decision. Returns true when the server accepted it, so the caller can
/// refresh the queue.
Future<bool> runReviewDecision(
  BuildContext context,
  WidgetRef ref, {
  required ReviewListing listing,
  required ReviewDecision decision,
}) async {
  final String? reason;
  if (decision.requiresReason) {
    reason = await showOurnegoDialog<String>(
      context: context,
      builder: (_) => ReviewReasonDialog(
        title: decision == ReviewDecision.reject
            ? 'Rechazar «${listing.name}»'
            : 'Retirar «${listing.name}»',
        helper: decision == ReviewDecision.reject
            ? 'La dueña verá este motivo y podrá corregir y reenviar.'
            : 'Dejará de verse en el mapa, la búsqueda y el detalle. La '
                  'dueña verá este motivo.',
        confirmLabel: decision == ReviewDecision.reject
            ? 'Rechazar'
            : 'Retirar',
      ),
    );
    if (reason == null) return false;
  } else {
    final check = await ref.read(checkListingBeforeApprovalUsecaseProvider)(
      listing: listing,
    );
    if (!context.mounted) return false;
    final report = check.fold<ListingReport?>((_) => null, (r) => r);
    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        OurnegoSnackbars.info(
          context,
          'No pudimos revisar la ficha. Revisa tu red e inténtalo de nuevo.',
        ),
      );
      return false;
    }
    if (!report.canApprove) {
      await showOurnegoDialog<void>(
        context: context,
        builder: (dialogContext) => ListingReportDialog(
          listing: listing,
          report: report,
          confirmLabel: 'Entendido',
          onConfirm: () => Navigator.of(dialogContext).pop(),
        ),
      );
      return false;
    }
    if (!context.mounted) return false;
    final confirmed = await showOurnegoDialog<bool>(
      context: context,
      builder: (dialogContext) => report.needsAttention
          ? ListingReportDialog(
              listing: listing,
              report: report,
              confirmLabel: 'Aprobar de todos modos',
              onConfirm: () => Navigator.of(dialogContext).pop(true),
              onCancel: () => Navigator.of(dialogContext).pop(false),
            )
          : OurnegoAlertDialog(
              title: 'Aprobar «${listing.name}»',
              content:
                  'La ficha será visible para todas las personas en el mapa, la '
                  'búsqueda y el detalle.',
              primaryAction: OurnegoDialogAction(
                key: const Key('confirmApproveButton'),
                label: 'Aprobar',
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
              secondaryAction: OurnegoDialogAction(
                label: 'Cancelar',
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
            ),
    );
    if (confirmed != true) return false;
    reason = null;
  }
  if (!context.mounted) return false;

  final result = await ref.read(decideBusinessReviewUsecaseProvider)(
    businessId: listing.id,
    decision: decision,
    reason: reason,
  );
  if (!context.mounted) return false;
  final messenger = ScaffoldMessenger.of(context);
  return result.fold(
    (failure) {
      messenger.showSnackBar(
        OurnegoSnackbars.info(context, reviewFailureMessage(failure)),
      );
      // A stale listing is worth refreshing: someone else already decided.
      return failure is ModerationStaleFailure;
    },
    (_) {
      messenger.showSnackBar(
        OurnegoSnackbars.success(context, reviewSuccessMessage(decision)),
      );
      return true;
    },
  );
}

String reviewSuccessMessage(ReviewDecision decision) {
  switch (decision) {
    case ReviewDecision.approve:
      return 'Ficha aprobada y publicada.';
    case ReviewDecision.reject:
      return 'Ficha rechazada. La dueña verá el motivo.';
    case ReviewDecision.withdraw:
      return 'Ficha retirada del mapa.';
  }
}

String reviewFailureMessage(Failure failure) {
  if (failure is ModerationNotAuthorizedFailure) {
    return 'Tu cuenta no puede resolver solicitudes.';
  }
  if (failure is ModerationReasonRequiredFailure) {
    return 'Escribe el motivo para continuar.';
  }
  if (failure is ModerationStaleFailure) {
    return 'Esta ficha ya cambió de estado. Actualizamos la lista.';
  }
  if (failure is NetworkFailure) {
    return 'Sin conexión. Revisa tu red e inténtalo de nuevo.';
  }
  return 'No se pudo guardar la decisión. Intenta nuevamente.';
}

/// Asks for the reason of a rejection or withdrawal. Pops the trimmed text.
class ReviewReasonDialog extends StatefulWidget {
  const ReviewReasonDialog({
    super.key,
    required this.title,
    required this.helper,
    required this.confirmLabel,
  });

  final String title;
  final String helper;
  final String confirmLabel;

  @override
  State<ReviewReasonDialog> createState() => _ReviewReasonDialogState();
}

class _ReviewReasonDialogState extends State<ReviewReasonDialog> {
  final _controller = TextEditingController();
  bool _showError = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      setState(() => _showError = true);
      return;
    }
    Navigator.of(context).pop(text);
  }

  @override
  Widget build(BuildContext context) {
    return OurnegoFormDialog(
      title: widget.title,
      primaryAction: OurnegoDialogAction(
        key: const Key('confirmReasonButton'),
        label: widget.confirmLabel,
        isDestructive: true,
        onPressed: _confirm,
      ),
      secondaryAction: OurnegoDialogAction(
        label: 'Cancelar',
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.helper, style: OurnegoTextStyles.bodyCompact),
          const SizedBox(height: 12),
          OurnegoInputField(
            fieldKey: const Key('reviewReasonField'),
            controller: _controller,
            labelText: 'Motivo',
            maxLines: 3,
            onChanged: (_) {
              if (_showError) setState(() => _showError = false);
            },
          ),
          if (_showError) ...[
            const SizedBox(height: 8),
            const Text(
              'El motivo es obligatorio.',
              key: Key('reviewReasonError'),
              style: OurnegoTextStyles.errorText,
            ),
          ],
        ],
      ),
    );
  }
}

/// What the check found. With blocking issues it only informs ([onCancel] is
/// null); with warnings or duplicates the reviewer can still approve.
class ListingReportDialog extends StatelessWidget {
  const ListingReportDialog({
    super.key,
    required this.listing,
    required this.report,
    required this.confirmLabel,
    required this.onConfirm,
    this.onCancel,
  });

  final ReviewListing listing;
  final ListingReport report;
  final String confirmLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final blocking = report.blocking;
    final warnings = report.warnings;
    return OurnegoFormDialog(
      title: blocking.isEmpty
          ? 'Revisa antes de aprobar'
          : 'No se puede aprobar «${listing.name}»',
      primaryAction: OurnegoDialogAction(
        key: const Key('confirmReportButton'),
        label: confirmLabel,
        onPressed: onConfirm,
      ),
      secondaryAction: onCancel == null
          ? null
          : OurnegoDialogAction(label: 'Cancelar', onPressed: onCancel!),
      child: Column(
        key: const Key('listingReport'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (blocking.isNotEmpty) ...[
            const Text(
              'Contenido inválido. Rechaza la ficha con el motivo para que la '
              'dueña la corrija.',
              style: OurnegoTextStyles.bodyCompact,
            ),
            const SizedBox(height: 8),
            for (final issue in blocking)
              Text('• ${issue.message}', style: OurnegoTextStyles.bodyCompact),
          ],
          if (warnings.isNotEmpty) ...[
            if (blocking.isNotEmpty) const SizedBox(height: 12),
            const Text('Avisos', style: OurnegoTextStyles.caption),
            for (final issue in warnings)
              Text('• ${issue.message}', style: OurnegoTextStyles.bodyCompact),
          ],
          if (report.duplicates.isNotEmpty) ...[
            if (blocking.isNotEmpty || warnings.isNotEmpty)
              const SizedBox(height: 12),
            const Text('Posibles duplicados', style: OurnegoTextStyles.caption),
            for (final d in report.duplicates)
              Text(
                '• «${d.listing.name}» (${d.reason.label}'
                '${d.listing.status == BusinessReviewStatus.approved ? ', ya publicada' : ', pendiente'})',
                style: OurnegoTextStyles.bodyCompact,
              ),
          ],
        ],
      ),
    );
  }
}
