import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';

class BusinessPanelGallery extends StatelessWidget {
  const BusinessPanelGallery({
    super.key,
    required this.images,
    required this.onDeleteImage,
    required this.onAddImage,
  });

  final List<String> images;
  final void Function(
    String imageUrl,
    ContainerTransformOriginController origin,
  )
  onDeleteImage;
  final VoidCallback onAddImage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    if (images.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(OurnegoSpacingTokens.md),
        decoration: BoxDecoration(
          color: colorScheme.inverseSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
          border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: OurnegoColorTokens.warning,
              size: 34,
            ),
            const SizedBox(height: OurnegoSpacingTokens.xs),
            const Text(
              'Debes agregar al menos una imagen de tu negocio.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: OurnegoSpacingTokens.sm),
            OurnegoButton.primary(
              size: OurnegoButtonSize.compact,
              label: 'Agregar imagen',
              icon: Icons.add_rounded,
              onPressed: onAddImage,
            ),
          ],
        ),
      );
    }

    final canDelete = images.length > 1;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: OurnegoSpacingTokens.xs),
        itemBuilder: (context, index) {
          final imageUrl = images[index];
          return Container(
            width: 130,
            decoration: BoxDecoration(
              color: colorScheme.inverseSurface.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.broken_image_outlined, size: 30),
                        );
                      },
                    ),
                  ),
                ),
                if (index == 0)
                  Positioned(
                    top: OurnegoSpacingTokens.xs,
                    left: OurnegoSpacingTokens.xs,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OurnegoSpacingTokens.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(
                          OurnegoRadiusTokens.full,
                        ),
                      ),
                      child: Text(
                        'Principal',
                        style: OurnegoTextStyles.badge.copyWith(
                          color: colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                if (canDelete)
                  Positioned(
                    right: OurnegoSpacingTokens.xs,
                    bottom: OurnegoSpacingTokens.xs,
                    // The confirmation grows out of the delete button.
                    child: ContainerTransformTrigger(
                      radius: OurnegoRadiusTokens.sm,
                      builder: (context, origin) => OurnegoIconButton(
                        size: OurnegoIconButtonSize.s28,
                        icon: Icons.delete_outline_rounded,
                        semanticLabel: 'Eliminar imagen',
                        onPressed: () => onDeleteImage(imageUrl, origin),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
