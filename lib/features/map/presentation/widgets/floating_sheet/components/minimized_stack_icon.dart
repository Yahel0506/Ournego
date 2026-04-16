import 'package:flutter/material.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/presentation/mappers/business_marker_ui_mapper.dart';
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
    const markerMapper = BusinessMarkerUiMapper();
    final markerUi = markerMapper(
      Business(
        id: business.id,
        name: business.name,
        description: business.description,
        ownerId: business.ownerId,
        address: business.address,
        phoneNumber: business.phoneNumber,
        latitude: 0,
        longitude: 0,
        type: business.type,
        images: business.images,
      ),
    );

    Widget fallbackIcon() {
      return Icon(
        markerUi.icon,
        color: Theme.of(context).colorScheme.inverseSurface,
        size: 22,
      );
    }

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
                  errorBuilder: (context, error, stackTrace) => fallbackIcon(),
                )
              : fallbackIcon(),
        ),
      ),
    );
  }
}
