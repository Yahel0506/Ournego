import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/minimized_stack_icon.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/sheet_control_button.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/sheet_header.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_controller.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_state.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

// =============================================================
// OURNEGO FLOATING SHEET — ANALISIS PRE-IMPLEMENTACION
// Generado por: OpenCode
// Fecha: 2026-04-14
// =============================================================
// Widget reemplazado: lib/features/map/presentation/pages/map_screen.dart:673
// + lib/features/map/presentation/widgets/business_information_widget.dart:24
// Widget padre: Scaffold > Stack > Align > SizedBox > NotificationListener >
// DraggableScrollableSheet en lib/features/map/presentation/pages/map_screen.dart
// Modelo de datos: Business (lib/features/map/domain/entities/business.dart)
// State management: Riverpod + controller local (favoritos)
// Border radius estándar app: 30
// Colores superficie dark: surface=#1E2625, primary=#3BCFED
// Fuente de animaciones: Durations.medium1/short4 + Curves.linearToEaseOut,
// easeOutCubic, easeInCubic
// Notas de riesgos: no existe rating en modelo Business; no hay altura global
// expuesta de navbar/topbar; tests actuales esperan que al tap marker aparezca
// nombre del negocio; no existe side stack hoy.
// =============================================================

class OurnegoFloatingSheet extends StatefulWidget {
  final FloatingSheetController controller;
  final double collapsedHeight;
  final double expandedHeight;
  final double bottomOffset;
  final double sideStackTop;
  final double maxWidth;
  final Future<bool> Function(SheetBusinessData business) onFavorite;
  final Future<void> Function(SheetBusinessData business) onContact;
  final void Function(SheetBusinessData business) onCatalog;
  final void Function(SheetBusinessData business) onReviews;

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
        child: Container(color: Colors.black),
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
        borderRadius: BorderRadius.circular(18),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SheetControlButton(
                      icon: business.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      onTap: _isFavoriteUpdating
                          ? () {}
                          : () async {
                              setState(() {
                                _isFavoriteUpdating = true;
                              });

                              controller.toggleFavoriteForBusiness(business.id);
                              final success = await widget.onFavorite(business);
                              if (!success) {
                                controller.toggleFavoriteForBusiness(
                                  business.id,
                                );
                              }

                              if (!mounted) return;
                              setState(() {
                                _isFavoriteUpdating = false;
                              });
                            },
                      backgroundColor: business.isFavorite
                          ? Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.25)
                          : null,
                      iconColor: business.isFavorite
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    const SizedBox(width: 8),
                    SheetControlButton(
                      icon: Icons.picture_in_picture_alt_rounded,
                      onTap: isPrimary
                          ? controller.minimizePrimaryInComparison
                          : controller.minimizeSecondaryInComparison,
                    ),
                    const SizedBox(width: 8),
                    SheetControlButton(
                      icon: Icons.close_rounded,
                      onTap: isPrimary
                          ? controller.closePrimaryInComparison
                          : controller.closeSecondaryInComparison,
                    ),
                  ],
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
              child: _LegacyExpandedContent(
                business: business,
                onContact: () => widget.onContact(business),
                onCatalog: () => widget.onCatalog(business),
                onReviews: () => widget.onReviews(business),
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
                    borderRadius: BorderRadius.circular(18),
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
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SheetControlButton(
                                  icon: activeBusiness.isFavorite
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  onTap: _isFavoriteUpdating
                                      ? () {}
                                      : () async {
                                          setState(() {
                                            _isFavoriteUpdating = true;
                                          });

                                          controller.toggleFavorite();
                                          final success = await widget
                                              .onFavorite(activeBusiness);

                                          if (!success) {
                                            controller.toggleFavorite();
                                          }

                                          if (!mounted) return;
                                          setState(() {
                                            _isFavoriteUpdating = false;
                                          });
                                        },
                                  backgroundColor: activeBusiness.isFavorite
                                      ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.25)
                                      : null,
                                  iconColor: activeBusiness.isFavorite
                                      ? Theme.of(context).colorScheme.primary
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                SheetControlButton(
                                  icon: Icons.picture_in_picture_alt_rounded,
                                  onTap: controller.minimizeActiveBusiness,
                                ),
                                const SizedBox(width: 8),
                                SheetControlButton(
                                  icon: isExpanded
                                      ? Icons.keyboard_arrow_down_rounded
                                      : Icons.open_in_full_rounded,
                                  onTap: controller.toggleExpandedCollapsed,
                                ),
                              ],
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
                        if (!isExpanded)
                          _LegacyCollapsedActions(
                            onContact: () => widget.onContact(activeBusiness),
                            onCatalog: () => widget.onCatalog(activeBusiness),
                            onReviews: () => widget.onReviews(activeBusiness),
                          )
                        else
                          Expanded(
                            child: _LegacyExpandedContent(
                              business: activeBusiness,
                              onContact: () => widget.onContact(activeBusiness),
                              onCatalog: () => widget.onCatalog(activeBusiness),
                              onReviews: () => widget.onReviews(activeBusiness),
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

class _LegacyCollapsedActions extends StatelessWidget {
  final VoidCallback onContact;
  final VoidCallback onCatalog;
  final VoidCallback onReviews;

  const _LegacyCollapsedActions({
    required this.onContact,
    required this.onCatalog,
    required this.onReviews,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _LegacyActionButton(
            icon: Icons.emoji_emotions,
            onTap: onReviews,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: _LegacyActionButton(
            icon: Icons.search_rounded,
            label: 'Buscar Productos',
            onTap: onCatalog,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _LegacyActionButton(
            icon: Icons.chat_rounded,
            onTap: onContact,
          ),
        ),
      ],
    );
  }
}

class _LegacyActionButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final VoidCallback onTap;

  const _LegacyActionButton({
    required this.icon,
    required this.onTap,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 42,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.inverseSurface.withValues(alpha: 0.12),
          foregroundColor: colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.28),
            ),
          ),
        ),
        child: label == null
            ? Icon(icon, size: 18)
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 6),
                  const Flexible(
                    child: Text(
                      'Buscar Productos',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LegacyExpandedContent extends ConsumerWidget {
  final SheetBusinessData business;
  final VoidCallback onContact;
  final VoidCallback onCatalog;
  final VoidCallback onReviews;

  const _LegacyExpandedContent({
    required this.business,
    required this.onContact,
    required this.onCatalog,
    required this.onReviews,
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
        if (business.images.isNotEmpty) const SizedBox(height: 16),
        _LegacyWideButton(
          icon: Icons.emoji_emotions_outlined,
          text: 'Opinión General',
          onTap: onReviews,
        ),
        const SizedBox(height: 12),
        _LegacyContactCard(ownerName: ownerName, onContact: onContact),
        const SizedBox(height: 12),
        _LegacyCatalogCard(onCatalog: onCatalog),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LegacyWideButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _LegacyWideButton({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 58,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: colorScheme.inverseSurface.withValues(alpha: 0.12),
          foregroundColor: colorScheme.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.28),
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 26),
          ],
        ),
      ),
    );
  }
}

