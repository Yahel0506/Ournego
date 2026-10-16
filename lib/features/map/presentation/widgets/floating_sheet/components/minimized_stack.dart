import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/minimized_stack_icon.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

/// The icons of the minimized businesses, oldest first, growing downwards.
///
/// Every icon sits in its own slot. A new icon takes the slot under the stack
/// without moving the others; when the stack is full, the oldest one rises one
/// slot while it fades out and the rest move up one place.
class MinimizedStack extends StatefulWidget {
  const MinimizedStack({
    super.key,
    required this.businesses,
    required this.left,
    required this.top,
    required this.onTap,
    required this.onLongPress,
    this.hiddenId,
    this.restoringId,
  });

  /// Slot size: 48 dp icon plus 8 dp gap.
  static const double slotHeight = 56;
  static const double iconSize = 48;

  final List<SheetBusinessData> businesses;
  final double left;
  final double top;

  /// A business that is still travelling from the sheet to its slot. It holds
  /// its slot but is not drawn until the sheet arrives, so there is never a
  /// second copy, and it appears at once (no fade) when it is revealed.
  final String? hiddenId;

  /// A business whose icon is becoming the sheet: it leaves the stack at once.
  final String? restoringId;

  final void Function(SheetBusinessData business, int index) onTap;
  final ValueChanged<SheetBusinessData> onLongPress;

  /// Top-left of slot [index] relative to this widget's parent.
  static Offset slotOffset(double left, double top, int index) =>
      Offset(left, top + index * slotHeight);

  @override
  State<MinimizedStack> createState() => _MinimizedStackState();
}

class _Item {
  _Item(this.business, {required this.animateIn});

  SheetBusinessData business;
  final bool animateIn;

  /// Set when the item is leaving: the slot it rises to while it fades.
  int? ghostSlot;

  bool get isGhost => ghostSlot != null;
}

class _MinimizedStackState extends State<MinimizedStack> {
  late List<_Item> _items = [
    for (final business in widget.businesses) _Item(business, animateIn: false),
  ];

  @override
  void didUpdateWidget(covariant MinimizedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incoming = widget.businesses;
    final incomingIds = {for (final b in incoming) b.id};
    final previous = {for (final item in _items) item.business.id: item};

    final next = <_Item>[];
    // The oldest icon of a full stack rises while it fades.
    for (var index = 0; index < _items.length; index++) {
      final item = _items[index];
      final id = item.business.id;
      if (incomingIds.contains(id)) {
        continue;
      }
      if (item.isGhost) {
        next.add(item);
      } else if (index == 0 && id != widget.restoringId) {
        item.ghostSlot = -1;
        next.add(item);
      }
    }
    for (final business in incoming) {
      final existing = previous[business.id];
      if (existing != null && !existing.isGhost) {
        existing.business = business;
        next.add(existing);
      } else {
        next.add(_Item(business, animateIn: business.id != widget.hiddenId));
      }
    }
    _items = next;
  }

  void _removeGhost(_Item item) {
    if (!mounted || !item.isGhost) {
      return;
    }
    setState(() => _items.remove(item));
  }

  @override
  Widget build(BuildContext context) {
    final live = [
      for (final item in _items)
        if (!item.isGhost) item,
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (final item in _items)
          _Slot(
            key: ValueKey(item.business.id),
            item: item,
            offset: MinimizedStack.slotOffset(
              widget.left,
              widget.top,
              item.isGhost ? item.ghostSlot! : live.indexOf(item),
            ),
            hidden: item.business.id == widget.hiddenId,
            onTap: () => widget.onTap(item.business, live.indexOf(item)),
            onLongPress: () => widget.onLongPress(item.business),
            onGone: () => _removeGhost(item),
          ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({
    super.key,
    required this.item,
    required this.offset,
    required this.hidden,
    required this.onTap,
    required this.onLongPress,
    required this.onGone,
  });

  final _Item item;
  final Offset offset;
  final bool hidden;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onGone;

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: kStandardDuration,
      curve: kEaseOutCubic,
      left: offset.dx,
      top: offset.dy,
      width: MinimizedStack.iconSize,
      height: MinimizedStack.iconSize,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: item.animateIn ? 0 : 1,
          end: item.isGhost ? 0 : 1,
        ),
        duration: kStandardDuration,
        curve: kEaseOutCubic,
        onEnd: item.isGhost ? onGone : null,
        builder: (context, value, child) => Opacity(
          opacity: hidden ? 0 : value,
          child: Transform.scale(scale: 0.8 + 0.2 * value, child: child),
        ),
        child: IgnorePointer(
          ignoring: hidden || item.isGhost,
          child: MinimizedStackIcon(
            business: item.business,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
      ),
    );
  }
}
