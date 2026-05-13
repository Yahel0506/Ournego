import 'package:flutter/material.dart';

class OnboardingResponsiveLayout extends StatelessWidget {
  const OnboardingResponsiveLayout({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(28),
    this.scrollBelowHeight = 680,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double scrollBelowHeight;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final content = Padding(padding: padding, child: child);

          if (constraints.maxHeight >= scrollBelowHeight) {
            return content;
          }

          return SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(child: content),
            ),
          );
        },
      ),
    );
  }
}
