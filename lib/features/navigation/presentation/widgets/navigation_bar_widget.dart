import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';

class AppNavigationBar extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datasource = ref.watch(appNavigationBarProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final icons = datasource.getNavigationBarItemsIcons();

    const double height = 72;
    const double borderRadius = 100;
    const EdgeInsets marginR = EdgeInsets.fromLTRB(48, 0, 48, 4);
    const EdgeInsets paddingR = EdgeInsets.fromLTRB(8, 8, 8, 10);

    return BottomAppBar(
      color: Colors.transparent,
      padding: EdgeInsets.zero,
      elevation: 0,
      height: height,
      child: Padding(
        padding: marginR,
        child: Container(
          decoration: BoxDecoration(
            boxShadow: const [
              BoxShadow(
                color: Color(0x26000000),
                blurRadius: 22,
                spreadRadius: 1,
              ),
            ],
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaY: 0, sigmaX: 0),
              child: Container(
                padding: paddingR,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    width: 1,
                    color: colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  color: colorScheme.surface.withValues(alpha: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      _CrystalNavItem(
                        icon: icons[0],
                        isSelected: currentIndex == 0,
                        selectedColor: colorScheme.primary,
                        selectedIconColor: colorScheme.surface,
                        unselectedIconColor: colorScheme.onSurface,
                        onTap: () => onTap(0),
                      ),
                      _CrystalNavItem(
                        icon: icons[1],
                        isSelected: currentIndex == 1,
                        selectedColor: colorScheme.primary,
                        selectedIconColor: colorScheme.surface,
                        unselectedIconColor: colorScheme.onSurface,
                        onTap: () => onTap(1),
                      ),
                      _CrystalNavItem(
                        icon: icons[2],
                        isSelected: currentIndex == 2,
                        selectedColor: colorScheme.primary,
                        selectedIconColor: colorScheme.surface,
                        unselectedIconColor: colorScheme.onSurface,
                        onTap: () => onTap(2),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CrystalNavItem extends StatelessWidget {
  final IconData icon;
  final bool isSelected;
  final Color selectedColor;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final VoidCallback onTap;

  const _CrystalNavItem({
    required this.icon,
    required this.isSelected,
    required this.selectedColor,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        type: MaterialType.transparency,
        child: InkResponse(
          radius: 36,
          splashColor: selectedColor.withValues(alpha: 0),
          highlightShape: BoxShape.circle,
          onTap: onTap,
          child: Center(
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: isSelected ? 1 : 0),
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                final iconScale = 1 + (0.12 * value);

                return Transform.scale(
                  scale: iconScale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: Color.lerp(
                        Colors.transparent,
                        selectedColor,
                        value,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      size: 40 + (4 * value),
                      color: Color.lerp(
                        unselectedIconColor,
                        selectedIconColor,
                        value,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
