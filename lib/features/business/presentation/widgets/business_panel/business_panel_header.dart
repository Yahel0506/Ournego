import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/navigation/presentation/widgets/profile_menu/profile_menu_actions.dart';
import 'package:ournego/features/navigation/presentation/widgets/profile_menu/profile_menu_dialog_widget.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

class BusinessPanelHeader extends ConsumerWidget {
  const BusinessPanelHeader({
    super.key,
    required this.profileImageUrl,
    required this.isLogged,
  });

  final String profileImageUrl;
  final bool isLogged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SizedBox(
      height: 56,
      child: Row(
        children: [
          const Expanded(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Panel de negocio', style: OurnegoTextStyles.header),
            ),
          ),
          OurnegoIconButton(
            size: OurnegoIconButtonSize.s44,
            icon: isLogged ? Icons.account_circle_rounded : Icons.login_rounded,
            semanticLabel: isLogged ? 'Perfil' : 'Iniciar sesión',
            onPressed: () {
              if (isLogged) {
                openProfileMenu(
                  context,
                  ref,
                  origin: ProfileMenuOrigin.businessPanel,
                );
                return;
              }
              context.push(AuthRoutes.authSelection);
            },
            child: profileImageUrl.isNotEmpty
                ? Image.network(
                    profileImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.account_circle_rounded);
                    },
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
