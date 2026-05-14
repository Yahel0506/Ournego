import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_icon_button.dart';

class BusinessPanelHeader extends StatelessWidget {
  const BusinessPanelHeader({
    super.key,
    required this.profileImageUrl,
    required this.isLogged,
  });

  final String profileImageUrl;
  final bool isLogged;

  @override
  Widget build(BuildContext context) {
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
          BusinessPanelIconButton(
            onTap: () {
              if (isLogged) return;
              context.push(AuthRoutes.authSelection);
            },
            child: profileImageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(
                      OurnegoRadiusTokens.full,
                    ),
                    child: Image.network(
                      profileImageUrl,
                      fit: BoxFit.cover,
                      width: 34,
                      height: 34,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.account_circle_rounded);
                      },
                    ),
                  )
                : Icon(
                    isLogged
                        ? Icons.account_circle_rounded
                        : Icons.login_rounded,
                  ),
          ),
        ],
      ),
    );
  }
}
