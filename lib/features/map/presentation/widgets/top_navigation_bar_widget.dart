import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';

class TopNavigationBarWidget extends ConsumerWidget {
  const TopNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogged = ref.watch(authSessionStatusProvider);
    final asyncUser = isLogged ? ref.watch(profileStreamProvider) : null;
    final imageUrl = asyncUser?.value?.profilePicture ?? '';
    final logOutUsecase = ref.watch(logOutUsecaseProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40.0),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              minimumSize: const Size(60, 60),
              padding: EdgeInsets.zero,
            ),
            child: Icon(
              Icons.mic,
              size: 28,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const Spacer(),
          SearchBar(
            elevation: const WidgetStatePropertyAll(1),
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
          const Spacer(),
          ElevatedButton(
            key: const ValueKey('mapProfileButton'),
            onPressed: () async {
              if (!context.mounted) return;

              if (isLogged) {
                showDialog<void>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text(
                        '¿Estás seguro de que quieres cerrar sesión?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                          },
                          child: const Text('Cancelar'),
                        ),
                        TextButton(
                          key: const ValueKey('confirmLogoutButton'),
                          onPressed: () async {
                            await logOutUsecase();
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                              dialogContext.go(MapRoutes.map);
                            }
                          },
                          child: const Text('Cerrar sesión'),
                        ),
                      ],
                    );
                  },
                );
              } else {
                context.push(AuthRoutes.authSelection);
              }
            },
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              minimumSize: const Size(60, 60),
              padding: EdgeInsets.zero,
            ),
            child: SizedBox(
              height: 44,
              width: 44,
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: Image(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            isLogged
                                ? Icons.account_circle
                                : Icons.login_rounded,
                            size: 44,
                            color: Colors.grey,
                          );
                        },
                      ),
                    )
                  : Icon(
                      isLogged ? Icons.account_circle : Icons.login_rounded,
                      size: 44,
                      color: Colors.grey,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
