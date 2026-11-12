import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_labels.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_review_status_card.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/presentation/widgets/review_labels.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

/// One listing of the moderation queue with the decisions that make sense for
/// its status: approve / reject while pending, withdraw while published.
class ReviewListingCard extends StatelessWidget {
  const ReviewListingCard({
    super.key,
    required this.listing,
    required this.onApprove,
    required this.onReject,
    required this.onWithdraw,
    required this.onHistory,
    this.enabled = true,
  });

  final ReviewListing listing;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onWithdraw;
  final VoidCallback onHistory;

  /// False while a decision is being saved, so a second tap cannot overlap it.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final id = listing.id;
    final date = listing.status == BusinessReviewStatus.pending
        ? listing.submittedAt
        : listing.reviewedAt;
    final dateLabel = listing.status == BusinessReviewStatus.pending
        ? 'Solicitada el'
        : 'Aprobada el';

    return OurnegoContentContainer(
      key: Key('reviewListingCard_$id'),
      margin: const EdgeInsets.only(bottom: OurnegoSpacingTokens.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(listing.name, style: OurnegoTextStyles.body),
          const SizedBox(height: OurnegoSpacingTokens.xs),
          Text(
            businessTypeLabel(listing.category),
            style: OurnegoTextStyles.caption,
          ),
          if (listing.address.isNotEmpty) ...[
            const SizedBox(height: OurnegoSpacingTokens.xs),
            Text(listing.address, style: OurnegoTextStyles.bodyCompact),
          ],
          if (listing.phoneNumber != null) ...[
            const SizedBox(height: OurnegoSpacingTokens.xs),
            Text(listing.phoneNumber!, style: OurnegoTextStyles.bodyCompact),
          ],
          if (listing.hours.isNotEmpty) ...[
            const SizedBox(height: OurnegoSpacingTokens.xs),
            Text(
              reviewHoursSummary(listing.hours),
              key: Key('reviewHours_$id'),
              style: OurnegoTextStyles.caption,
            ),
          ],
          if (listing.description.isNotEmpty) ...[
            const SizedBox(height: OurnegoSpacingTokens.xs),
            Text(
              listing.description,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: OurnegoTextStyles.bodyCompact,
            ),
          ],
          if (listing.images.isNotEmpty) ...[
            const SizedBox(height: OurnegoSpacingTokens.sm),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: listing.images.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(width: OurnegoSpacingTokens.xs),
                itemBuilder: (_, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    listing.images[index],
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox(
                      width: 72,
                      height: 72,
                      child: Icon(Icons.image_not_supported_outlined),
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (date != null) ...[
            const SizedBox(height: OurnegoSpacingTokens.xs),
            Text(
              '$dateLabel ${formatReviewDate(date)}.',
              style: OurnegoTextStyles.caption,
            ),
          ],
          const SizedBox(height: OurnegoSpacingTokens.sm),
          OverflowBar(
            spacing: OurnegoSpacingTokens.xs,
            overflowSpacing: OurnegoSpacingTokens.xs,
            children: [
              if (listing.status == BusinessReviewStatus.pending) ...[
                OurnegoButton.primary(
                  key: Key('approveButton_$id'),
                  size: OurnegoButtonSize.compact,
                  label: 'Aprobar',
                  icon: Icons.check_rounded,
                  onPressed: enabled ? onApprove : null,
                ),
                OurnegoButton.destructive(
                  key: Key('rejectButton_$id'),
                  size: OurnegoButtonSize.compact,
                  label: 'Rechazar',
                  onPressed: enabled ? onReject : null,
                ),
              ],
              if (listing.status == BusinessReviewStatus.approved)
                OurnegoButton.destructive(
                  key: Key('withdrawButton_$id'),
                  size: OurnegoButtonSize.compact,
                  label: 'Retirar',
                  onPressed: enabled ? onWithdraw : null,
                ),
              OurnegoButton.text(
                key: Key('historyButton_$id'),
                size: OurnegoButtonSize.compact,
                label: 'Historial',
                onPressed: onHistory,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
