import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

/// Shows where the listing stands in the publication review: waiting, public,
/// rejected (with the reviewer's reason) or withdrawn. When the owner can ask
/// for a review it also offers the button to do so.
class BusinessPanelReviewStatusCard extends StatelessWidget {
  const BusinessPanelReviewStatusCard({
    super.key,
    required this.ownedBusiness,
    required this.onRequestReview,
  });

  final OwnedBusinessProfile ownedBusiness;

  /// Called when the owner taps "Enviar a revisión". Null disables the button
  /// (for example while another change is saving).
  final VoidCallback? onRequestReview;

  @override
  Widget build(BuildContext context) {
    final status = ownedBusiness.reviewStatus;
    final copy = _copyFor(status);
    final reason = ownedBusiness.rejectionReason;

    return OurnegoContentContainer(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: OurnegoSpacingTokens.xs,
          horizontal: OurnegoSpacingTokens.xs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(copy.icon, color: copy.color),
                const SizedBox(width: OurnegoSpacingTokens.xs),
                Expanded(
                  child: Text(
                    copy.title,
                    key: const Key('reviewStatusTitle'),
                    style: OurnegoTextStyles.body,
                  ),
                ),
              ],
            ),
            const SizedBox(height: OurnegoSpacingTokens.xs),
            Text(
              copy.message,
              key: const Key('reviewStatusMessage'),
              style: OurnegoTextStyles.bodyCompact,
            ),
            if (reason != null &&
                (status == BusinessReviewStatus.rejected ||
                    status == BusinessReviewStatus.withdrawn)) ...[
              const SizedBox(height: OurnegoSpacingTokens.xs),
              Text(
                'Motivo: $reason',
                key: const Key('reviewStatusReason'),
                style: OurnegoTextStyles.bodyCompact,
              ),
            ],
            if (_dateLine(status) case final line?) ...[
              const SizedBox(height: OurnegoSpacingTokens.xs),
              Text(
                line,
                key: const Key('reviewStatusDate'),
                style: const TextStyle(fontSize: 12),
              ),
            ],
            if (status.canRequestReview) ...[
              const SizedBox(height: OurnegoSpacingTokens.sm),
              OurnegoButton.primary(
                key: const Key('requestReviewButton'),
                size: OurnegoButtonSize.compact,
                label: status == BusinessReviewStatus.rejected
                    ? 'Reenviar a revisión'
                    : 'Solicitar publicación',
                icon: Icons.send_rounded,
                onPressed: onRequestReview,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _dateLine(BusinessReviewStatus status) {
    switch (status) {
      case BusinessReviewStatus.pending:
        final at = ownedBusiness.submittedAt;
        return at == null ? null : 'Enviada el ${formatReviewDate(at)}.';
      case BusinessReviewStatus.rejected:
        final at = ownedBusiness.reviewedAt;
        return at == null ? null : 'Revisada el ${formatReviewDate(at)}.';
      case BusinessReviewStatus.withdrawn:
        // Only a reviewer's withdrawal carries a reason and a decision date.
        final at = ownedBusiness.reviewedAt;
        return (at == null || ownedBusiness.rejectionReason == null)
            ? null
            : 'Retirada el ${formatReviewDate(at)}.';
      case BusinessReviewStatus.approved:
        return null;
    }
  }

  _StatusCopy _copyFor(BusinessReviewStatus status) {
    switch (status) {
      case BusinessReviewStatus.pending:
        return const _StatusCopy(
          icon: Icons.hourglass_top_rounded,
          color: OurnegoColorTokens.warning,
          title: 'En revisión',
          message:
              'Recibimos la solicitud. Tu negocio se publicará en el mapa '
              'cuando sea aprobado.',
        );
      case BusinessReviewStatus.approved:
        return const _StatusCopy(
          icon: Icons.check_circle_rounded,
          color: OurnegoColorTokens.success,
          title: 'Publicado',
          message:
              'Tu negocio es visible en el mapa. Si cambias el nombre, la '
              'descripción, la categoría, la dirección, el teléfono o las '
              'fotos, volverá a revisión y dejará de verse hasta ser aprobado.',
        );
      case BusinessReviewStatus.rejected:
        return const _StatusCopy(
          icon: Icons.cancel_rounded,
          color: OurnegoColorTokens.error,
          title: 'No aprobado',
          message:
              'Corrige lo indicado con las opciones de edición y vuelve a '
              'enviarlo a revisión.',
        );
      case BusinessReviewStatus.withdrawn:
        final byReview = ownedBusiness.rejectionReason != null;
        return _StatusCopy(
          icon: Icons.remove_circle_outline_rounded,
          color: OurnegoColorTokens.warning,
          title: 'Retirado',
          message: byReview
              ? 'Retiramos tu negocio del mapa. Corrige lo indicado y '
                    'solicita la publicación de nuevo.'
              : 'Tu negocio no está publicado. Puedes solicitar la '
                    'publicación de nuevo cuando quieras.',
        );
    }
  }
}

/// `dd/MM/yyyy`, kept dependency-free on purpose.
String formatReviewDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year}';
}

class _StatusCopy {
  const _StatusCopy({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
}
