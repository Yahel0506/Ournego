import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/business_hours_compact_card.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/minimized_stack_icon.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/sheet_header.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_controller.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_state.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';

class OurnegoFloatingSheet extends StatefulWidget {
  final FloatingSheetController controller;
  final double collapsedHeight;
  final double expandedHeight;
  final double bottomOffset;
  final double sideStackTop;
  final double maxWidth;
  final Future<bool> Function(SheetBusinessData business) onFavorite;

  /// [origin] is the button that was tapped, so the notice can grow out of it.
  final Future<void> Function(
    SheetBusinessData business,
    ContainerTransformOriginController origin,
  )
  onContact;
  final void Function(SheetBusinessData business) onCatalog;
  final void Function(SheetBusinessData business) onReviews;
  final Future<void> Function(SheetBusinessData business) onShare;

  const OurnegoFloatingSheet({
    super.key,
    required this.controller,
    required this.collapsedHeight,
    required this.expandedHeight,
    required this.bottomOffset,
    required this.sideStackTop,
    required this.maxWidth,
    required this.onFavorite,
    required this.onContact,
    required this.onCatalog,
    required this.onReviews,
    required this.onShare,
  });

  @override
  State<OurnegoFloatingSheet> createState() => _OurnegoFloatingSheetState();
}

class _OurnegoFloatingSheetState extends State<OurnegoFloatingSheet> {
  bool _isFavoriteUpdating = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(covariant OurnegoFloatingSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) {
      return;
    }

