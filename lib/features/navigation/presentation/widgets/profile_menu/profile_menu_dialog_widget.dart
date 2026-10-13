import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_dialog_surface.dart';

/// Entries of the profile menu opened from the map's profile button.
///
/// The dialog only reports which entry was chosen (via `Navigator.pop`);
/// the caller performs the action with its own, still-mounted context.
enum ProfileMenuAction {
  logIn,
  businessPanel,
  locationPermissions,
  reportProblem,
  debugPanel,
  logOut,
}

/// Screen the profile menu was opened from. Entries that lead to where the
/// user already is are not offered.
enum ProfileMenuOrigin { map, businessPanel }

/// Centered menu with access to the account and the app's settings modules.
///
/// Use [showProfileMenuDialog] to open it.
class ProfileMenuDialogWidget extends ConsumerWidget {
  const ProfileMenuDialogWidget({
    super.key,
    this.origin = ProfileMenuOrigin.map,
  });

  final ProfileMenuOrigin origin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogged = ref.watch(authSessionStatusProvider);
    final user = isLogged ? ref.watch(profileStreamProvider).value : null;
    final colorScheme = Theme.of(context).colorScheme;
    final showsBusinessEntry =
        isLogged && origin != ProfileMenuOrigin.businessPanel;

    void select(ProfileMenuAction action) {
      Navigator.of(context).pop(action);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(OurnegoSpacingTokens.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Material(
            key: const ValueKey('profileMenuDialog'),
            type: MaterialType.transparency,
            child: OurnegoDialogSurface(
              customHorizontalPadding: OurnegoSpacingTokens.xs,
              customVerticalPadding: OurnegoSpacingTokens.md,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProfileHeader(
                      isLogged: isLogged,
                      name: user?.name,
                      email: user?.email,
                      imageUrl: user?.profilePicture,
                    ),
                    const SizedBox(height: OurnegoSpacingTokens.sm),
                    if (!isLogged)
                      _MenuItem(
                        key: const ValueKey('profileMenuLogInButton'),
                        icon: Icons.login_rounded,
                        label: 'Iniciar sesión o registrarse',
                        onTap: () => select(ProfileMenuAction.logIn),
                      ),
                    if (showsBusinessEntry) ...[
                      const _SectionLabel('Cuenta'),
                      _MenuItem(
                        key: const ValueKey('profileMenuBusinessButton'),
                        icon: Icons.storefront_rounded,
                        label: 'Mi negocio',
                        onTap: () => select(ProfileMenuAction.businessPanel),
                      ),
                    ],
                    const _SectionLabel('Configuración'),
                    _MenuItem(
                      key: const ValueKey('profileMenuLocationButton'),
                      icon: Icons.location_on_outlined,
                      label: 'Permisos de ubicación',
                      onTap: () =>
                          select(ProfileMenuAction.locationPermissions),
                    ),
                    _MenuItem(
                      key: const ValueKey('profileMenuFeedbackButton'),
                      icon: Icons.bug_report_outlined,
                      label: 'Reportar un problema',
                      onTap: () => select(ProfileMenuAction.reportProblem),
                    ),
                    if (kDebugMode)
                      _MenuItem(
                        key: const ValueKey('profileMenuDebugButton'),
                        icon: Icons.developer_mode_rounded,
                        label: 'Panel de depuración',
                        onTap: () => select(ProfileMenuAction.debugPanel),
                      ),
                    if (isLogged) ...[
                      const Divider(height: OurnegoSpacingTokens.lg),
                      _MenuItem(
                        key: const ValueKey('profileMenuLogoutButton'),
                        icon: Icons.logout_rounded,
                        label: 'Cerrar sesión',
                        color: colorScheme.error,
                        onTap: () => select(ProfileMenuAction.logOut),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the profile menu and resolves with the chosen entry, or `null`
/// when the menu is dismissed.
///
/// Pass the profile button's [trigger] so the menu grows out of it.
Future<ProfileMenuAction?> showProfileMenuDialog(
  BuildContext context, {
  ProfileMenuOrigin origin = ProfileMenuOrigin.map,
  ContainerTransformOriginController? trigger,
}) {
  return showOurnegoMenu<ProfileMenuAction>(
    context: context,
    origin: trigger,
    builder: (_) => ProfileMenuDialogWidget(origin: origin),
  );
}

class _ProfileHeader extends StatelessWidget {
  final bool isLogged;
  final String? name;
  final String? email;
  final String? imageUrl;

  const _ProfileHeader({
    required this.isLogged,
    required this.name,
    required this.email,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;
    final displayName = isLogged
        ? ((name?.trim().isNotEmpty ?? false) ? name!.trim() : 'Mi cuenta')
        : 'Invitado';
    final subtitle = isLogged
        ? (email ?? '')
        : 'Inicia sesión para gestionar tu cuenta';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OurnegoSpacingTokens.sm),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: colorScheme.surfaceContainerHighest,
            foregroundImage: hasImage ? NetworkImage(imageUrl!) : null,
            onForegroundImageError: hasImage ? (_, _) {} : null,
            child: Icon(
              Icons.person_rounded,
              size: 30,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(width: OurnegoSpacingTokens.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: OurnegoTextStyles.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: OurnegoTextStyles.bodyCompact.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OurnegoSpacingTokens.sm,
        OurnegoSpacingTokens.sm,
        OurnegoSpacingTokens.sm,
        OurnegoSpacingTokens.xxs,
      ),
      child: Text(
        label.toUpperCase(),
        style: OurnegoTextStyles.caption.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: foreground),
      title: Text(
        label,
        style: OurnegoTextStyles.body.copyWith(color: foreground),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.actionTile),
      ),
      visualDensity: VisualDensity.compact,
      onTap: onTap,
    );
  }
}
