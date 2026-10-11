import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';
import 'package:ournego/features/map/presentation/widgets/profile_menu_dialog_widget.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
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
          _CrystalItemContainer(
            borderRadius: OurnegoRadiusTokens.container,
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
          const SizedBox(width: OurnegoSpacingTokens.controlGap),
          Expanded(
            child: _CrystalItemContainer(
              borderRadius: OurnegoRadiusTokens.container,
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
          const SizedBox(width: OurnegoSpacingTokens.controlGap),
          _CrystalItemContainer(
            borderRadius: OurnegoRadiusTokens.container,
            child: ElevatedButton(
              key: const ValueKey('mapProfileButton'),
              onPressed: () => _openProfileMenu(context, ref),
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
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.6,
                              ),
                            );
                          },
                        ),
                      )
                    : Icon(
                        isLogged ? Icons.account_circle : Icons.login_rounded,
                        size: 40,
                        color: colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
              ),
            ),
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
        filter: ImageFilter.blur(sigmaY: 6, sigmaX: 6),
        child: Container(
          decoration: BoxDecoration(
            color: OurnegoSemanticTokens.surfaceRaised(colorScheme),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              width: 1,
              color: OurnegoSemanticTokens.borderSubtle(colorScheme),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
