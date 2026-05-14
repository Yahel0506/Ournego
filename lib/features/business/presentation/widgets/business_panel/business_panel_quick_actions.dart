import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_metric_tile.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

class BusinessPanelQuickActions extends ConsumerWidget {
  const BusinessPanelQuickActions({
    super.key,
    required this.businessId,
    required this.onPlaceholderTap,
  });

  final String businessId;
  final VoidCallback onPlaceholderTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(businessPanelMetricsProvider(businessId));
    final metrics = metricsAsync.value;
    final isLoading = metricsAsync.isLoading;
    final averageRating = (metrics?.averageRating ?? 0).toStringAsFixed(1);
    final monthlyInteractions = '${metrics?.monthlyInteractions ?? 0}';
    final favoriteCount = '${metrics?.favoriteCount ?? 0}';
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BusinessPanelMetricTile(
                icon: Icons.star_rounded,
                value: averageRating,
                label: 'Opiniones',
                isLoading: isLoading,
                onTap: onPlaceholderTap,
              ),
            ),
            const SizedBox(width: OurnegoSpacingTokens.sm),
            Expanded(
              child: BusinessPanelMetricTile(
                icon: Icons.storefront_rounded,
                value: '--',
                label: 'Catalogo',
                onTap: onPlaceholderTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: OurnegoSpacingTokens.sm),
        OurnegoContentContainer(
          borderRadius: OurnegoRadiusTokens.lg,
          customHorizontalPadding: OurnegoSpacingTokens.md,
          customVerticalPadding: OurnegoSpacingTokens.md,
          backgroundColor: colorScheme.surface,
          borderColor: colorScheme.outline.withValues(alpha: 0.3),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPlaceholderTap,
              borderRadius: BorderRadius.circular(OurnegoRadiusTokens.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.insights_rounded,
                        color: colorScheme.onSurface,
                        size: 20,
                      ),
                      const SizedBox(width: OurnegoSpacingTokens.xs),
                      Text(
                        'Ver estadisticas',
                        style: OurnegoTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OurnegoSpacingTokens.sm),
                  Row(
                    children: [
                      Expanded(
                        child: BusinessPanelMetricTile(
                          icon: Icons.touch_app_rounded,
                          value: monthlyInteractions,
                          label: 'Interacciones',
                          isLoading: isLoading,
                          onTap: onPlaceholderTap,
                        ),
                      ),
                      const SizedBox(width: OurnegoSpacingTokens.sm),
                      Expanded(
                        child: BusinessPanelMetricTile(
                          icon: Icons.favorite_rounded,
                          value: favoriteCount,
                          label: 'Favoritos',
                          isLoading: isLoading,
                          onTap: onPlaceholderTap,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
