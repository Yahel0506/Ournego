import 'package:flutter/material.dart';

import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';

/// Places the content of a popover next to the element it grows out of.
///
/// It sits right below the anchor, aligned with the anchor's start edge (the
/// left one in left-to-right text, the right one in right-to-left), flips above
/// the anchor when it does not fit below, and never leaves the screen. Without
/// an anchor (outside a container-transform route, or when the trigger is gone)
/// it centers the content.
///
/// The anchor is read once, when the popover opens, so the content stays put
/// while the window closes back into the (possibly moved) anchor.
///
/// Coordinates are those of the screen: open the popover on the root navigator
/// without a safe-area inset (`showOurnegoPopover` does).
class ContainerTransformAnchoredPosition extends StatefulWidget {
  const ContainerTransformAnchoredPosition({
    super.key,
    required this.child,
    this.gap = 4,
    this.screenMargin = 8,
  });

  final Widget child;

  /// Space between the anchor and the popover.
  final double gap;

  /// Minimum distance to the screen edges and the system insets.
  final double screenMargin;

  @override
  State<ContainerTransformAnchoredPosition> createState() =>
      _ContainerTransformAnchoredPositionState();
}

class _ContainerTransformAnchoredPositionState
    extends State<ContainerTransformAnchoredPosition> {
  Rect? _anchor;
  bool _read = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_read) return;
    _read = true;
    _anchor = ContainerTransformScope.maybeOf(context)?.origin?.rect;
  }

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.paddingOf(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return CustomSingleChildLayout(
      delegate: _AnchoredPositionDelegate(
        anchor: _anchor,
        textDirection: Directionality.of(context),
        insets: EdgeInsets.fromLTRB(
          padding.left,
          padding.top,
          padding.right,
          viewInsets.bottom > padding.bottom
              ? viewInsets.bottom
              : padding.bottom,
        ),
        gap: widget.gap,
        margin: widget.screenMargin,
      ),
      child: widget.child,
    );
  }
}

class _AnchoredPositionDelegate extends SingleChildLayoutDelegate {
  _AnchoredPositionDelegate({
    required this.anchor,
    required this.textDirection,
    required this.insets,
    required this.gap,
    required this.margin,
  });

  final Rect? anchor;
  final TextDirection textDirection;
  final EdgeInsets insets;
  final double gap;
  final double margin;

  Rect _usable(Size size) => Rect.fromLTRB(
    insets.left + margin,
    insets.top + margin,
    size.width - insets.right - margin,
    size.height - insets.bottom - margin,
  );

  double _roomBelow(Size size) => _usable(size).bottom - (anchor!.bottom + gap);

  double _roomAbove(Size size) => anchor!.top - gap - _usable(size).top;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final usable = _usable(constraints.biggest);
    final a = anchor;
    if (a == null) return BoxConstraints.loose(usable.size);
    final room =
        _roomBelow(constraints.biggest) > _roomAbove(constraints.biggest)
        ? _roomBelow(constraints.biggest)
        : _roomAbove(constraints.biggest);
    final maxWidth = usable.width;
    return BoxConstraints(
      minWidth: a.width < maxWidth ? a.width : maxWidth,
      maxWidth: maxWidth,
      maxHeight: room < 0 ? 0 : room,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final usable = _usable(size);
    final a = anchor;
    if (a == null) {
      return Offset(
        usable.left + (usable.width - childSize.width) / 2,
        usable.top + (usable.height - childSize.height) / 2,
      );
    }

    final below = _roomBelow(size);
    final above = _roomAbove(size);
    final fitsBelow = childSize.height <= below;
    final fitsAbove = childSize.height <= above;
    final placeBelow = fitsBelow || (!fitsAbove && below >= above);
    final y = placeBelow ? a.bottom + gap : a.top - gap - childSize.height;

    final x = textDirection == TextDirection.rtl
        ? a.right - childSize.width
        : a.left;

    double clamp(double v, double lo, double hi) =>
        hi < lo ? lo : v.clamp(lo, hi);
    return Offset(
      clamp(x, usable.left, usable.right - childSize.width),
      clamp(y, usable.top, usable.bottom - childSize.height),
    );
  }

  @override
  bool shouldRelayout(_AnchoredPositionDelegate old) =>
      old.anchor != anchor ||
      old.textDirection != textDirection ||
      old.insets != insets ||
      old.gap != gap ||
      old.margin != margin;
}
