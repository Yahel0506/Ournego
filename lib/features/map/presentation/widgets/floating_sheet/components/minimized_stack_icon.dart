import 'package:flutter/material.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

class MinimizedStackIcon extends StatelessWidget {
  final SheetBusinessData business;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const MinimizedStackIcon({
    super.key,
    required this.business,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = business.images.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: hasImage
              ? Image.network(
                  business.images.first,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.store_rounded,
                    color: Theme.of(context).colorScheme.inverseSurface,
                    size: 22,
                  ),
                )
              : Icon(
                  Icons.store_rounded,
                  color: Theme.of(context).colorScheme.inverseSurface,
                  size: 22,
                ),
        ),
      ),
    );
  }
}
