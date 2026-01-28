import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/auth/presentation/pages/auth_selection_screen.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';

import '../../../business/presentation/providers/business_providers.dart';

class TopNavigationBarWidget extends ConsumerWidget {
  const TopNavigationBarWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(profileStreamProvider);
    final imageUrl = asyncUser.value?.profilePicture ?? '';

    final isLoggedAsync = ref.watch(isLoggedProvider);
    final logOutUsecase = ref.watch(logOutUsecaseProvider);
    // TODO: Improve this by using a more efficient method to check login status
    /*Timer.periodic(const Duration(seconds: 1), (_) {
      ref.invalidate(isLoggedProvider);
    });*/

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
            onPressed: () {
              isLoggedAsync.when(
                data: (isLogged) {
                  if (isLogged) {
                    showDialog(
                      context: context,
                      builder: (context) {
                        return AlertDialog(
                          title: Text('Cerrar sesión'),
                          content: Text(
                            '¿Estás seguro de que quieres cerrar sesión?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancelar'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await logOutUsecase();
                                Navigator.of(context).pop();
                              },
                              child: Text('Cerrar sesión'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthSelectionScreen(),
                        settings: RouteSettings(name: '/authSelection'),
                      ),
                    );
                  }
                },
                error: (error, stackTrace) {},
                loading: () {},
              );
            },
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
                      isLoggedAsync.when(
                        data: (isLogged) => isLogged
                            ? Icons.account_circle
                            : Icons.login_rounded,
                        error: (error, stackTrace) => Icons.account_circle,
                        loading: () => Icons.account_circle,
                      ),
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
