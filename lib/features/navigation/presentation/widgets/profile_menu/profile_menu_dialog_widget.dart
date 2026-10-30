import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/shared/widgets/buttons/ournego_button_tokens.dart';
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
  deleteAccount,
  logOut,
}

/// Screen the profile menu was opened from. Entries that lead to where the
/// user already is are not offered.
enum ProfileMenuOrigin { map, businessPanel }

/// Centered menu with access to the account and the app's settings modules.
///
/// Use [showProfileMenuDialog] to open it.
class ProfileMenuDialogWidget extends ConsumerStatefulWidget {
  const ProfileMenuDialogWidget({
    super.key,
    this.origin = ProfileMenuOrigin.map,
    this.handoff,
  });

  final ProfileMenuOrigin origin;

  /// Receives the rect of the item the user taps, so the window that follows
  /// can grow out of it.
  final ContainerTransformHandoff? handoff;

  @override
  ConsumerState<ProfileMenuDialogWidget> createState() =>
      _ProfileMenuDialogWidgetState();
}

class _ProfileMenuDialogWidgetState
    extends ConsumerState<ProfileMenuDialogWidget> {
  bool _selected = false;

  @override
  Widget build(BuildContext context) {
    final origin = widget.origin;
    final isLogged = ref.watch(authSessionStatusProvider);
    final user = isLogged ? ref.watch(profileStreamProvider).value : null;
    final colorScheme = Theme.of(context).colorScheme;
    final showsBusinessEntry =
        isLogged && origin != ProfileMenuOrigin.businessPanel;

    void select(ProfileMenuAction action) {
      // While the menu closes it still receives touches; a second one must not
      // pop another route.
      if (_selected) return;
      _selected = true;
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
              customHorizontalPadding: OurnegoSpacingTokens.sm,
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
                    if (!isLogged) ...[
                      const SizedBox(height: OurnegoSpacingTokens.sm),
                      _MenuGroup(
                        handoff: widget.handoff,
                        items: [
                          _MenuItem(
                            key: const ValueKey('profileMenuLogInButton'),
                            icon: Icons.login_rounded,
                            label: 'Iniciar sesión o registrarse',
                            onTap: () => select(ProfileMenuAction.logIn),
                          ),
                        ],
                      ),
                    ],
                    if (showsBusinessEntry) ...[
                      const _SectionLabel('Cuenta'),
                      _MenuGroup(
                        handoff: widget.handoff,
                        items: [
                          _MenuItem(
                            key: const ValueKey('profileMenuBusinessButton'),
                            icon: Icons.storefront_rounded,
                            label: 'Mi negocio',
                            onTap: () =>
                                select(ProfileMenuAction.businessPanel),
                          ),
                        ],
                      ),
                    ],
                    const _SectionLabel('Configuración'),
                    _MenuGroup(
                      handoff: widget.handoff,
                      items: [
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
                      ],
                    ),
                    if (isLogged) ...[
                      const SizedBox(height: OurnegoSpacingTokens.sm),
                      _MenuGroup(
                        handoff: widget.handoff,
                        items: [
                          _MenuItem(
                            key: const ValueKey(
                              'profileMenuDeleteAccountButton',
                            ),
                            icon: Icons.delete_forever_outlined,
                            label: 'Eliminar cuenta',
                            color: colorScheme.error,
                            onTap: () =>
                                select(ProfileMenuAction.deleteAccount),
                          ),
                          _MenuItem(
                            key: const ValueKey('profileMenuLogoutButton'),
                            icon: Icons.logout_rounded,
                            label: 'Cerrar sesión',
                            color: colorScheme.error,
                            onTap: () => select(ProfileMenuAction.logOut),
                          ),
                        ],
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
/// Pass the profile button's [trigger] so the menu grows out of it. Pass a
/// [handoff] to learn which item was tapped (its rect), so the next window can
/// grow out of that item.
Future<ProfileMenuAction?> showProfileMenuDialog(
  BuildContext context, {
  ProfileMenuOrigin origin = ProfileMenuOrigin.map,
  ContainerTransformOriginController? trigger,
  ContainerTransformHandoff? handoff,
}) {
  return showOurnegoMenu<ProfileMenuAction>(
    context: context,
    origin: trigger,
    builder: (_) => ProfileMenuDialogWidget(origin: origin, handoff: handoff),
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
      padding: const EdgeInsets.symmetric(horizontal: OurnegoSpacingTokens.xs),
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
        OurnegoSpacingTokens.xs,
        OurnegoSpacingTokens.md,
        OurnegoSpacingTokens.xs,
        OurnegoSpacingTokens.xs,
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

/// The options of one section: bricks of a single rounded rectangle, like the
/// groups in Google's settings. The outer corners are generous, the corners
/// between bricks are small, and a thin gap separates them.
class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.items, this.handoff});

  static const double _outerRadius = 18;
  static const double _innerRadius = 4;
  static const double _gap = 2;

  final List<_MenuItem> items;
  final ContainerTransformHandoff? handoff;

  BorderRadius _radiusFor(int index) {
    const outer = Radius.circular(_outerRadius);
    const inner = Radius.circular(_innerRadius);
    final isFirst = index == 0;
    final isLast = index == items.length - 1;
    return BorderRadius.vertical(
      top: isFirst ? outer : inner,
      bottom: isLast ? outer : inner,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A touch off the dialog's face, so each brick reads as its own piece.
    final brick = Color.alphaBlend(
      scheme.onSurface.withValues(alpha: 0.07),
      OurnegoGlassPalette.navFace(scheme),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          items[i].asBrick(
            color: brick,
            radius: _radiusFor(i),
            handoff: handoff,
          ),
        ],
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  final Color? brickColor;
  final BorderRadius radius;
  final ContainerTransformHandoff? handoff;

  const _MenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
    this.brickColor,
    this.radius = BorderRadius.zero,
    this.handoff,
  });

  /// The same item, drawn as a brick of a group. Keeps the key.
  _MenuItem asBrick({
    required Color color,
    required BorderRadius radius,
    ContainerTransformHandoff? handoff,
  }) {
    return _MenuItem(
      key: key,
      icon: icon,
      label: label,
      onTap: onTap,
      color: this.color,
      brickColor: color,
      radius: radius,
      handoff: handoff,
    );
  }

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? Theme.of(context).colorScheme.onSurface;

    return Material(
      color: brickColor ?? Colors.transparent,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: radius),
      child: ListTile(
        leading: Icon(icon, color: foreground),
        title: Text(
          label,
          style: OurnegoTextStyles.body.copyWith(color: foreground),
        ),
        visualDensity: VisualDensity.compact,
        onTap: () {
          // The window that follows grows out of this brick: its rect, its
          // largest corner and its color (the menu's block color).
          handoff?.capture(
            context,
            radius: [
              radius.topLeft.x,
              radius.topRight.x,
              radius.bottomLeft.x,
              radius.bottomRight.x,
            ].reduce(math.max),
            color: brickColor ?? Theme.of(context).colorScheme.surface,
          );
          onTap();
        },
      ),
    );
  }
}
