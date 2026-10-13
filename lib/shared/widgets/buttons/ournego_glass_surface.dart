import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';

/// Non-pressable flat glass container for the map search bar (spec §6.12):
/// glass face, blur and a 1 px contour. The contour reacts to hover and to
/// focus inside [child], which also shows a 3 px outer glow.
class OurnegoGlassSurface extends StatefulWidget {
  const OurnegoGlassSurface({
    super.key,
    required this.child,
    this.borderRadius = OurnegoRadiusTokens.container,
    this.height = OurnegoComponentMetrics.glassSurfaceHeight,
  });

  static const Duration _focusDuration = Duration(milliseconds: 200);

  final Widget child;
  final double borderRadius;
  final double height;

  /// Whether a descendant of the nearest surface has focus.
  static bool isFocusedOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_GlassSurfaceScope>()
            ?.focused ??
        false;
  }

  @override
  State<OurnegoGlassSurface> createState() => _OurnegoGlassSurfaceState();
}

class _OurnegoGlassSurfaceState extends State<OurnegoGlassSurface> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(widget.borderRadius);
    final border = _focused
        ? OurnegoGlassPalette.active(scheme)
        : _hovered
        ? OurnegoGlassPalette.borderHover(scheme)
        : OurnegoGlassPalette.border(scheme);
    const glow = OurnegoComponentMetrics.focusGlowWidth;

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (value) => setState(() => _focused = value),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: _GlassSurfaceScope(
          focused: _focused,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: -glow,
                top: -glow,
                right: -glow,
                bottom: -glow,
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _focused ? 1 : 0,
                    duration: OurnegoGlassSurface._focusDuration,
                    curve: kCalmCurve,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius + BorderRadius.circular(glow),
                        border: Border.all(
                          color: OurnegoGlassPalette.focusGlow(scheme),
                          width: glow,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: radius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: OurnegoGlassPalette.blurSigma,
                    sigmaY: OurnegoGlassPalette.blurSigma,
                  ),
                  child: AnimatedContainer(
                    duration: OurnegoGlassSurface._focusDuration,
                    curve: kCalmCurve,
                    height: widget.height,
                    decoration: BoxDecoration(
                      color: OurnegoGlassPalette.face(scheme),
                      borderRadius: radius,
                      border: Border.all(
                        color: border,
                        width: OurnegoComponentMetrics.borderWidth,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassSurfaceScope extends InheritedWidget {
  const _GlassSurfaceScope({required this.focused, required super.child});

  final bool focused;

  @override
  bool updateShouldNotify(covariant _GlassSurfaceScope oldWidget) =>
      oldWidget.focused != focused;
}

/// Leading icon for content inside [OurnegoGlassSurface] (the search
/// magnifier): accent ink and scale 1.06 while the surface has focus.
class OurnegoGlassSurfaceIcon extends StatelessWidget {
  const OurnegoGlassSurfaceIcon(this.icon, {super.key});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final focused = OurnegoGlassSurface.isFocusedOf(context);
    return AnimatedScale(
      scale: focused ? 1.06 : 1,
      duration: kGlassReleaseDuration,
      curve: kCalmCurve,
      child: TweenAnimationBuilder<Color?>(
        tween: ColorTween(
          end: focused ? OurnegoGlassPalette.active(scheme) : scheme.onSurface,
        ),
        duration: OurnegoGlassSurface._focusDuration,
        curve: kCalmCurve,
        builder: (context, color, _) => Icon(
          icon,
          size: OurnegoComponentMetrics.glassIconSize,
          color: color,
        ),
      ),
    );
  }
}
