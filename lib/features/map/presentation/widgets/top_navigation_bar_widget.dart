import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TopNavigationBarWidget extends ConsumerWidget {
  const TopNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
      child: Row(
        children: [
          // -------------------- Voice Search Button --------------------
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              minimumSize: Size(60, 60),
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              Icons.mic,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Spacer(),
          // -------------------- Search Bar --------------------
          SearchBar(
            elevation: WidgetStatePropertyAll(1),
            leading: Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            hintText: 'Buscar negocio...',
            constraints: BoxConstraints(
              maxWidth: (MediaQuery.of(context).size.width - 162),
              minHeight: 60,
            ),
          ),
          Spacer(),
          // -------------------- User Profile Button --------------------
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              minimumSize: Size(60, 60),
              padding: EdgeInsets.zero,
            ),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x7E6A6A6A),
              ),
              child: Icon(
                Icons.person,
                size: 28,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