class _LegacyContactCard extends StatelessWidget {
  final String ownerName;
  final VoidCallback onContact;

  const _LegacyContactCard({required this.ownerName, required this.onContact});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_circle_outlined,
                color: colorScheme.onSurface.withValues(alpha: 0.8),
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                ownerName,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CompactAction(
                icon: Icons.chat_rounded,
                text: 'Mensaje',
                onTap: onContact,
              ),
              const SizedBox(width: 12),
              _CompactAction(
                icon: Icons.call_rounded,
                text: 'Llamar',
                onTap: onContact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegacyCatalogCard extends StatelessWidget {
  final VoidCallback onCatalog;

  const _LegacyCatalogCard({required this.onCatalog});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.28)),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 42,
            child: SearchBar(
              hintText: 'Buscar productos...',
              elevation: const WidgetStatePropertyAll(0),
              onTap: onCatalog,
              leading: const Icon(Icons.search_rounded, size: 18),
              backgroundColor: WidgetStatePropertyAll(
                colorScheme.surface.withValues(alpha: 0.85),
              ),
              hintStyle: WidgetStatePropertyAll(
                TextStyle(color: colorScheme.onSurface.withValues(alpha: 0.65)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onCatalog,
              icon: const Icon(Icons.inventory_2_rounded, size: 18),
              label: const Text('Ver catálogo'),
              style: TextButton.styleFrom(
                foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactAction extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;

  const _CompactAction({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: colorScheme.inverseSurface.withValues(alpha: 0.12),
        foregroundColor: colorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: colorScheme.outline.withValues(alpha: 0.28)),
        ),
      ),
    );
  }
}
