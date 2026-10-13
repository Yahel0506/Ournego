import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

final GlobalKey appNavigationBarKey = GlobalKey(debugLabel: 'appNavigationBar');

/// Bottom navigation of the app. The visuals live in [OurnegoNavBar]; this
/// widget only feeds it the items and keeps the outer layout.
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
    final icons = datasource.getNavigationBarItemsIcons();
    final labels = datasource.getNavigationBarItemsLabels();
    final isWideScreen = MediaQuery.of(context).size.width > 600;

    const EdgeInsets margin = EdgeInsets.fromLTRB(48, 0, 48, 4);

    return BottomAppBar(
      key: appNavigationBarKey,
      color: Colors.transparent,
      padding: EdgeInsets.zero,
      elevation: 0,
      height: OurnegoSpacingTokens.navHeight,
      child: Padding(
        padding: margin,
        child: Center(
          child: SizedBox(
            width: isWideScreen ? 400 : double.infinity,
            child: OurnegoNavBar(
              items: [
                for (var i = 0; i < icons.length; i++)
                  OurnegoNavBarItem(icon: icons[i], label: labels[i]),
              ],
              currentIndex: currentIndex,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}
