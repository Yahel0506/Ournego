import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';

/// One destination of [OurnegoNavBar].
@immutable
class OurnegoNavBarItem {
  const OurnegoNavBarItem({required this.icon, required this.label});

  final IconData icon;

  /// Semantic label.
  final String label;
}

/// Opaque flat glass navigation bar (spec §6.10): 1 px contour, soft shadow,
/// height 72 and one aqua indicator that slides to the active item without
/// overshoot. No lip and no blur.
class OurnegoNavBar extends StatelessWidget {
  const OurnegoNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<OurnegoNavBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final radius = BorderRadius.circular(OurnegoRadiusTokens.pill);
    const itemSize = OurnegoComponentMetrics.navItemSize;

    return Container(
      height: OurnegoSpacingTokens.navHeight,
      padding: const EdgeInsets.all(OurnegoComponentMetrics.navPadding),
      decoration: BoxDecoration(
        color: OurnegoGlassPalette.navFace(scheme),
        borderRadius: radius,
        border: Border.all(
          color: OurnegoGlassPalette.border(scheme),
          width: OurnegoComponentMetrics.borderWidth,
        ),
        boxShadow: const [
          BoxShadow(
            color: OurnegoGlassPalette.navShadow,
            blurRadius: 10,
            spreadRadius: 0.2,
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / items.length;
          // The contour and padding can leave less than 56 px (e.g. inside
          // the bottom bar margin): shrink the indicator instead of clipping.
          final indicatorSize = math.min(itemSize, constraints.maxHeight);
          final top = (constraints.maxHeight - indicatorSize) / 2;
          return Stack(
            children: [
              AnimatedPositioned(
                key: ournegoNavIndicatorKey,
                duration: reduced ? Duration.zero : kNavIndicatorDuration,
                curve: kEaseOutExpo,
                left:
                    currentIndex * itemWidth + (itemWidth - indicatorSize) / 2,
                top: top,
                width: indicatorSize,
                height: indicatorSize,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    color: OurnegoGlassPalette.navIndicator,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Row(
                children: [
                  for (var i = 0; i < items.length; i++)
                    Expanded(
                      child: Center(
                        child: _NavItem(
                          item: items[i],
                          selected: i == currentIndex,
                          onTap: () => onTap(i),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Key of the sliding indicator, used by tests.
const ValueKey<String> ournegoNavIndicatorKey = ValueKey<String>(
  'ournegoNavIndicator',
);

class _NavItem extends StatefulWidget {
  const _NavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  static const double _pressedScale = 0.94;
  static const double _activeScale = 1.06;
  static const Duration _inkDuration = Duration(milliseconds: 200);
  static const Duration _activeScaleDuration = Duration(milliseconds: 300);

  final OurnegoNavBarItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem>
    with SingleTickerProviderStateMixin {
  // 0 = rest, 1 = pressed; bounded, so no overshoot.
  late final AnimationController _press;
  bool _hovered = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  void _down() =>
      _press.animateTo(1, duration: kGlassPressDuration, curve: Curves.easeOut);

  void _up() =>
      _press.animateTo(0, duration: kGlassReleaseDuration, curve: kCalmCurve);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const size = OurnegoComponentMetrics.navItemSize;
    final ink = widget.selected
        ? OurnegoGlassPalette.navIndicatorInk
        : scheme.onSurface;
    final ringOffset =
        OurnegoComponentMetrics.focusRingWidth +
        OurnegoComponentMetrics.focusRingGap;

    final visual = Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedContainer(
          duration: kGlassHoverDuration,
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hovered && !widget.selected
                ? OurnegoButtonPalette.ghostOverlay(scheme)
                : const Color(0x00000000),
          ),
          alignment: Alignment.center,
          child: AnimatedScale(
            scale: widget.selected ? _NavItem._activeScale : 1,
            duration: _NavItem._activeScaleDuration,
            curve: kCalmCurve,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: ink),
              duration: _NavItem._inkDuration,
              builder: (context, color, _) => Icon(
                widget.item.icon,
                size: OurnegoComponentMetrics.navIconSize,
                color: color,
              ),
            ),
          ),
        ),
        if (_focused)
          Positioned(
            left: -ringOffset,
            top: -ringOffset,
            right: -ringOffset,
            bottom: -ringOffset,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: OurnegoButtonPalette.focusRing(scheme),
                    width: OurnegoComponentMetrics.focusRingWidth,
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      label: widget.item.label,
      excludeSemantics: true,
      onTap: widget.onTap,
      child: FocusableActionDetector(
        mouseCursor: SystemMouseCursors.click,
        shortcuts: const <ShortcutActivator, Intent>{
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap();
              return null;
            },
          ),
        },
        onShowHoverHighlight: (value) => setState(() => _hovered = value),
        onShowFocusHighlight: (value) => setState(() => _focused = value),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTapDown: (_) => _down(),
          onTapUp: (_) => _up(),
          onTapCancel: _up,
          onTap: widget.onTap,
          child: AnimatedBuilder(
            animation: _press,
            child: visual,
            builder: (context, child) => Transform.scale(
              scale: lerpDouble(1, _NavItem._pressedScale, _press.value)!,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
