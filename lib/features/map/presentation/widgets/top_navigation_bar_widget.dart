import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_buttons.dart';

final GlobalKey topNavigationBarKey = GlobalKey(debugLabel: 'topNavigationBar');

class TopNavigationBarWidget extends ConsumerWidget {
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchTap;
  final VoidCallback? onVoiceSearchTap;
  final bool isVoiceListening;

  const TopNavigationBarWidget({
    super.key,
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.onSearchTap,
    this.onVoiceSearchTap,
    this.isVoiceListening = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogged = ref.watch(authSessionStatusProvider);
    final asyncUser = isLogged ? ref.watch(profileStreamProvider) : null;
    final imageUrl = asyncUser?.value?.profilePicture ?? '';
    final logOutUsecase = ref.watch(logOutUsecaseProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      key: topNavigationBarKey,
      padding: const EdgeInsets.fromLTRB(16, 40, 16, 0),
      child: Row(
        children: [
          _CrystalItemContainer(
            borderRadius: 30,
            child: ElevatedButton(
              onPressed: onVoiceSearchTap,
              style: OurnegoButtonStyles.circularSurface(context: context),
              child: Icon(
                isVoiceListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                size: 26,
                color: isVoiceListening
                    ? colorScheme.primary
                    : colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _CrystalItemContainer(
              borderRadius: 30,
              child: SearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
                onTap: onSearchTap,
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: WidgetStatePropertyAll(
                  colorScheme.surface.withValues(alpha: 0.35),
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Icon(Icons.search, color: colorScheme.onSurface),
                ),
                hintText: 'Buscar negocio...',
                constraints: const BoxConstraints(minHeight: 52),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CrystalItemContainer(
            borderRadius: 30,
            child: ElevatedButton(
              key: const ValueKey('mapProfileButton'),
              onPressed: () async {
                if (!context.mounted) return;

                if (isLogged) {
                  showDialog<void>(
                    context: context,
                    builder: (dialogContext) {
                      return OurnegoAlertDialog(
                        title: 'Cerrar sesión',
                        content: '¿Estás seguro de que quieres cerrar sesión?',
                        actionLabel: 'Cancelar',
                        onAction: () {
                          Navigator.of(dialogContext).pop();
                        },
                        trailingActions: [
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
              style: OurnegoButtonStyles.circularSurface(context: context),
              child: SizedBox(
                height: 40,
                width: 40,
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
                              size: 40,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : Icon(
                        isLogged ? Icons.account_circle : Icons.login_rounded,
                        size: 40,
                        color: Colors.grey,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CrystalItemContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;

  const _CrystalItemContainer({
    required this.child,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaY: 0, sigmaX: 0),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 1),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              width: 1,
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
