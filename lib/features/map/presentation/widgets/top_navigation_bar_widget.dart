import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';
import 'package:ournego/features/map/presentation/widgets/profile_menu_dialog_widget.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      key: topNavigationBarKey,
      padding: const EdgeInsets.fromLTRB(
        OurnegoSpacingTokens.md,
        40,
        OurnegoSpacingTokens.md,
        0,
      ),
      child: Row(
        children: [
          OurnegoGlassIconButton(
            icon: Icons.mic_none_rounded,
            activeIcon: Icons.mic_rounded,
            active: isVoiceListening,
            showHalo: true,
            semanticLabel: isVoiceListening
                ? 'Detener búsqueda por voz'
                : 'Buscar por voz',
            onPressed: onVoiceSearchTap,
          ),
          const SizedBox(width: OurnegoSpacingTokens.controlGap),
          Expanded(
            child: OurnegoGlassSurface(
              child: SearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                onChanged: onSearchChanged,
                onTap: onSearchTap,
                elevation: const WidgetStatePropertyAll(0),
                backgroundColor: const WidgetStatePropertyAll(
                  Colors.transparent,
                ),
                leading: const Padding(
                  padding: EdgeInsets.only(left: 8),
                  child: OurnegoGlassSurfaceIcon(Icons.search_rounded),
                ),
                hintText: 'Buscar negocio...',
                constraints: const BoxConstraints(minHeight: 52),
              ),
            ),
          ),
          const SizedBox(width: OurnegoSpacingTokens.controlGap),
          OurnegoGlassIconButton(
            key: const ValueKey('mapProfileButton'),
            icon: isLogged ? Icons.account_circle_rounded : Icons.login_rounded,
            semanticLabel: 'Abrir menú de perfil',
            onPressed: () => _openProfileMenu(context, ref),
            child: imageUrl.isNotEmpty
                ? Image(
                    image: NetworkImage(imageUrl),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        isLogged
                            ? Icons.account_circle_rounded
                            : Icons.login_rounded,
                        size: 40,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      );
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

Future<void> _openProfileMenu(BuildContext context, WidgetRef ref) async {
  final action = await showProfileMenuDialog(context);
  if (action == null || !context.mounted) return;

  switch (action) {
    case ProfileMenuAction.logIn:
      context.push(AuthRoutes.authSelection);
    case ProfileMenuAction.businessPanel:
      context.go(BusinessRoutes.panel);
    case ProfileMenuAction.locationPermissions:
      await Geolocator.openAppSettings();
    case ProfileMenuAction.reportProblem:
      await _openFeedbackDialog(context, ref);
    case ProfileMenuAction.debugPanel:
      context.go(DebuggingRoutes.debugPanel);
    case ProfileMenuAction.logOut:
      await _confirmLogOut(context, ref);
  }
}

Future<void> _openFeedbackDialog(BuildContext context, WidgetRef ref) async {
  if (ref.read(isFeedbackDialogOpenProvider)) return;
  ref.read(isFeedbackDialogOpenProvider.notifier).setIsOpen();
  await showDialog<void>(
    context: context,
    builder: (_) => const FeedbackDialogWidget(),
  );
  ref.read(isFeedbackDialogOpenProvider.notifier).setIsClosed();
}

Future<void> _confirmLogOut(BuildContext context, WidgetRef ref) {
  final logOutUsecase = ref.read(logOutUsecaseProvider);

  return showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return OurnegoAlertDialog(
        title: 'Cerrar sesión',
        content: '¿Estás seguro de que quieres cerrar sesión?',
        primaryAction: OurnegoDialogAction(
          key: const ValueKey('confirmLogoutButton'),
          label: 'Cerrar sesión',
          isDestructive: true,
          onPressed: () async {
            await logOutUsecase();
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
              dialogContext.go(MapRoutes.map);
            }
          },
        ),
        secondaryAction: OurnegoDialogAction(
          label: 'Cancelar',
          onPressed: () {
            Navigator.of(dialogContext).pop();
          },
        ),
      );
    },
  );
}
