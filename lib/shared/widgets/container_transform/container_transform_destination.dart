import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:ournego/core/motion/motion_window.dart';
import 'package:ournego/core/motion/ournego_motion_level.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';

/// Where the trigger is covered by the window, in units of the clock `p`.
const double kTriggerCoveredAt = 0.12;

/// State of one open window, shared by the route and the destination widget.
class ContainerTransformController {
  ContainerTransformController({
    required this.animation,
    required this.preset,
    required this.level,
    this.originSource,
  }) : origin = originSource?.measure();

  /// The route's clock `p`, bounded to [0, 1] and driven by a spring.
  final Animation<double> animation;
  final OurnegoSpringPreset preset;
  final OurnegoMotionLevel level;
  final ContainerTransformOriginController? originSource;

  /// Null when there is no trigger (or it is gone): the window then just grows
  /// a little around its own center.
  ContainerTransformOriginData? origin;

  /// Whether a [ContainerTransformDestination] is on screen. A window without
  /// one still gets a plain fade.
  bool hasDestination = false;

  /// Measures the trigger again; called when the window starts to close, since
  /// it may have moved or disappeared meanwhile.
  void remeasureOrigin() {
    final source = originSource;
    if (source != null) origin = source.measure();
  }
}

class ContainerTransformScope extends InheritedWidget {
  const ContainerTransformScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final ContainerTransformController controller;

  static ContainerTransformController? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ContainerTransformScope>()
      ?.controller;

  @override
  bool updateShouldNotify(ContainerTransformScope oldWidget) =>
      controller != oldWidget.controller;
}

/// Marks the visible surface of a window (the glass card, not the empty area
/// around it) as the destination of the container transform.
///
/// The surface is laid out once at its final size. What grows from the trigger
/// is a clip, so nothing reflows while it opens. Outside a
/// `showOurnegoDialog` / `showOurnegoMenu` route it is transparent.
class ContainerTransformDestination extends StatelessWidget {
  const ContainerTransformDestination({
    super.key,
    required this.child,
    this.radius = OurnegoRadiusTokens.window,
    this.fillColor,
  });

  final Widget child;

  /// Radius of the surface at rest.
  final double radius;

  /// Color the container takes on while it grows; defaults to the theme's
  /// surface.
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final controller = ContainerTransformScope.maybeOf(context);
    if (controller == null) return child;

    Widget content = child;
    if (controller.level == OurnegoMotionLevel.b) {
      // The level never changes during a route, so this wrapper (and the state
      // of the child under it) is stable. `enabled` skips the layer at rest.
      content = AnimatedBuilder(
        animation: controller.animation,
        child: child,
        builder: (context, child) {
          final preset = controller.preset;
          final t = seg(
            controller.animation.value,
            preset.contentStart,
            preset.contentEnd,
            Curves.easeOut,
          );
          final sigma = preset.maxItemBlur * (1 - t);
          return ImageFiltered(
            enabled: sigma > 0.1,
            imageFilter: ui.ImageFilter.blur(
              sigmaX: sigma,
              sigmaY: sigma,
              tileMode: TileMode.decal,
            ),
            child: child,
          );
        },
      );
    }

    return _DestinationRenderWidget(
      controller: controller,
      radius: radius,
      fill: fillColor ?? Theme.of(context).colorScheme.surface,
      child: content,
    );
  }
}

class _DestinationRenderWidget extends SingleChildRenderObjectWidget {
  const _DestinationRenderWidget({
    required this.controller,
    required this.radius,
    required this.fill,
    required super.child,
  });

  final ContainerTransformController controller;
  final double radius;
  final Color fill;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      RenderContainerTransformDestination(
        controller: controller,
        radius: radius,
        fill: fill,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderContainerTransformDestination renderObject,
  ) {
    renderObject
      ..controller = controller
      ..radius = radius
      ..fill = fill;
  }
}

class RenderContainerTransformDestination extends RenderProxyBox {
  RenderContainerTransformDestination({
    required ContainerTransformController controller,
    required double radius,
    required Color fill,
  }) : _controller = controller,
       _radius = radius,
       _fill = fill;

  ContainerTransformController _controller;
  ContainerTransformController get controller => _controller;
  set controller(ContainerTransformController value) {
    if (identical(value, _controller)) return;
    if (attached) _controller.animation.removeListener(markNeedsPaint);
    _controller = value;
    if (attached) {
      _controller.hasDestination = true;
      _controller.animation.addListener(markNeedsPaint);
    }
    markNeedsPaint();
  }

