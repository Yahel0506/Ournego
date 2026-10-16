import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_route.dart';

/// The surface of a sheet docked to the bottom edge (see `showOurnegoSheet`).
///
/// Flat glass like the dialogs, with a drag handle. Its bottom corners and
/// border sit just below the screen edge, so it reads as docked. It is the
/// destination of the container transform and follows a finger that drags it
/// down: the sheet's progress `p` is the drag, and the scrim fades with it.
class OurnegoSheetSurface extends StatefulWidget {
  const OurnegoSheetSurface({super.key, required this.child});

  final Widget child;

  /// How far the surface extends below the screen edge, so its rounded bottom
  /// corners are out of sight.
  static const double hiddenBelow = OurnegoRadiusTokens.window;

  /// Releasing past this fraction of the sheet's height dismisses it.
  static const double dismissFraction = 0.3;

  /// A fling faster than this (dp/s) dismisses it, whatever the distance.
  static const double dismissVelocity = 700;

  @override
  State<OurnegoSheetSurface> createState() => _OurnegoSheetSurfaceState();
}

class _OurnegoSheetSurfaceState extends State<OurnegoSheetSurface> {
  ContainerTransformRoute<dynamic>? get _route {
    final route = ModalRoute.of(context);
    return route is ContainerTransformRoute ? route : null;
  }

  double _height = 1;
  final _surfaceKey = GlobalKey();

  void _onDragStart(DragStartDetails details) {
    final box = _surfaceKey.currentContext?.findRenderObject();
    _height = box is RenderBox
        ? box.size.height.clamp(1.0, double.infinity)
        : 1;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final route = _route;
    if (route == null) return;
    route.dragTo(route.progress - details.delta.dy / _height);
  }

  void _onDragEnd(DragEndDetails details) {
    final route = _route;
    if (route == null) return;
    final velocity = details.primaryVelocity ?? 0;
    final dismiss =
        velocity > OurnegoSheetSurface.dismissVelocity ||
        (velocity.abs() <= OurnegoSheetSurface.dismissVelocity &&
            route.progress < 1 - OurnegoSheetSurface.dismissFraction);
    route.endDrag(dismiss: dismiss, velocity: -velocity / _height);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final face = OurnegoGlassPalette.navFace(scheme);
    final media = MediaQuery.of(context);
    final insets = media.viewInsets.bottom;

    return Padding(
      // The whole sheet rises above the keyboard; its content does not need to.
      padding: EdgeInsets.only(bottom: insets),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Transform.translate(
          offset: const Offset(0, OurnegoSheetSurface.hiddenBelow),
          child: GestureDetector(
            onVerticalDragStart: _onDragStart,
            onVerticalDragUpdate: _onDragUpdate,
            onVerticalDragEnd: _onDragEnd,
            child: ContainerTransformDestination(
              radius: OurnegoRadiusTokens.window,
              fillColor: face,
              child: DecoratedBox(
                key: _surfaceKey,
                decoration: BoxDecoration(
                  color: face,
                  border: Border.all(color: OurnegoGlassPalette.border(scheme)),
                  borderRadius: BorderRadius.circular(
                    OurnegoRadiusTokens.window,
                  ),
                ),
                child: ContainerTransformBlur(
                  child: Material(
                    type: MaterialType.transparency,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        bottom: OurnegoSheetSurface.hiddenBelow,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            key: const Key('sheet-drag-handle'),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(
                              color: scheme.onSurface.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          Flexible(
                            fit: FlexFit.loose,
                            child: MediaQuery(
                              // The sheet already sits below the status bar and
                              // above the keyboard: its content must not keep
                              // those insets of its own.
                              data: media.copyWith(
                                padding: media.padding.copyWith(top: 0),
                                viewPadding: media.viewPadding.copyWith(top: 0),
                                viewInsets: media.viewInsets.copyWith(
                                  bottom: 0,
                                ),
                              ),
                              child: widget.child,
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
      ),
    );
  }
}