    oldWidget.controller.removeListener(_onControllerChanged);
    widget.controller.addListener(_onControllerChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final activeBusiness = controller.activeBusiness;
    final comparisonBusiness = controller.comparisonBusiness;
    final isComparisonMode = controller.isComparisonMode;

    return AnimatedSwitcher(
      duration: kSheetTransitionDuration,
      switchInCurve: kEaseOutExpo,
      switchOutCurve: kEaseOutExpo,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation);

        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: Stack(
        key: ValueKey<String>(
          '${controller.isComparisonMode}-${controller.activeBusiness?.id}-${controller.comparisonBusiness?.id}',
        ),
        children: [
          _buildOverlay(controller.state, isComparisonMode),
          if (!isComparisonMode)
            _buildMinimizedStack(controller.minimizedBusinesses),
          if (activeBusiness != null && comparisonBusiness == null)
            _buildFloatingSheet(
              activeBusiness: activeBusiness,
              controller: controller,
            ),
          if (activeBusiness != null && comparisonBusiness != null)
            _buildComparisonSheets(
              primaryBusiness: activeBusiness,
              secondaryBusiness: comparisonBusiness,
              controller: controller,
            ),
        ],
      ),
    );
  }

  Widget _buildOverlay(FloatingSheetState state, bool isComparisonMode) {
    final shouldBlock =
        state == FloatingSheetState.expanded || isComparisonMode;

    return AnimatedOpacity(
      duration: kSheetTransitionDuration,
      curve: kEaseOutExpo,
      opacity: isComparisonMode
          ? 0.5
          : state == FloatingSheetState.expanded
          ? 0.4
          : 0,
      child: IgnorePointer(
        ignoring: !shouldBlock,
        child: GestureDetector(
          key: const ValueKey('floatingSheetScrim'),
          behavior: HitTestBehavior.opaque,
          onTap: widget.controller.handleBack,
          child: Container(color: Colors.black),
        ),
      ),
    );
  }

  Widget _buildMinimizedStack(List<SheetBusinessData> minimizedBusinesses) {
    return AnimatedPositioned(
      duration: kSheetTransitionDuration,
      curve: kEaseOutExpo,
      left: 12,
      top: widget.sideStackTop,
      child: AnimatedOpacity(
        duration: kSheetTransitionDuration,
        curve: kEaseOutExpo,
        opacity: minimizedBusinesses.isEmpty ? 0 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: minimizedBusinesses
              .map(
                (business) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: MinimizedStackIcon(
                    business: business,
                    onTap: () =>
                        widget.controller.onMinimizedBusinessTap(business.id),
                    onLongPress: () =>
                        widget.controller.removeFromMinimized(business.id),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _buildComparisonSheets({
    required SheetBusinessData primaryBusiness,
    required SheetBusinessData secondaryBusiness,
    required FloatingSheetController controller,
  }) {
    final gap = 10.0;
    final compareHeight = (widget.expandedHeight - gap) / 2;
    final topBottom = widget.bottomOffset + compareHeight + gap;
    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 24;
    final sheetWidth = availableWidth > widget.maxWidth
        ? widget.maxWidth
        : availableWidth;
    final centeredLeft = (screenWidth - sheetWidth) / 2;

    return AnimatedSwitcher(
      duration: kSheetTransitionDuration,
      switchInCurve: kEaseOutExpo,
      switchOutCurve: kEaseOutExpo,
      transitionBuilder: (child, animation) {
        final scale = Tween<double>(begin: 0.96, end: 1).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(scale: scale, child: child),
        );
      },
      child: Stack(
        key: ValueKey<String>(
          'compare-${primaryBusiness.id}-${secondaryBusiness.id}',
        ),
        children: [
          Positioned(
            left: centeredLeft,
            width: sheetWidth,
            bottom: widget.bottomOffset,
            child: _buildComparisonCard(
              business: primaryBusiness,
              controller: controller,
              height: compareHeight,
              isPrimary: true,
            ),
          ),
          Positioned(
            left: centeredLeft,
            width: sheetWidth,
            bottom: topBottom,
            child: _buildComparisonCard(
              business: secondaryBusiness,
              controller: controller,
              height: compareHeight,
              isPrimary: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonCard({
    required SheetBusinessData business,
    required FloatingSheetController controller,
    required double height,
    required bool isPrimary,
  }) {
    return AnimatedContainer(
      duration: kSheetTransitionDuration,
      curve: kEaseOutExpo,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.window),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            spreadRadius: -4,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TypeRatingBadgeRow(
                  type: business.type,
                  rating: business.rating,
                ),
                const Spacer(),
                _SheetControls(
                  onShare: () => widget.onShare(business),
                  isFavorite: business.isFavorite,
                  onFavoriteToggle: _isFavoriteUpdating
                      ? null
                      : () async {
                          setState(() {
                            _isFavoriteUpdating = true;
                          });

                          controller.toggleFavoriteForBusiness(business.id);
                          final success = await widget.onFavorite(business);
                          if (!success) {
                            controller.toggleFavoriteForBusiness(business.id);
                          }

                          if (!mounted) return;
                          setState(() {
                            _isFavoriteUpdating = false;
                          });
                        },
                  onMinimize: isPrimary
                      ? controller.minimizePrimaryInComparison
                      : controller.minimizeSecondaryInComparison,
                  lastIcon: Icons.close_rounded,
                  lastLabel: 'Cerrar',
                  onLast: isPrimary
                      ? controller.closePrimaryInComparison
                      : controller.closeSecondaryInComparison,
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SheetHeader(name: business.name, isExpanded: true),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _ExpandedContent(
                business: business,
                onContact: (origin) => widget.onContact(business, origin),
                onCatalog: () => widget.onCatalog(business),
                onReviews: () => widget.onReviews(business),
                onShare: () => widget.onShare(business),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingSheet({
    required SheetBusinessData activeBusiness,
    required FloatingSheetController controller,
  }) {
    final state = controller.state;
    final isExpanded = state == FloatingSheetState.expanded;
    final isMinimized = state == FloatingSheetState.minimized;
    final isMinimizingToStack =
        isMinimized &&
        controller.pendingMinimizeToStack &&
        controller.pendingClearActive;

    final double targetHeight = isExpanded
        ? widget.expandedHeight
        : widget.collapsedHeight;

    final screenWidth = MediaQuery.of(context).size.width;
    final availableWidth = screenWidth - 24;
    final sheetWidth = availableWidth > widget.maxWidth
        ? widget.maxWidth
        : availableWidth;

    final centeredLeft = (screenWidth - sheetWidth) / 2;
    final visibleLeft = centeredLeft.clamp(12.0, double.infinity);
    final defaultBottom = widget.bottomOffset;

    final double animatedWidth = isMinimizingToStack ? 48 : sheetWidth;
    final double animatedHeight = isMinimized
        ? (isMinimizingToStack ? 48 : 0)
        : targetHeight;

    final double left = isMinimizingToStack ? 12 : visibleLeft;
    final double? top = isMinimizingToStack ? widget.sideStackTop : null;
    final double? bottom = isMinimizingToStack ? null : defaultBottom;
    final double opacity = isMinimized ? 0 : 1;

    return AnimatedPositioned(
      duration: kSheetTransitionDuration,
      curve: kEaseOutExpo,
      left: left,
      top: top,
      bottom: bottom,
      width: animatedWidth,
      child: AnimatedOpacity(
        duration: kSheetTransitionDuration,
        curve: kEaseOutExpo,
        opacity: opacity,
        onEnd: controller.finalizeTransitionOut,
        child: AnimatedScale(
          duration: kSheetTransitionDuration,
          curve: kEaseOutExpo,
          scale: isMinimizingToStack
              ? 0.2
              : isMinimized
              ? 0.94
              : 1,
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: kSheetTransitionDuration,
            curve: kEaseOutExpo,
            height: animatedHeight,
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                controller.handleVerticalDragEnd(
                  velocity: details.primaryVelocity ?? 0,
                  currentHeight: targetHeight,
                  collapsedHeight: widget.collapsedHeight,
                  expandedHeight: widget.expandedHeight,
                );
              },
              child: IgnorePointer(
                ignoring: isMinimized,
                child: AnimatedContainer(
                  duration: kSheetTransitionDuration,
                  curve: kEaseOutExpo,
                  height: animatedHeight,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.3),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(
                      OurnegoRadiusTokens.window,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: -4,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      children: [
                        _AnimatedDragHandle(isExpanded: isExpanded),
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _TypeRatingBadgeRow(
                              type: activeBusiness.type,
                              rating: activeBusiness.rating,
                            ),
                            const Spacer(),
                            _SheetControls(
                              onShare: () => widget.onShare(activeBusiness),
                              isFavorite: activeBusiness.isFavorite,
                              onFavoriteToggle: _isFavoriteUpdating
                                  ? null
                                  : () async {
                                      setState(() {
                                        _isFavoriteUpdating = true;
                                      });

                                      controller.toggleFavorite();
                                      final success = await widget.onFavorite(
                                        activeBusiness,
                                      );

                                      if (!success) {
                                        controller.toggleFavorite();
                                      }

                                      if (!mounted) return;
                                      setState(() {
                                        _isFavoriteUpdating = false;
                                      });
                                    },
                              onMinimize: controller.minimizeActiveBusiness,
                              lastIcon: isExpanded
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.open_in_full_rounded,
                              lastLabel: isExpanded ? 'Contraer' : 'Expandir',
                              onLast: controller.toggleExpandedCollapsed,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: SheetHeader(
                            name: activeBusiness.name,
                            isExpanded: isExpanded,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: isExpanded
                              ? _ExpandedContent(
                                  business: activeBusiness,
                                  onContact: (origin) =>
                                      widget.onContact(activeBusiness, origin),
                                  onCatalog: () =>
                                      widget.onCatalog(activeBusiness),
                                  onReviews: () =>
                                      widget.onReviews(activeBusiness),
                                  onShare: () => widget.onShare(activeBusiness),
                                )
                              : SingleChildScrollView(
                                  // In the collapsed state, available height can
                                  // be smaller than the actions' intrinsic size
                                  // (especially in widget tests). Scrolling/clip
                                  // avoids RenderFlex overflow without changing
                                  // the visible layout in normal use.
                                  physics: const NeverScrollableScrollPhysics(),
                                  child: _CollapsedActions(
                                    onContact: (origin) => widget.onContact(
                                      activeBusiness,
                                      origin,
                                    ),
                                    onCatalog: () =>
                                        widget.onCatalog(activeBusiness),
                                    onReviews: () =>
                                        widget.onReviews(activeBusiness),
                                    onShare: () =>
                                        widget.onShare(activeBusiness),
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedDragHandle extends StatelessWidget {
  final bool isExpanded;

  const _AnimatedDragHandle({required this.isExpanded});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 46,
          height: 5,
          decoration: BoxDecoration(
            color: colorScheme.outline.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ],
    );
  }
}

class _TypeRatingBadgeRow extends StatelessWidget {
  final dynamic type;
  final double? rating;

  const _TypeRatingBadgeRow({required this.type, required this.rating});

  String _typeLabel(dynamic type) {
    final typeText = type.toString().split('.').last;
    switch (typeText) {
      case 'drinkAndEat':
        return 'Comida y bebida';
      case 'shop':
        return 'Tienda';
      case 'personalService':
        return 'Servicio personal';
      case 'professionalService':
        return 'Servicio profesional';
      case 'healthAndWellness':
        return 'Salud y bienestar';
      case 'education':
        return 'Educacion';
      case 'constructionAndHome':
        return 'Hogar y construccion';
      case 'transportation':
        return 'Transporte';
      case 'entertainment':
        return 'Entretenimiento';
      case 'technology':
        return 'Tecnologia';
      case 'informalBusiness':
        return 'Negocio informal';
      case 'mixed':
        return 'Mixto';
      default:
        return 'General';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Text(
            _typeLabel(type),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        if (rating != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  rating!.toStringAsFixed(1),
                  style: TextStyle(fontSize: 11, color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _CollapsedActions extends StatelessWidget {
  final ValueChanged<ContainerTransformOriginController> onContact;
  final VoidCallback onCatalog;
  final VoidCallback onReviews;
  final VoidCallback onShare;

  const _CollapsedActions({
    required this.onContact,
    required this.onCatalog,
    required this.onReviews,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: OurnegoSpacingTokens.xs);
    return Row(
      children: [
        Expanded(
          child: OurnegoActionButton(
            icon: Icons.sentiment_satisfied_rounded,
            semanticLabel: 'Reseñas',
            onPressed: onReviews,
          ),
        ),
        gap,
        Expanded(
          child: OurnegoActionButton(
            icon: Icons.search_rounded,
            semanticLabel: 'Catálogo',
            onPressed: onCatalog,
          ),
        ),
        gap,
        Expanded(
          child: ContainerTransformTrigger(
            radius: OurnegoRadiusTokens.lg,
            builder: (context, origin) => OurnegoActionButton(
              icon: Icons.chat_rounded,
              semanticLabel: 'Mensaje',
              onPressed: () => onContact(origin),
            ),
          ),
        ),
      ],
    );
  }
}

class _SheetControls extends StatelessWidget {
  const _SheetControls({
    required this.onShare,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onMinimize,
    required this.lastIcon,
    required this.lastLabel,
    required this.onLast,
  });

  final VoidCallback onShare;
  final bool isFavorite;

  /// Null while the favorite update is in flight, which disables the toggle.
  final VoidCallback? onFavoriteToggle;
  final VoidCallback onMinimize;
  final IconData lastIcon;
  final String lastLabel;
  final VoidCallback onLast;

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(width: OurnegoSpacingTokens.xs);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OurnegoIconButton(
          tone: OurnegoButtonTone.tonal,
          outlined: true,
          size: OurnegoIconButtonSize.s32,
          radius: OurnegoRadiusTokens.lg,
          icon: Icons.share_rounded,
          semanticLabel: 'Compartir',
          onPressed: onShare,
        ),
        gap,
        OurnegoIconButton.toggle(
          outlined: true,
          radius: OurnegoRadiusTokens.lg,
          selected: isFavorite,
          icon: Icons.favorite_border_rounded,
          selectedIcon: Icons.favorite_rounded,
          celebrate: true,
          semanticLabel: 'Favorito',
          onChanged: onFavoriteToggle == null
              ? null
              : (_) => onFavoriteToggle!(),
        ),
        gap,
        OurnegoIconButton(
          tone: OurnegoButtonTone.tonal,
          outlined: true,
          size: OurnegoIconButtonSize.s32,
          radius: OurnegoRadiusTokens.lg,
          icon: Icons.picture_in_picture_alt_rounded,
          semanticLabel: 'Minimizar',
          onPressed: onMinimize,
        ),
        gap,
        OurnegoIconButton(
          tone: OurnegoButtonTone.tonal,
          outlined: true,
          size: OurnegoIconButtonSize.s32,
          radius: OurnegoRadiusTokens.lg,
          icon: lastIcon,
          semanticLabel: lastLabel,
          onPressed: onLast,
        ),
      ],
    );
  }
}

BoxDecoration _brandedSheetCardDecoration(ColorScheme colorScheme) {
  return BoxDecoration(
    color: colorScheme.surface,
    borderRadius: BorderRadius.circular(OurnegoRadiusTokens.xl),
    border: Border.all(color: OurnegoSemanticTokens.borderSubtle(colorScheme)),
  );
}

class _SheetAccentIcon extends StatelessWidget {
  const _SheetAccentIcon({required this.icon, this.size = 36});

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.full),
      ),
      child: Icon(icon, size: size * 0.52),
    );
  }
}

class _ExpandedContent extends ConsumerWidget {
  final SheetBusinessData business;
  final ValueChanged<ContainerTransformOriginController> onContact;
  final VoidCallback onCatalog;
  final VoidCallback onReviews;
  final VoidCallback onShare;

  const _ExpandedContent({
    required this.business,
    required this.onContact,
    required this.onCatalog,
    required this.onReviews,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final ownerProfileAsync = ref.watch(
      ownerProfileStreamProvider(business.ownerId),
    );
    final ownerName = ownerProfileAsync.maybeWhen(
      data: (user) {
        final name = user.name?.trim();
        if (name == null || name.isEmpty) {
          return 'Sin usuario';
        }

        return name;
      },
      orElse: () => 'Cargando usuario...',
    );

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Text(
          business.description,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontSize: 15,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        if (business.images.isNotEmpty)
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: business.images.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final imageUrl = business.images[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    imageUrl,
                    width: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 180,
                        color: colorScheme.inverseSurface.withValues(
                          alpha: 0.08,
                        ),
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        if (business.images.isNotEmpty) const SizedBox(height: 0),
        const SizedBox(height: 12),
        OurnegoRowButton(
          icon: Icons.sentiment_satisfied_rounded,
          label: 'Opinión general',
          onPressed: onReviews,
        ),
        const SizedBox(height: 12),
        _ContactCard(ownerName: ownerName, onContact: onContact),
        const SizedBox(height: 12),
        BusinessHoursCompactCard(hours: business.hours),
        const SizedBox(height: 12),
        _CatalogCard(onCatalog: onCatalog),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String ownerName;
  final ValueChanged<ContainerTransformOriginController> onContact;

  const _ContactCard({required this.ownerName, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _brandedSheetCardDecoration(colorScheme),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const _SheetAccentIcon(
                icon: Icons.account_circle_outlined,
                size: 40,
              ),
              const SizedBox(width: 12),
              Text(
                ownerName,
                style: OurnegoTextStyles.body.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ContainerTransformTrigger(
                radius: OurnegoRadiusTokens.lg,
                builder: (context, origin) => OurnegoButton.secondary(
                  size: OurnegoButtonSize.compact,
                  radius: OurnegoRadiusTokens.lg,
                  label: 'Mensaje',
                  icon: Icons.chat_rounded,
                  iconMotion: OurnegoIconMotion.wiggle,
                  onPressed: () => onContact(origin),
                ),
              ),
              const SizedBox(width: 12),
              ContainerTransformTrigger(
                radius: OurnegoRadiusTokens.lg,
                builder: (context, origin) => OurnegoButton.secondary(
                  size: OurnegoButtonSize.compact,
                  radius: OurnegoRadiusTokens.lg,
                  label: 'Llamar',
                  icon: Icons.call_rounded,
                  iconMotion: OurnegoIconMotion.wiggle,
                  onPressed: () => onContact(origin),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final VoidCallback onCatalog;

  const _CatalogCard({required this.onCatalog});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _brandedSheetCardDecoration(colorScheme),
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: SearchBar(
              hintText: 'Buscar productos...',
              elevation: const WidgetStatePropertyAll(0),
              onTap: onCatalog,
              leading: Icon(
                Icons.search_rounded,
                size: 18,
                color: colorScheme.primary,
              ),
              backgroundColor: WidgetStatePropertyAll(
                colorScheme.primary.withValues(alpha: 0.08),
              ),
              side: WidgetStatePropertyAll(
                BorderSide(color: colorScheme.outline.withValues(alpha: 0.3)),
              ),
              hintStyle: WidgetStatePropertyAll(
                TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.65)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.center,
            child: OurnegoButton.text(
              size: OurnegoButtonSize.compact,
              label: 'Ver catálogo',
              icon: Icons.inventory_2_rounded,
              iconMotion: OurnegoIconMotion.wiggle,
              onPressed: onCatalog,
            ),
          ),
        ],
      ),
    );
  }
}
