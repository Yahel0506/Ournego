import 'package:flutter/material.dart';

import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';

/// Whether [status] should be announced with the persistent map banner.
bool locationStatusNeedsBanner(LocationAccessStatus? status) {
  return status == LocationAccessStatus.permissionDenied ||
      status == LocationAccessStatus.permissionDeniedForever ||
      status == LocationAccessStatus.serviceDisabled;
}

/// Persistent, non-dismissible notice shown only on the map while location is
/// unavailable. It disappears by itself once access is restored.
class MapLocationBanner extends StatelessWidget {
  const MapLocationBanner({
    super.key,
    required this.status,
    required this.onAction,
  });

  final LocationAccessStatus status;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isService = status == LocationAccessStatus.serviceDisabled;
    final isPermanent = status == LocationAccessStatus.permissionDeniedForever;

    final message = isService
        ? 'Tu GPS está apagado'
        : 'Ournego no puede ver tu ubicación';
    final actionLabel = isService
        ? 'Activar'
        : (isPermanent ? 'Ajustes' : 'Permitir');

    return Semantics(
      container: true,
      liveRegion: true,
      child: OurnegoContentContainer(
        key: const Key('map-location-banner'),
        hasBlur: true,
        borderRadius: 20,
        customHorizontalPadding: OurnegoSpacingTokens.md,
        customVerticalPadding: OurnegoSpacingTokens.xs,
        child: Row(
          children: [
            Icon(
              isService
                  ? Icons.location_disabled_rounded
                  : Icons.location_off_rounded,
              color: OurnegoColorTokens.warning,
              size: 22,
            ),
            const SizedBox(width: OurnegoSpacingTokens.sm),
            Expanded(
              child: Text(
                message,
                style: OurnegoTextStyles.bodyCompact.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            FilledButton(
              key: const Key('map-location-banner-action'),
              onPressed: onAction,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 36),
                padding: const EdgeInsets.symmetric(
                  horizontal: OurnegoSpacingTokens.md,
                ),
                textStyle: OurnegoTextStyles.bodyCompact.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
