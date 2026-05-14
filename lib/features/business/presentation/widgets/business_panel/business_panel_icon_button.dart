import 'package:flutter/material.dart';

class BusinessPanelIconButton extends StatelessWidget {
  const BusinessPanelIconButton({
    super.key,
    required this.onTap,
    required this.child,
    this.small = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final size = small ? 28.0 : 44.0;
    return Material(
      color: colorScheme.surface,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(child: child),
        ),
      ),
    );
  }
}
