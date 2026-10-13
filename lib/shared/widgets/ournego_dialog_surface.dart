import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

/// The surface of every dialog and menu: flat glass, like the navigation bar
/// and the floating sheet. A flat, opaque face and a visible 1 px contour; no
/// blur and no shadow, because the window sits on its own scrim.
///
/// It is also the destination of the container transform: it marks itself as
/// the surface that grows out of the trigger, and blurs only its content while
/// it travels, so the face and the contour stay crisp.
class OurnegoDialogSurface extends StatelessWidget {
  const OurnegoDialogSurface({
    super.key,
    required this.child,
    this.customHorizontalPadding,
    this.customVerticalPadding,
  });

  final Widget child;

  /// Override the width-dependent padding of [OurnegoContentContainer].
  final double? customHorizontalPadding;
  final double? customVerticalPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final face = OurnegoGlassPalette.navFace(scheme);

    return ContainerTransformDestination(
      radius: OurnegoRadiusTokens.window,
      fillColor: face,
      child: OurnegoContentContainer(
        hasBlur: false,
        borderRadius: OurnegoRadiusTokens.window,
        backgroundColor: face,
        borderColor: OurnegoGlassPalette.border(scheme),
        customHorizontalPadding: customHorizontalPadding,
        customVerticalPadding: customVerticalPadding,
        child: ContainerTransformBlur(child: child),
      ),
    );
  }
}
