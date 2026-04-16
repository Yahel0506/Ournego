import 'package:flutter/material.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/action_tile.dart';

class BentoActionGrid extends StatelessWidget {
  final VoidCallback onFavorite;
  final VoidCallback onContact;
  final VoidCallback onCatalog;
  final VoidCallback onReviews;

  const BentoActionGrid({
    super.key,
    required this.onFavorite,
    required this.onContact,
    required this.onCatalog,
    required this.onReviews,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.95,
      children: [
        ActionTile(
          icon: Icons.star_rounded,
          label: 'Favorito',
          onTap: onFavorite,
        ),
        ActionTile(
          icon: Icons.phone_rounded,
          label: 'Contacto',
          onTap: onContact,
        ),
        ActionTile(
          icon: Icons.inventory_2_rounded,
          label: 'Catalogo',
          onTap: onCatalog,
        ),
        ActionTile(
          icon: Icons.chat_bubble_rounded,
          label: 'Resenas',
          onTap: onReviews,
        ),
      ],
    );
  }
}
