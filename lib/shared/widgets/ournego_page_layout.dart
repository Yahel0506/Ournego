import 'package:flutter/material.dart';

import 'package:ournego/shared/widgets/animated_background.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';

class OurnegoPageLayout extends StatelessWidget {
  final Widget child;
  final Key? scaffoldKey;
  final bool resizeToAvoidBottomInset;
  final double maxWidth;
  final EdgeInsetsGeometry contentPadding;

  const OurnegoPageLayout({
    super.key,
    required this.child,
    this.scaffoldKey,
    this.resizeToAvoidBottomInset = false,
    this.maxWidth = 500,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: OurnegoSpacingTokens.pagePadding,
      vertical: OurnegoSpacingTokens.pageTopOffset,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: Stack(
        children: [
          const AnimatedBackground(),
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Padding(padding: contentPadding, child: child),
            ),
          ),
        ],
      ),
    );
  }
}
