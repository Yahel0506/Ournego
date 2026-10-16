import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/motion/motion_window.dart';
import 'package:ournego/core/motion/ournego_motion_level.dart';
import 'package:ournego/core/motion/spring_clock.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/business_hours_compact_card.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/minimized_stack.dart';
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

  /// [origin] is the sheet's rectangle, so a login page can grow out of it.
  final Future<bool> Function(SheetBusinessData business, Rect? origin)
  onFavorite;

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

/// The sheet's frame, found by tests to measure it.
const Key frameKey = ValueKey('floatingSheetFrame');

class _OurnegoFloatingSheetState extends State<OurnegoFloatingSheet>
    with TickerProviderStateMixin {
  static const double _stackLeft = 12;
  static const double _stackIconSize = MinimizedStack.iconSize;

  bool _isFavoriteUpdating = false;

  /// Entry: 0 at the origin of the opening (or below the screen), 1 at rest.
  late final SpringClock _entry;

  /// Expansion: 0 collapsed, 1 expanded. Follows the finger during a drag.
  late final SpringClock _expand;

  /// Minimize: 0 is the sheet, 1 is the stacked icon.
  late final SpringClock _minimize;

  /// Business the sheet has been showing, or null while it is hidden.
  String? _shownId;

  /// Where the sheet grew from and goes back to. Null makes it leave downwards.
  SheetOrigin? _entryOrigin;

  bool _dragging = false;
  final _frameBoxKey = GlobalKey(debugLabel: 'floatingSheetFrameBox');

  /// Dismissal by dragging down: 0 at rest, 1 when the sheet has been pushed
  /// down by [_dismissRange] and shrunk. It is the first phase of every close.
  late final SpringClock _dismiss;

  /// How far the finger pushed the sheet down, in dp.
  double _dismissPx = 0;

  /// A close is waiting for the first phase to finish before heading to the
  /// origin.
  bool _closeStaged = false;

  static const double _dismissRange = 280;
  static const double _dismissCommitPx = 96;
  static const double _dismissCommitVelocity = 700;

  /// Fraction of the dismissal after which the sheet starts to go back.
  static const double _dismissHandover = 0.75;

  @override
  void initState() {
    super.initState();
    final controller = widget.controller;
    _entry = SpringClock(vsync: this, preset: kFloatingSheetSpring, initial: 1)
      ..onSettled = _onEntrySettled;
    _expand = SpringClock(
      vsync: this,
      preset: kSheetExpandSpring,
      initial: controller.state == FloatingSheetState.expanded ? 1 : 0,
    )..onSettled = _onExpandSettled;
    _minimize = SpringClock(vsync: this, preset: kMinimizeSpring)
      ..onSettled = _onMinimizeSettled;
    _dismiss = SpringClock(vsync: this, preset: kSheetExpandSpring);
    _shownId = controller.activeBusiness?.id;
    _entry.animation.addListener(_publishEntryProgress);
    _dismiss.animation.addListener(_onDismissTick);
    controller.addListener(_onControllerChanged);
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
    _entry.animation.removeListener(_publishEntryProgress);
    _dismiss.animation.removeListener(_onDismissTick);
    _dismiss.dispose();
    _entry.dispose();
    _expand.dispose();
    _minimize.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    if (!mounted) {
      return;
    }
    _syncSheetMotion();
    setState(() {});
  }

  bool get _reducedMotion =>
      !OurnegoMotion.containerTransformEnabled.value ||
      (MediaQuery.maybeOf(context)?.disableAnimations ?? false);

  /// Drives the springs from the controller's state. Only the springs that
  /// change are moved, so a settled sheet does not restart its animations.
  void _syncSheetMotion() {
    final controller = widget.controller;
    final active = controller.activeBusiness;
    if (active == null) {
      _shownId = null;
      _entryOrigin = null;
      _closeStaged = false;
      _dismissPx = 0;
      _dismiss.jumpTo(0);
      _expand.jumpTo(0);
      return;
    }

    var instant = _reducedMotion;
    if (_shownId == null) {
      final entry = controller.takePendingEntry();
      instant = instant || (entry?.instant ?? false);
      _entryOrigin = entry?.origin;
      _entry.preset = (_entryOrigin?.isStackIcon ?? false)
          ? kRestoreSpring
          : kFloatingSheetSpring;
      _entry.jumpTo(instant ? 1 : 0);
      _minimize.jumpTo(0);
      _expand.jumpTo(controller.state == FloatingSheetState.expanded ? 1 : 0);
    }
    _shownId = active.id;

    final closing =
        controller.pendingClearActive && !controller.pendingMinimizeToStack;
    if (closing) {
      if (_entry.target != 0 && !_closeStaged) {
        if (instant) {
          _beginClose(instant: true);
        } else {
          // First the sheet sinks and shrinks; the way back starts from there.
          _closeStaged = true;
          if (_dismiss.target != 1) {
            _dismiss.settleTo(1);
          }
        }
      }
    } else {
      _closeStaged = false;
      _dismissPx = 0;
      _move(_dismiss, 0, instant);
      _move(_entry, 1, instant);
    }
    _move(
      _minimize,
      controller.pendingMinimizeToStack && controller.pendingClearActive
          ? 1
          : 0,
      instant,
    );
    if (!_dragging && controller.state != FloatingSheetState.minimized) {
      _move(
        _expand,
        controller.state == FloatingSheetState.expanded ? 1 : 0,
        instant,
      );
    }
  }

  void _onDismissTick() {
    if (_closeStaged && _dismiss.value >= _dismissHandover) {
      _closeStaged = false;
      _beginClose(instant: false);
    }
  }

  void _beginClose({required bool instant}) {
    // The origin may have moved or disappeared since the sheet opened. The
    // target is fixed for the whole close, so it never jumps mid-way.
    final origin = _entryOrigin;
    final resolved = origin?.resolve?.call();
    _entryOrigin = origin != null && resolved != null
        ? origin.withRect(resolved)
        : null;
    _move(_entry, 0, instant);
  }

  void _move(SpringClock clock, double target, bool instant) {
    if (clock.target == target) {
      return;
    }
    if (instant) {
      clock.jumpTo(target);
      clock.onSettled?.call(target);
    } else {
      clock.animateTo(target);
    }
  }

  void _publishEntryProgress() {
    widget.controller.entryProgress.value = _entry.value;
  }

  /// Closing has finished: the business leaves the sheet.
  void _onEntrySettled(double target) {
    final controller = widget.controller;
    if (target == 0 && controller.pendingClearActive) {
      controller.finalizeTransitionOut();
    }
  }

  /// The spring decided the new expansion, so the state follows it.
  void _onExpandSettled(double target) {
    final controller = widget.controller;
    if (controller.activeBusiness == null ||
        controller.state == FloatingSheetState.minimized) {
      return;
    }
    controller.transitionTo(
      target > 0.5 ? FloatingSheetState.expanded : FloatingSheetState.collapsed,
    );
  }

  /// The sheet has become the stacked icon: it is removed from the sheet and
  /// the icon takes its place in the stack.
  void _onMinimizeSettled(double target) {
    final controller = widget.controller;
    if (target > 0.5 && controller.pendingMinimizeToStack) {
      controller.finalizeTransitionOut();
    }
  }

  /// The rectangle of stack slot [index] in local coordinates.
  Rect _slotRect(int index) {
    final offset = MinimizedStack.slotOffset(
      _stackLeft,
      widget.sideStackTop,
      index,
    );
    return offset & const Size.square(_stackIconSize);
  }

  /// The stack icon is not there once the sheet is open, so there is nothing
  /// to go back to: closing leaves downwards.
  SheetOrigin? _stackOrigin(int index) {
    final rect = _stackIconRectGlobal(index);
    return rect == null
        ? null
        : SheetOrigin(
            rect: rect,
            radius: OurnegoRadiusTokens.innerCard,
            isStackIcon: true,
          );
  }

  Rect? _stackIconRectGlobal(int index) {
    final local = _slotRect(index);
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached) {
      return null;
    }
    return box.localToGlobal(local.topLeft) & local.size;
  }

  /// The sheet's rectangle on screen, or null when it is not showing.
  Rect? _sheetRect() {
    final box = _frameBoxKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      return null;
    }
    return box.localToGlobal(Offset.zero) & box.size;
  }

  Rect? _toLocal(Rect global) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) {
      return null;
    }
    return box.globalToLocal(global.topLeft) & global.size;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final activeBusiness = controller.activeBusiness;
    final comparisonBusiness = controller.comparisonBusiness;
    final isComparisonMode = controller.isComparisonMode;

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildScrim(controller),
        if (!isComparisonMode) _buildMinimizedStack(controller),
        if (activeBusiness != null) _buildSheetLayer(controller),
        if (activeBusiness != null && comparisonBusiness != null)
          _buildComparisonSheets(
            primaryBusiness: activeBusiness,
            secondaryBusiness: comparisonBusiness,
            controller: controller,
          ),
      ],
    );
  }

  /// Dims the map while the sheet is expanded (and while comparing). The
  /// dimming follows the expansion, so it never jumps.
  Widget _buildScrim(FloatingSheetController controller) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _expand.animation,
          _entry.animation,
          _minimize.animation,
        ]),
        builder: (context, _) {
          final isComparing = controller.isComparisonMode;
          final blocks =
              isComparing || controller.state == FloatingSheetState.expanded;
          final alpha = isComparing
              ? kComparisonScrimAlpha
              : kSheetExpandSpring.scrimAlpha *
                    _expand.value.clamp(0.0, 1.0) *
                    // The dimming leaves with the sheet when it minimizes or
                    // closes, even from the expanded state.
                    (1 - _segment(_minimize.value, 0, 0.6)) *
                    _segment(_entry.value, 0, 0.3);
          return IgnorePointer(
            ignoring: !blocks,
            child: GestureDetector(
              key: const ValueKey('floatingSheetScrim'),
              behavior: HitTestBehavior.opaque,
              onTap: widget.controller.handleBack,
              child: ColoredBox(color: Colors.black.withValues(alpha: alpha)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMinimizedStack(FloatingSheetController controller) {
    // The business that is becoming an icon is already in the list, in its
    // final slot, but is only drawn once the sheet has arrived there.
    final hiddenId = controller.pendingMinimizeToStack
        ? controller.activeBusiness?.id
        : null;
    return Positioned.fill(
      child: MinimizedStack(
        businesses: controller.minimizedBusinesses,
        left: _stackLeft,
        top: widget.sideStackTop,
        hiddenId: hiddenId,
        restoringId: controller.activeBusiness?.id,
        onTap: (business, index) => controller.onMinimizedBusinessTap(
          business.id,
          origin: _stackOrigin(index),
        ),
        onLongPress: (business) => controller.removeFromMinimized(business.id),
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
                          final success = await widget.onFavorite(
                            business,
                            _sheetRect(),
                          );
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

  /// The main sheet: one surface whose frame moves between its origin, its
  /// resting place (depending on the expansion) and the stacked icon.
  Widget _buildSheetLayer(FloatingSheetController controller) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _entry.animation,
          _expand.animation,
          _minimize.animation,
          _dismiss.animation,
        ]),
        builder: (context, _) {
          final business = controller.activeBusiness;
          if (business == null) {
            return const SizedBox.shrink();
          }
          return LayoutBuilder(
            builder: (context, constraints) => Stack(
              fit: StackFit.expand,
              children: [
                _buildFrame(controller, business, constraints.biggest),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Sheet rectangle when the sheet is at rest for expansion [pe].
  Rect _restingRect(Size stack, double pe) {
    final availableWidth = stack.width - 24;
    final sheetWidth = availableWidth > widget.maxWidth
        ? widget.maxWidth
        : availableWidth;
    final left = ((stack.width - sheetWidth) / 2).clamp(12.0, double.infinity);
    final height =
        widget.collapsedHeight +
        (widget.expandedHeight - widget.collapsedHeight) * pe;
    return Rect.fromLTWH(
      left,
      stack.height - widget.bottomOffset - height,
      sheetWidth,
      height,
    );
  }

  Widget _buildFrame(
    FloatingSheetController controller,
    SheetBusinessData business,
    Size stack,
  ) {
    final po = _entry.value.clamp(0.0, 1.0);
    final pe = _expand.value.clamp(0.0, 1.0);
    final pm = _minimize.value.clamp(0.0, 1.0);
    final resting = _restingRect(stack, pe);
    final entryOrigin = _entryOrigin;
    final origin = entryOrigin == null ? null : _toLocal(entryOrigin.rect);
    // The same smooth curve as the windows: a marker or row leans into the
    // sheet's place. From the bottom edge the sheet simply rises.
    final opened = origin == null
        ? resting.shift(Offset(0, (1 - po) * (stack.height - resting.top)))
        : _along(origin, resting, po, kFloatingSheetSpring.verticalPath);
    final slot = controller.minimizedBusinesses.indexWhere(
      (b) => b.id == business.id,
    );
    final iconRect = _slotRect(slot < 0 ? 0 : slot);
    // The finger (or the first phase of a close) pushes the sheet down and
    // shrinks it; the push relaxes while the sheet goes back to its origin.
    final dismissal = _dismiss.value.clamp(0.0, 1.0);
    final push = dismissal * _dismissRange * (1 - 0.3 * dismissal) * po;
    final shrink = 1 - 0.12 * dismissal;
    final frame = _along(
      opened,
      iconRect,
      pm,
      kMinimizeSpring.verticalPath,
    ).shift(Offset(0, push));
    final entryRadius = _lerpDouble(
      entryOrigin?.radius ?? OurnegoRadiusTokens.window,
      OurnegoRadiusTokens.window,
      _segment(po, 0, 1) * (2 - _segment(po, 0, 1)),
    );
    final radius = BorderRadius.circular(
      _lerpDouble(entryRadius, OurnegoRadiusTokens.innerCard, pm),
    );

    // A sheet from a marker appears as the marker grows; one from the bottom
    // edge slides up in full.
    final shown = controller.isComparisonMode ? 0.0 : 1.0;
    // From a marker the frame is first the marker itself (its circle, color and
    // border) and settles into the sheet's surface over the first 30 %.
    final markerColor = origin == null ? null : entryOrigin?.color;
    final settle = _segment(po, 0, 0.3);
    final edge = (origin == null ? 1.0 : settle) * shown;
    final fade = (origin == null || markerColor != null ? 1.0 : settle) * shown;
    // On arrival the frame is replaced by the stack's own icon, which draws
    // its own fill and border, so the frame's give way to it.
    final handover = 1 - _segment(pm, 0.6, 1);
    final chrome = fade * handover;
    final contentAlpha =
        _segment(
          po,
          kFloatingSheetSpring.contentStart,
          kFloatingSheetSpring.contentEnd,
        ) *
        (1 - _segment(pm, 0, 0.3)) *
        (1 - _segment(dismissal, 0.5, 1)) *
        shown;
    final iconAlpha =
        _segment(pm, kMinimizeSpring.contentStart, kMinimizeSpring.contentEnd) *
        shown;
    // Content travels blurred and sharpens at the end (level B only).
    final blurOn =
        OurnegoMotion.resolveLevel(context, wantsBlur: true) ==
        OurnegoMotionLevel.b;
    final contentBlur = blurOn
        ? math.max(
            math.max(
              transitBlurSigma(po, kFloatingSheetSpring),
              kMinimizeSpring.maxItemBlur * _segment(pm, 0, 0.1),
            ),
            kFloatingSheetSpring.maxItemBlur * _segment(dismissal, 0, 0.5),
          )
        : 0.0;
    final iconBlur = blurOn ? transitBlurSigma(pm, kMinimizeSpring) : 0.0;
    final interactive =
        shown == 1 &&
        po > 0.5 &&
        pm < 0.5 &&
        !controller.pendingClearActive &&
        !controller.pendingMinimizeToStack;

    final colorScheme = Theme.of(context).colorScheme;
    final fillColor = markerColor == null
        ? colorScheme.surface
        : Color.lerp(markerColor, colorScheme.surface, settle)!;
    final borderColor = markerColor == null
        ? colorScheme.outline.withValues(alpha: 0.3)
        : Color.lerp(
            entryOrigin?.foregroundColor ?? colorScheme.outline,
            colorScheme.outline.withValues(alpha: 0.3),
            settle,
          )!;
    final markerAlpha = markerColor == null ? 0.0 : (1 - _segment(po, 0, 0.25));
    final markerBlur = blurOn
        ? kFloatingSheetSpring.maxItemBlur * _segment(po, 0, 0.1)
        : 0.0;
    return Positioned.fromRect(
      rect: frame,
      child: Transform.scale(
        scale: shrink,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: interactive ? _onSheetDragStart : null,
          onVerticalDragUpdate: interactive ? _onSheetDragUpdate : null,
          onVerticalDragEnd: interactive ? _onSheetDragEnd : null,
          child: IgnorePointer(
            ignoring: !interactive,
            child: DecoratedBox(
              key: _frameBoxKey,
              decoration: BoxDecoration(
                color: fillColor.withValues(alpha: chrome),
                border: Border.all(
                  color: borderColor.withValues(
                    alpha: borderColor.a * edge * handover,
                  ),
                  width: markerColor == null ? 1 : _lerpDouble(2, 1, settle),
                ),
                borderRadius: radius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.35 * edge * handover,
                    ),
                    blurRadius: 24,
                    spreadRadius: -4,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                key: frameKey,
                borderRadius: radius,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // What the marker looked like melts into the sheet's content.
                    if (markerAlpha > 0 && entryOrigin?.icon != null)
                      Center(
                        child: _blurred(
                          markerBlur,
                          Opacity(
                            opacity: markerAlpha * shown,
                            child: Icon(
                              entryOrigin!.icon,
                              size: 18,
                              color: entryOrigin.foregroundColor,
                            ),
                          ),
                        ),
                      ),
                    // The card keeps its resting size and rides the frame's
                    // center, so it is never squeezed while the frame moves.
                    OverflowBox(
                      alignment: Alignment.center,
                      minWidth: resting.width,
                      maxWidth: resting.width,
                      minHeight: resting.height,
                      maxHeight: resting.height,
                      child: SizedBox(
                        width: resting.width,
                        height: resting.height,
                        child: _blurred(
                          contentBlur,
                          Opacity(
                            opacity: contentAlpha,
                            child: _buildSheetCard(
                              business: business,
                              controller: controller,
                              pe: pe,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (iconAlpha > 0)
                      Center(
                        child: _blurred(
                          iconBlur,
                          Opacity(
                            opacity: iconAlpha,
                            child: SizedBox.square(
                              dimension: _stackIconSize,
                              child: MinimizedStackIcon(
                                business: business,
                                onTap: () {},
                                onLongPress: () {},
                              ),
                            ),
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
    );
  }

  /// Moves from [from] to [to] with the plain route, and the vertical position
  /// on [path] when there is one (as in the windows).
  Rect _along(Rect from, Rect to, double p, Curve? path) {
    final rect = Rect.lerp(from, to, p)!;
    if (path == null) {
      return rect;
    }
    final g = p.clamp(0.0, 1.0);
    return rect.shift(
      Offset(0, (path.transform(g) - g) * (to.center.dy - from.center.dy)),
    );
  }

  Widget _blurred(double sigma, Widget child) {
    return ImageFiltered(
      enabled: sigma > 0.1,
      imageFilter: ui.ImageFilter.blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: TileMode.decal,
      ),
      child: child,
    );
  }

  /// The content of the sheet. The collapsed actions leave during the first
  /// 30 % of the expansion and the expanded content arrives over 35–75 %.
  Widget _buildSheetCard({
    required SheetBusinessData business,
    required FloatingSheetController controller,
    required double pe,
  }) {
    final isExpanded = controller.state == FloatingSheetState.expanded;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Column(
        children: [
          _AnimatedDragHandle(isExpanded: isExpanded),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TypeRatingBadgeRow(type: business.type, rating: business.rating),
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

                        controller.toggleFavorite();
                        final success = await widget.onFavorite(
                          business,
                          _sheetRect(),
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
            child: SheetHeader(name: business.name, isExpanded: isExpanded),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    ignoring: pe >= 0.5,
                    child: Opacity(
                      opacity: 1 - _segment(pe, 0, 0.3),
                      child: SingleChildScrollView(
                        // In the collapsed state, available height can be
                        // smaller than the actions' intrinsic size (especially
                        // in widget tests). Scrolling/clip avoids RenderFlex
                        // overflow without changing the visible layout in
                        // normal use.
                        physics: const NeverScrollableScrollPhysics(),
                        child: _CollapsedActions(
                          onContact: (origin) =>
                              widget.onContact(business, origin),
                          onCatalog: () => widget.onCatalog(business),
                          onReviews: () => widget.onReviews(business),
                          onShare: () => widget.onShare(business),
                        ),
                      ),
                    ),
                  ),
                ),
                if (pe > 0)
                  Positioned.fill(
                    child: IgnorePointer(
                      ignoring: pe < 0.5,
                      child: Opacity(
                        opacity: _segment(pe, 0.35, 0.75),
                        child: _ExpandedContent(
                          business: business,
                          onContact: (origin) =>
                              widget.onContact(business, origin),
                          onCatalog: () => widget.onCatalog(business),
                          onReviews: () => widget.onReviews(business),
                          onShare: () => widget.onShare(business),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double get _dragTravel {
    final travel = widget.expandedHeight - widget.collapsedHeight;
    return travel > 0 ? travel : 1;
  }

  /// The finger takes the sheet directly, with no spring in the way. Dragging
  /// down first collapses an expanded sheet; what is left of the movement
  /// pushes the sheet down to dismiss it. Dragging up undoes it in reverse.
  void _onSheetDragStart(DragStartDetails details) {
    _dragging = true;
    _expand.dragTo(_expand.value);
    _dismiss.dragTo(_dismiss.value);
    _dismissPx = _dismiss.value * _dismissRange;
  }

  void _onSheetDragUpdate(DragUpdateDetails details) {
    var dy = details.delta.dy;
    if (dy > 0) {
      final room = _expand.value * _dragTravel;
      final used = dy < room ? dy : room;
      _expand.dragTo(_expand.value - used / _dragTravel);
      dy -= used;
      _dismissPx += dy;
    } else if (dy < 0) {
      final used = -dy < _dismissPx ? -dy : _dismissPx;
      _dismissPx -= used;
      dy += used;
      _expand.dragTo((_expand.value - dy / _dragTravel).clamp(0.0, 1.0));
    }
    _dismiss.dragTo((_dismissPx / _dismissRange).clamp(0.0, 1.0));
  }

  /// Pushed far enough, or flung down: the sheet is dismissed. Otherwise it
  /// springs back; flings up or down decide the expansion, slow releases
  /// settle to the nearer end.
  void _onSheetDragEnd(DragEndDetails details) {
    _dragging = false;
    final controller = widget.controller;
    final velocity = details.primaryVelocity ?? 0;
    final pushed = _dismissPx > 0;
    final flungDown = velocity > _dismissCommitVelocity && _expand.value < 0.1;

    if ((pushed && _dismissPx >= _dismissCommitPx) || flungDown) {
      _expand.settleTo(0);
      _dismiss.settleTo(1, velocity: velocity / _dismissRange);
      controller.closeActiveBusiness();
      return;
    }
    if (pushed) {
      _dismissPx = 0;
      _dismiss.settleTo(0, velocity: velocity / _dismissRange);
    }

    final expands =
        velocity < -500 || (velocity.abs() <= 500 && _expand.value >= 0.5);
    _expand.settleTo(expands ? 1 : 0, velocity: -velocity / _dragTravel);
  }
}

double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

/// Progress of [value] between [start] and [end], clamped to 0..1.
double _segment(double value, double start, double end) {
  return ((value - start) / (end - start)).clamp(0.0, 1.0);
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
