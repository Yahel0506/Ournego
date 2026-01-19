import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';

class TopNavigationBarWidget extends ConsumerWidget {
  const TopNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(profileStreamProvider);
    final imageUrl = asyncUser.value?.profilePicture ?? '';

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
            child: SizedBox(
              height: 44,
              width: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_circle_rounded,
                      size: 44,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
