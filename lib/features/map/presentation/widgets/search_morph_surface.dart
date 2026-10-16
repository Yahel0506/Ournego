import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';

/// The search panel grows out of the search bar in place: its frame travels
/// from [barRect] to [panelRect] while the bar keeps its own focus.
///
/// [progress] is the spring clock `p` (0 = bar, 1 = panel). The frame lerps its
/// rect and radius; its fill fades from transparent to [fill] over the first
/// 30 %. The panel's content is laid out at its final size, centered on the
/// frame (it rides the container, as in route transforms) and clipped by it. It
/// fades in over [preset]'s content window, so nothing shows while the frame is
/// still the size of the bar.
///
/// [panelRect] is read on every frame, so a sheet that changes height under
/// the panel is followed without a rebuild of the parent.
class SearchMorphSurface extends StatelessWidget {
  const SearchMorphSurface({
    super.key,
    required this.progress,
    required this.barRect,
    required this.panelRect,
    required this.fill,
    required this.preset,
    required this.child,
  });

  /// Spring clock `p`, typically `SpringClock.animation`.
  final Animation<double> progress;

  /// Where the frame sits at `p = 0`, in this widget's coordinates.
  final Rect barRect;

  /// Where the frame sits at `p = 1`, computed from the available size.
  final Rect Function(Size size) panelRect;

  /// Opaque color of the panel surface.
  final Color fill;
  final OurnegoSpringPreset preset;
  final Widget child;

  /// Frame key used by tests to find the moving frame.
  static const Key frameKey = Key('search-morph-frame');

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final panel = panelRect(constraints.biggest);
        return AnimatedBuilder(
          animation: progress,
          child: child,
          builder: (context, child) {
            final p = progress.value.clamp(0.0, 1.0);
            final rect = Rect.lerp(barRect, panel, p)!;
            final radius = BorderRadius.lerp(
              BorderRadius.circular(OurnegoRadiusTokens.container),
              BorderRadius.circular(OurnegoRadiusTokens.window),
              p,
            )!;
            final fillAlpha = _segment(p, 0, 0.3);
            final contentAlpha = _segment(
              p,
              preset.contentStart,
              preset.contentEnd,
            );

            return SizedBox.expand(
              child: Stack(
                children: [
                  Positioned.fromRect(
                    rect: rect,
                    child: ClipRRect(
                      key: frameKey,
                      borderRadius: radius,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: fill.withValues(alpha: fillAlpha),
                        ),
                        child: OverflowBox(
                          alignment: Alignment.center,
                          minWidth: panel.width,
                          maxWidth: panel.width,
                          minHeight: panel.height,
                          maxHeight: panel.height,
                          child: SizedBox(
                            width: panel.width,
                            height: panel.height,
                            child: Opacity(opacity: contentAlpha, child: child),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  static double _segment(double value, double start, double end) {
    return ((value - start) / (end - start)).clamp(0.0, 1.0);
  }
}
