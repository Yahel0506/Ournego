import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';

class AppNavigationBar extends ConsumerStatefulWidget {
  const AppNavigationBar({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _AppNavigationBarState();
}

class _AppNavigationBarState extends ConsumerState<AppNavigationBar> {
  @override
  Widget build(BuildContext context) {
    final datasource = ref.watch(appNavigationBarProvider);
    final controller = ref.watch(pageControllerProvider);
    final index = ref.watch(navigationIndexProvider);

    const buttonAnimationDuration = Duration(milliseconds: 250);

    return Container(
      height: 96,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withOpacity(0.1),
            blurRadius: 10,
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Center(
        child: Row(
          children: [
            Spacer(),
            // ------------------ Home Button ------------------
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).setIndex(0);
                controller.jumpToPage(0);
              },
              icon: AnimatedContainer(
                duration: buttonAnimationDuration,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: index == 0
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  datasource.getNavigationBarItemsIcons()[0],
                  size: 44,
                  color: index == 0
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Spacer(),
            // ------------------ Map Button ------------------
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).setIndex(1);
                controller.jumpToPage(1);
              },
              icon: AnimatedContainer(
                duration: buttonAnimationDuration,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: index == 1
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  datasource.getNavigationBarItemsIcons()[1],
                  size: 44,
                  color: index == 1
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Spacer(),
            // ------------------ MyBussines Button ------------------
            IconButton(
              padding: EdgeInsets.zero,
              onPressed: () {
                ref.read(navigationIndexProvider.notifier).setIndex(2);
                controller.jumpToPage(2);
              },
              icon: AnimatedContainer(
                duration: buttonAnimationDuration,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: index == 2
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  datasource.getNavigationBarItemsIcons()[2],
                  size: 44,
                  color: index == 2
                      ? Theme.of(context).colorScheme.surface
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            Spacer(),
          ],
        ),
      ),
    );
  }
}
