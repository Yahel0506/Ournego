import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:ournego/features/moderation/presentation/widgets/review_labels.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';

/// Every status change of a listing: what, who, when and why.
class ReviewLogDialog extends ConsumerWidget {
  const ReviewLogDialog({super.key, required this.listing});

  final ReviewListing listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = ref.watch(reviewLogProvider(listing.id));

    return OurnegoFormDialog(
      title: 'Historial de «${listing.name}»',
      maxWidth: 440,
      primaryAction: OurnegoDialogAction(
        label: 'Cerrar',
        onPressed: () => Navigator.of(context).pop(),
      ),
      child: log.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(OurnegoSpacingTokens.md),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, _) => const Text(
          'No pudimos cargar el historial.',
          key: Key('reviewLogError'),
          style: OurnegoTextStyles.bodyCompact,
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const Text(
              'Aún no hay decisiones registradas.',
              style: OurnegoTextStyles.bodyCompact,
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final entry in entries)
                Padding(
                  key: Key('reviewLogEntry_${entry.id}'),
                  padding: const EdgeInsets.only(
                    bottom: OurnegoSpacingTokens.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reviewLogEntryLabel(entry),
                        style: OurnegoTextStyles.body,
                      ),
                      Text(
                        '${reviewActorLabel(entry)} · '
                        '${formatReviewDateTime(entry.createdAt)}',
                        style: OurnegoTextStyles.caption,
                      ),
                      if (entry.reason != null)
                        Text(
                          'Motivo: ${entry.reason}',
                          style: OurnegoTextStyles.bodyCompact,
                        ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