  double _radius;
  set radius(double value) {
    if (value == _radius) return;
    _radius = value;
    markNeedsPaint();
  }

  Color _fill;
  set fill(Color value) {
    if (value == _fill) return;
    _fill = value;
    markNeedsPaint();
  }

  /// The rect the container painted last, in global coordinates. For tests.
  @visibleForTesting
  Rect? lastPaintedRect;

  // Where the content is painted relative to its final place while the window
  // opens: it rides the container's center. Zero at rest.
  Offset _contentOffset = Offset.zero;

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _controller.hasDestination = true;
    _controller.animation.addListener(markNeedsPaint);
  }

  @override
  void detach() {
    _controller.animation.removeListener(markNeedsPaint);
    super.detach();
  }

  double get _contentProgress => seg(
    _controller.animation.value,
    _controller.preset.contentStart,
    _controller.preset.contentEnd,
    Curves.easeOut,
  );

  /// Items only respond once they are at least half visible; the scrim and the
  /// back gesture respond from the first frame.
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (_controller.animation.value < 1 && _contentProgress <= 0.5) {
      return false;
    }
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: _contentOffset,
      position: position,
      hitTest: (result, position) => child.hitTest(result, position: position),
    );
  }

  @override
  void applyPaintTransform(RenderObject child, Matrix4 transform) {
    transform.translateByDouble(_contentOffset.dx, _contentOffset.dy, 0, 1);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;

    final p = _controller.animation.value;
    final topLeft = localToGlobal(Offset.zero);
    lastPaintedRect = topLeft & size;

    // At rest this is the plain child: no clip, no layer.
    if (p >= 1) {
      _contentOffset = Offset.zero;
      context.paintChild(child, offset);
      return;
    }

    if (_controller.level == OurnegoMotionLevel.r) {
      _contentOffset = Offset.zero;
      if (p <= 0) return;
      context.pushOpacity(
        offset,
        (p.clamp(0.0, 1.0) * 255).round(),
        (context, offset) => context.paintChild(child, offset),
      );
      return;
    }

    final preset = _controller.preset;
    final g = p.clamp(0.0, 1.0);
    final destination = topLeft & size;
    final origin = _controller.origin;

    final Rect from;
    final double fromRadius;
    final Color fromColor;
    if (origin != null) {
      from = origin.rect;
      fromRadius = origin.radius;
      fromColor = origin.color;
    } else {
      from = Rect.fromCenter(
        center: destination.center,
        width: destination.width * 0.92,
        height: destination.height * 0.92,
      );
      fromRadius = _radius;
      fromColor = _fill;
    }

    var globalRect = Rect.lerp(from, destination, g)!;

    // The vertical position follows its own smooth curve over the whole path
    // (it leans in, passes the destination slightly and settles back); the
    // horizontal position and the size follow the plain route.
    final verticalPath = preset.verticalPath;
    if (verticalPath != null) {
      final travelY = destination.center.dy - from.center.dy;
      globalRect = globalRect.shift(
        Offset(0, (verticalPath.transform(g) - g) * travelY),
      );
    }
    lastPaintedRect = globalRect;
    // Relative to this box, which is what pushClipRRect expects together with
    // the paint offset.
    final localRect = globalRect.shift(-topLeft);
    final radius = ui.lerpDouble(
      fromRadius,
      _radius,
      seg(p, 0, 1, Curves.easeOut),
    )!;
    final rrect = RRect.fromRectAndRadius(localRect, Radius.circular(radius));

    // The container takes over from the trigger in the first frames, and gives
    // way to the surface's own glass at the end.
    final fillAlpha =
        seg(p, 0, kTriggerCoveredAt) * (1 - seg(p, preset.contentEnd - 0.1, 1));
    if (fillAlpha > 0) {
      final color = Color.lerp(
        fromColor,
        _fill,
        seg(p, 0, 0.5, Curves.easeOut),
      )!;
      context.canvas.drawRRect(
        rrect.shift(offset),
        Paint()..color = color.withValues(alpha: color.a * fillAlpha),
      );
    }

    // The content is not revealed in place: it travels with the container,
    // keeping its center on the container's center, and the container's clip
    // shows as much of it as fits.
    _contentOffset = globalRect.center - destination.center;

    final t = _contentProgress;
    if (t <= 0) return;

    context.pushClipRRect(needsCompositing, offset, localRect, rrect, (
      context,
      offset,
    ) {
      context.pushOpacity(
        offset,
        (t * 255).round(),
        (context, offset) => context.paintChild(child, offset + _contentOffset),
      );
    });
  }
}
