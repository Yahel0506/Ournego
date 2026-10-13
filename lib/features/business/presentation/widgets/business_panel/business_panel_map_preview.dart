import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:ournego/core/mapbox_config.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

class BusinessPanelMapPreview extends StatelessWidget {
  const BusinessPanelMapPreview({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.onEdit,
  });

  final String address;
  final double latitude;
  final double longitude;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final token = MapboxConfig.accessToken;
    final hasMapbox = token.isNotEmpty;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: colorScheme.inverseSurface.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(OurnegoRadiusTokens.md),
              child: IgnorePointer(
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(latitude, longitude),
                    initialZoom: 16,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: hasMapbox
                          ? 'https://api.mapbox.com/styles/v1/mapbox/streets-v12/tiles/512/{z}/{x}/{y}@2x?access_token=$token'
                          : 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.ournego.app',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(latitude, longitude),
                          width: 36,
                          height: 36,
                          child: Icon(
                            Icons.location_on_rounded,
                            color: colorScheme.error,
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: OurnegoSpacingTokens.sm,
            bottom: OurnegoSpacingTokens.sm,
            right: OurnegoSpacingTokens.sm,
            child: Text(
              address,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: OurnegoTextStyles.body.copyWith(fontSize: 12),
            ),
          ),
          Positioned(
            right: OurnegoSpacingTokens.xs,
            top: OurnegoSpacingTokens.xs,
            child: OurnegoIconButton(
              size: OurnegoIconButtonSize.s28,
              icon: Icons.edit_rounded,
              semanticLabel: 'Editar ubicación',
              onPressed: onEdit,
            ),
          ),
        ],
      ),
    );
  }
}
