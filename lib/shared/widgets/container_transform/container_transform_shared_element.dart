import 'package:flutter/material.dart';

import 'package:ournego/core/motion/motion_window.dart';
import 'package:ournego/core/motion/ournego_motion_level.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';

/// An element that exists in the page that opened a container-transform page
/// and again in the new one (a mascot, an avatar): it flies from where it was
/// ([from], global coordinates) to its place in the new page, over the first
/// part of the transition, and the other way when the page closes.
///
/// The real [child] stays in the page, invisible until the flight is over. The
/// flying copy lives in the root overlay so the container's clip does not cut
/// it. Without a [from], outside a container-transform route, or in reduced
/// motion it is just [child].
class ContainerTransformSharedElement extends StatefulWidget {
  const ContainerTransformSharedElement({
    super.key,
    required this.from,
    required this.child,
    this.end = 0.7,
  });

  final Rect? from;
  final Widget child;

  /// The flight ends at this value of the window's clock `p`.
  final double end;

  @override
  State<ContainerTransformSharedElement> createState() =>
      _ContainerTransformSharedElementState();
}

class _ContainerTransformSharedElementState
    extends State<ContainerTransformSharedElement> {
  final _targetKey = GlobalKey();
  OverlayEntry? _entry;
  ContainerTransformController? _controller;

  bool get _flies {
    final controller = _controller;
    return controller != null &&
        widget.from != null &&
        controller.level != OurnegoMotionLevel.r;
  }

  bool get _inFlight => _flies && _controller!.animation.value < widget.end;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = ContainerTransformScope.maybeOf(context);
    if (identical(controller, _controller)) return;
    _controller?.animation.removeListener(_onTick);
    _controller = controller;
    controller?.animation.addListener(_onTick);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onTick());
  }

  void _onTick() {
    if (!mounted) return;
    if (_inFlight) {
      _entry ??= _insert();
    } else {
      _removeEntry();
    }
  }

  OverlayEntry? _insert() {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return null;
    final entry = OverlayEntry(builder: _buildFlying);
    overlay.insert(entry);
    return entry;
  }

  void _removeEntry() {
    _entry?.remove();
    _entry?.dispose();
    _entry = null;
  }

  Widget _buildFlying(BuildContext context) {
    final controller = _controller;
    final from = widget.from;
    if (controller == null || from == null) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: controller.animation,
      builder: (context, _) {
        final box = _targetKey.currentContext?.findRenderObject();
        if (box is! RenderBox || !box.attached || !box.hasSize) {
          return const SizedBox.shrink();
        }
        // The destination moves its content while it opens, so subtract that
        // to get the place the element will end up in.
        final to =
            (box.localToGlobal(Offset.zero) - controller.contentOffset) &
            box.size;
        final t = seg(
          controller.animation.value,
          0,
          widget.end,
          Curves.easeOutCubic,
        );
        final rect = Rect.lerp(from, to, t)!;
        return Positioned.fromRect(
          rect: rect,
          child: IgnorePointer(
            child: FittedBox(
              child: SizedBox.fromSize(size: box.size, child: widget.child),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller?.animation.removeListener(_onTick);
    _removeEntry();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null || !_flies) return widget.child;
    return AnimatedBuilder(
      animation: controller.animation,
      child: KeyedSubtree(key: _targetKey, child: widget.child),
      builder: (context, child) =>
          Opacity(opacity: _inFlight ? 0 : 1, child: child),
    );
  }
}
