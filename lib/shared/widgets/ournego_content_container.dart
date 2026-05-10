import 'dart:ui';

import 'package:flutter/material.dart';

class OurnegoContentContainer extends StatelessWidget {
  const OurnegoContentContainer({
    super.key,
    required this.child,
    this.margin,
    this.borderRadius = 30,
    this.hasBlur = false,
    this.customHorizontalPadding,
    this.customVerticalPadding,
    this.backgroundColor,
    this.borderColor,
    this.blurSigma = 10,
  });

  final Widget child;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final bool hasBlur;
  final double? customHorizontalPadding;
  final double? customVerticalPadding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final horizontalPadding = width < 360
            ? 14.0
            : (width < 420 ? 18.0 : 28.0);
        final verticalPadding = width < 360
            ? 20.0
            : (width < 420 ? 18.0 : 24.0);

        final contentContainer = Container(
          margin: margin,
          decoration: BoxDecoration(
            color:
                backgroundColor ?? colorScheme.surface.withValues(alpha: 0.5),
            border: Border.all(
              color: borderColor ?? colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: customHorizontalPadding ?? horizontalPadding,
              vertical: customVerticalPadding ?? verticalPadding,
            ),
            child: child,
          ),
        );

        if (!hasBlur) {
          return contentContainer;
        } else {
          return ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
              child: contentContainer,
            ),
          );
        }
      },
    );
  }
}
