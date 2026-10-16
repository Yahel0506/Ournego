import 'package:flutter/material.dart';

import 'package:ournego/core/motion/ournego_motion_level.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_route.dart';

/// What a page needs to grow out of the element that opened it. Pass it as
/// `extra` when navigating; a route that finds it builds a
/// [ContainerTransformPage], and any other navigation gets a standard page.
@immutable
class ContainerTransformRouteExtra {
  const ContainerTransformRouteExtra(this.origin);

  final ContainerTransformOriginData origin;

  /// Measures the element behind [context] right now, so the page grows out of
  /// it. Call it from the tap handler, not from `build`.
  factory ContainerTransformRouteExtra.measure(
    BuildContext context, {
    required double radius,
    required Color color,
  }) => ContainerTransformRouteExtra(
    ContainerTransformOriginData(
      rect: globalRectOf(context),
      radius: radius,
      color: color,
    ),
  );

  /// The extra for an origin that was measured elsewhere (a menu item, a
  /// trigger), or null when there is none.
  static ContainerTransformRouteExtra? from(
    ContainerTransformOriginData? data,
  ) => data == null ? null : ContainerTransformRouteExtra(data);
}

/// A go_router page that grows out of [origin] and fills the screen, with the
/// same spring as the windows. It goes back to the same place when it is
/// popped. It has no scrim: the page is the whole screen.
class ContainerTransformPage<T> extends Page<T> {
  const ContainerTransformPage({
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
    required this.child,
    required this.origin,
  });

  final Widget child;
  final ContainerTransformOriginData origin;

  @override
  Route<T> createRoute(BuildContext context) {
    return ContainerTransformRoute<T>(
      builder: (context) => ContainerTransformDestination(
        radius: 0,
        fillColor: Theme.of(context).scaffoldBackgroundColor,
        child: child,
      ),
      capturedThemes: InheritedTheme.capture(from: context, to: context),
      motionLevel: OurnegoMotion.resolveLevel(context),
      preset: kFullBleedSpring,
      scrimAlpha: 0,
      staticOrigin: origin,
      useSafeArea: false,
      dismissible: false,
      settings: this,
    );
  }
}
