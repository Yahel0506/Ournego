import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/review_decision.dart';
import 'package:ournego/features/moderation/domain/entities/review_listing.dart';
import 'package:ournego/features/moderation/presentation/providers/moderation_providers.dart';
import 'package:ournego/features/moderation/presentation/widgets/review_decision_flow.dart';
import 'package:ournego/features/moderation/presentation/widgets/review_listing_card.dart';
import 'package:ournego/features/moderation/presentation/widgets/review_log_dialog.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_page_layout.dart';

/// Moderation queue for authorized staff: pending requests to approve or
/// reject, and published listings that can be withdrawn.
///
/// What this screen shows is only a convenience; the server decides who can
/// read the queue and who can resolve a request.
class ModerationScreen extends ConsumerStatefulWidget {
  const ModerationScreen({super.key});

  @override
  ConsumerState<ModerationScreen> createState() => _ModerationScreenState();
}

class _ModerationScreenState extends ConsumerState<ModerationScreen> {
  BusinessReviewStatus _tab = BusinessReviewStatus.pending;
  bool _isSaving = false;

  Future<void> _decide(ReviewListing listing, ReviewDecision decision) async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    final changed = await runReviewDecision(
      context,
      ref,
      listing: listing,
      decision: decision,
    );
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (changed) {
      ref.invalidate(reviewListingsProvider(BusinessReviewStatus.pending));
      ref.invalidate(reviewListingsProvider(BusinessReviewStatus.approved));
    }
  }

  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(MapRoutes.map);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isReviewer = ref.watch(isReviewerProvider);

    return OurnegoPageLayout(
      scaffoldKey: const Key('moderationScreen'),
      maxWidth: 560,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              OurnegoIconButton.ghost(
                key: const Key('moderationBackButton'),
                icon: Icons.arrow_back_rounded,
                semanticLabel: 'Volver',
                onPressed: _back,
              ),
              const SizedBox(width: OurnegoSpacingTokens.xs),
              const Expanded(
                child: Text('Moderación', style: OurnegoTextStyles.title),
              ),
              if (isReviewer.value == true)
                OurnegoIconButton.ghost(
                  key: const Key('moderationRefreshButton'),
                  icon: Icons.refresh_rounded,
                  semanticLabel: 'Actualizar',
                  onPressed: () => ref.invalidate(reviewListingsProvider(_tab)),
                ),
            ],
          ),
          const SizedBox(height: OurnegoSpacingTokens.sm),
          Expanded(
            child: isReviewer.when(
              loading: () => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              error: (_, _) => _Message(
                text: 'No pudimos comprobar tu acceso.',
                onRetry: () => ref.invalidate(isReviewerProvider),
              ),
              data: (allowed) {
                if (!allowed) {
                  return const _Message(
                    key: Key('moderationNoAccess'),
                    text:
                        'Esta sección es solo para el personal autorizado '
                        'de Ournego.',
                  );
                }
                return _Queue(
                  tab: _tab,
                  isSaving: _isSaving,
                  onTab: (tab) => setState(() => _tab = tab),
                  onDecision: _decide,
                  onHistory: (listing) => showOurnegoDialog<void>(
                    context: context,
                    builder: (_) => ReviewLogDialog(listing: listing),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Queue extends ConsumerWidget {
  const _Queue({
    required this.tab,
    required this.isSaving,
    required this.onTab,
    required this.onDecision,
    required this.onHistory,
  });

  final BusinessReviewStatus tab;
  final bool isSaving;
  final ValueChanged<BusinessReviewStatus> onTab;
  final void Function(ReviewListing, ReviewDecision) onDecision;
  final ValueChanged<ReviewListing> onHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listings = ref.watch(reviewListingsProvider(tab));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OurnegoChip<void>.filter(
              key: const Key('moderationTabPending'),
              label: 'Pendientes',
              selected: tab == BusinessReviewStatus.pending,
              onSelected: (_) => onTab(BusinessReviewStatus.pending),
            ),
            const SizedBox(width: OurnegoSpacingTokens.xs),
            OurnegoChip<void>.filter(
              key: const Key('moderationTabPublished'),
              label: 'Publicadas',
              selected: tab == BusinessReviewStatus.approved,
              onSelected: (_) => onTab(BusinessReviewStatus.approved),
            ),
          ],
        ),
        const SizedBox(height: OurnegoSpacingTokens.sm),
        Expanded(
          child: listings.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, _) => _Message(
              key: const Key('moderationError'),
              text: 'No pudimos cargar la lista.',
              onRetry: () => ref.invalidate(reviewListingsProvider(tab)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return _Message(
                  key: const Key('moderationEmpty'),
                  text: tab == BusinessReviewStatus.pending
                      ? 'No hay solicitudes pendientes.'
                      : 'No hay fichas publicadas.',
                );
              }
              return ListView.builder(
                itemCount: items.length,
                itemBuilder: (_, index) {
                  final listing = items[index];
                  return ReviewListingCard(
                    listing: listing,
                    enabled: !isSaving,
                    onApprove: () =>
                        onDecision(listing, ReviewDecision.approve),
                    onReject: () => onDecision(listing, ReviewDecision.reject),
                    onWithdraw: () =>
                        onDecision(listing, ReviewDecision.withdraw),
                    onHistory: () => onHistory(listing),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({super.key, required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: OurnegoContentContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: OurnegoTextStyles.bodyCompact,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: OurnegoSpacingTokens.sm),
              OurnegoButton.primary(
                size: OurnegoButtonSize.compact,
                label: 'Reintentar',
                icon: Icons.refresh_rounded,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
