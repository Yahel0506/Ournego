import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/navigation/presentation/widgets/profile_menu/profile_menu_actions.dart';
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
            onPressed: () => openProfileMenu(context, ref),
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
