import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';

/// Where a window grows from: the trigger's rect on screen, plus the radius and
/// color it has, so the window can start looking like it.
@immutable
class ContainerTransformOriginData {
  const ContainerTransformOriginData({
    required this.rect,
    required this.radius,
    required this.color,
  });

  final Rect rect;
  final double radius;
  final Color color;
}

/// Carries the origin of a window from one place to the next one.
///
/// The caller creates it, passes it to the window that is about to close (for
/// example the profile menu, whose items [capture] their own rect when tapped)
/// and then hands [data] to the window that follows as its static origin.
class ContainerTransformHandoff {
  /// What the last [capture] measured, or null when nothing was captured.
  ContainerTransformOriginData? data;

  /// Measures the element behind [context] and stores it. Measured where the
  /// element is painted at this moment, so a window that is still travelling
  /// hands over the position the user actually touched.
  void capture(
    BuildContext context, {
    required double radius,
    required Color color,
  }) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    data = ContainerTransformOriginData(
      rect: box.localToGlobal(Offset.zero) & box.size,
      radius: radius,
      color: color,
    );
  }
}

/// Connects a trigger to the window it opens.
///
/// The route asks it to [measure] the trigger once when it opens and again when
/// it starts closing, and tells it when the window covers the trigger so the
/// trigger can step out of the way (it keeps its layout).
class ContainerTransformOriginController {
  final GlobalKey _key = GlobalKey(debugLabel: 'containerTransformOrigin');
  final ValueNotifier<bool> _isCovered = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _hasWindow = ValueNotifier<bool>(false);
  double _radius = OurnegoRadiusTokens.window;
  Color _color = Colors.transparent;
  bool _disposed = false;

  /// Whether the window currently covers the trigger.
  ValueListenable<bool> get isCovered => _isCovered;

  /// The trigger's current rect, radius and color, or null when it is not on
  /// screen any more (for example the screen behind was replaced).
  ContainerTransformOriginData? measure() {
    final box = _key.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return ContainerTransformOriginData(
      rect: box.localToGlobal(Offset.zero) & box.size,
      radius: _radius,
      color: _color,
    );
  }

  void setCovered(bool covered) {
    if (_disposed) return;
    _isCovered.value = covered;
  }

  /// Whether a window opened from this trigger exists, opening or closing.
  /// While it does, the trigger ignores touches: Flutter lets touches through
  /// the barrier once a route starts to pop, and a second tap would stack a
  /// second window.
  void setHasWindow(bool hasWindow) {
    if (_disposed) return;
    _hasWindow.value = hasWindow;
  }

  void _dispose() {
    _disposed = true;
    _isCovered.dispose();
    _hasWindow.dispose();
  }
}

/// Wraps the element that opens a window. [builder] gets the controller to pass
/// to `showOurnegoDialog` / `showOurnegoMenu`.
class ContainerTransformTrigger extends StatefulWidget {
  const ContainerTransformTrigger({
    super.key,
    required this.builder,
    this.radius = OurnegoRadiusTokens.window,
    this.color,
  });

  final Widget Function(
    BuildContext context,
    ContainerTransformOriginController origin,
  )
  builder;

  /// Corner radius of the trigger (22 for a 44 dp circle).
  final double radius;

  /// Fill of the trigger; defaults to the theme's surface.
  final Color? color;

  @override
  State<ContainerTransformTrigger> createState() =>
      _ContainerTransformTriggerState();
}

class _ContainerTransformTriggerState extends State<ContainerTransformTrigger> {
  final _origin = ContainerTransformOriginController();

  @override
  void dispose() {
    _origin._dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _origin._radius = widget.radius;
    _origin._color = widget.color ?? Theme.of(context).colorScheme.surface;

    return KeyedSubtree(
      key: _origin._key,
      child: ValueListenableBuilder<bool>(
        valueListenable: _origin._hasWindow,
        builder: (context, hasWindow, child) =>
            IgnorePointer(ignoring: hasWindow, child: child),
        child: ValueListenableBuilder<bool>(
          valueListenable: _origin._isCovered,
          // Opacity 0 paints nothing but keeps the trigger's size in the layout.
          builder: (context, covered, child) =>
              Opacity(opacity: covered ? 0 : 1, child: child),
          child: widget.builder(context, _origin),
        ),
      ),
    );
  }
}

/// The rectangle of the render object that [context] belongs to, in global
/// coordinates. Used to start a window from the element that was tapped.
Rect globalRectOf(BuildContext context) {
  final box = context.findRenderObject() as RenderBox;
  return box.localToGlobal(Offset.zero) & box.size;
}
