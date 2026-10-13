import 'package:flutter/material.dart';

import 'package:ournego/core/motion/ournego_motion_level.dart';
import 'package:ournego/core/ournego_motion.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_route.dart';

/// Opens a dialog that grows out of [origin] (or, without one, out of the
/// center of the screen), and returns what it was popped with, like
/// `showDialog` does.
///
/// This is the only way to open a dialog in the app: every window shares the
/// same spring, scrim and closing behavior.
Future<T?> showOurnegoDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  ContainerTransformOriginController? origin,
  OurnegoSpringPreset preset = kDialogSpring,
  double scrimAlpha = kDialogScrimAlpha,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final navigator = Navigator.of(context, rootNavigator: useRootNavigator);
  return navigator.push<T>(
    ContainerTransformRoute<T>(
      builder: builder,
      capturedThemes: InheritedTheme.capture(
        from: context,
        to: navigator.context,
      ),
      motionLevel: OurnegoMotion.resolveLevel(
        context,
        wantsBlur: preset.maxItemBlur > 0,
      ),
      preset: preset,
      scrimAlpha: scrimAlpha,
      origin: origin,
      dismissible: barrierDismissible,
      label: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      settings: routeSettings,
    ),
  );
}

/// A menu: a dialog with a lighter scrim, meant to be opened from [origin].
Future<T?> showOurnegoMenu<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  ContainerTransformOriginController? origin,
  bool useRootNavigator = true,
}) {
  return showOurnegoDialog<T>(
    context: context,
    builder: builder,
    origin: origin,
    scrimAlpha: kDialogSpring.scrimAlpha,
    useRootNavigator: useRootNavigator,
  );
}
