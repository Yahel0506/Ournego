import 'package:flutter/material.dart';

import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

/// The surface of every small anchored popover (chip options, notices): the
/// flat glass of the dialogs with the small radius of decision D26
/// (`OurnegoRadiusTokens.lg`, 14) and no blur: popovers are level C by design.
///
/// It is the destination of the container transform, so it grows out of the
/// element that opened it.
class OurnegoPopoverSurface extends StatelessWidget {
  const OurnegoPopoverSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 6, horizontal: 6),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final face = OurnegoGlassPalette.navFace(scheme);

    return ContainerTransformDestination(
      radius: OurnegoRadiusTokens.lg,
      fillColor: face,
      child: OurnegoContentContainer(
        hasBlur: false,
        borderRadius: OurnegoRadiusTokens.lg,
        backgroundColor: face,
        borderColor: OurnegoGlassPalette.border(scheme),
        customHorizontalPadding: padding.horizontal / 2,
        customVerticalPadding: padding.vertical / 2,
        child: child,
      ),
    );
  }
}
