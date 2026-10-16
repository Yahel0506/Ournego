import 'package:flutter/material.dart';

import 'package:ournego/core/ournego_motion.dart';

/// The strip under the search bar: the register card, the location banner and
/// the zone chip. They share one container, so when one of them comes or goes
/// the others slide to their new place and it fades, instead of popping in.
class MapTopStrip extends StatelessWidget {
  const MapTopStrip({
    super.key,
    required this.showRegister,
    required this.register,
    required this.showBanner,
    required this.showChip,
    this.banner,
    this.chip,
  });

  final bool showRegister;
  final Widget register;
  final bool showBanner;
  final Widget? banner;
  final bool showChip;
  final Widget? chip;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _StripItem(visible: showRegister, child: register),
        _StripItem(visible: showBanner, child: banner),
        _StripItem(
          fill: false,
          visible: showChip,
          // The gap to the banner belongs to the chip, so it goes with it.
          child: chip == null
              ? null
              : Padding(
                  padding: EdgeInsets.only(top: showBanner ? 8 : 0),
                  child: chip,
                ),
        ),
      ],
    );
  }
}

/// Fades its child in and out while the space it takes grows and shrinks.
class _StripItem extends StatelessWidget {
  const _StripItem({
    required this.visible,
    required this.child,
    this.fill = true,
  });

  /// Whether the child takes the full width, or only the one it needs.
  final bool fill;
  final bool visible;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final shown = visible && child != null;
    return AnimatedSize(
      duration: kStandardDuration,
      curve: kEaseOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: kStandardDuration,
        switchInCurve: kEaseOutCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        child: shown
            ? (fill
                  ? SizedBox(
                      key: const ValueKey('shown'),
                      width: double.infinity,
                      child: child,
                    )
                  : Align(
                      key: const ValueKey('shown'),
                      alignment: Alignment.topLeft,
                      child: child,
                    ))
            : const SizedBox(key: ValueKey('hidden'), width: double.infinity),
      ),
    );
  }
}
