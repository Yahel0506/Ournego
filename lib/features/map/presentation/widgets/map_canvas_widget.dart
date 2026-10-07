import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/presentation/models/business_marker_ui_model.dart';

class MapCanvasWidget extends StatelessWidget {
  final AnimatedMapController animatedMapController;
  final LatLng initialCenter;
  final double initialZoom;
  final bool mapTilesEnabled;
  final bool hasMapboxConfig;
  final bool isDarkModeOn;
  final String mapboxUsername;
  final String mapboxStyleId;
  final String mapboxAccessToken;
  final AppPosition? location;
  final AsyncValue<List<Business>> businessState;
  final bool isMarkerVisible;
  final bool isMarkerHidden;
  final Future<void> Function(double zoom) onCameraChanged;
  final void Function(Business business) onBusinessTap;
  final BusinessMarkerUiModel Function(Business business) markerUiMapper;
  final VoidCallback? onRetryBusinesses;

  const MapCanvasWidget({
    super.key,
    required this.animatedMapController,
    required this.initialCenter,
    required this.initialZoom,
    required this.mapTilesEnabled,
    required this.hasMapboxConfig,
    required this.isDarkModeOn,
    required this.mapboxUsername,
    required this.mapboxStyleId,
    required this.mapboxAccessToken,
    required this.location,
    required this.businessState,
    required this.isMarkerVisible,
    required this.isMarkerHidden,
    required this.onCameraChanged,
    required this.onBusinessTap,
    required this.markerUiMapper,
    this.onRetryBusinesses,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: animatedMapController.mapController,
      options: MapOptions(
        backgroundColor: Theme.of(context).colorScheme.surface,
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        minZoom: 3,
        maxZoom: 21,
        onPositionChanged: (camera, hasGesture) async {
          await onCameraChanged(camera.zoom);
        },
      ),
      children: [
        if (mapTilesEnabled && hasMapboxConfig)
          TileLayer(
            urlTemplate:
                'https://api.mapbox.com/styles/v1/$mapboxUsername/$mapboxStyleId/tiles/256/{z}/{x}/{y}@2x?access_token=$mapboxAccessToken',
            userAgentPackageName: 'com.ournego.app',
            tileProvider: kIsWeb
                ? NetworkTileProvider(silenceExceptions: true)
                : NetworkTileProvider(
                    silenceExceptions: true,
                    headers: {
                      'User-Agent': 'com.ournego.app',
                      'Referer': 'com.ournego.app',
                    },
                    cachingProvider:
                        BuiltInMapCachingProvider.getOrCreateInstance(
                          maxCacheSize: 1_000_000_000,
                        ),
                  ),
            key: Key(mapboxStyleId),
          )
        else if (mapTilesEnabled)
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.ournego.app',
            tileProvider: kIsWeb
                ? NetworkTileProvider(silenceExceptions: true)
                : NetworkTileProvider(
                    silenceExceptions: true,
                    headers: {'User-Agent': 'com.ournego.app'},
                    cachingProvider:
                        BuiltInMapCachingProvider.getOrCreateInstance(
                          maxCacheSize: 1_000_000_000,
                        ),
                  ),
            key: const Key('osm-fallback'),
          ),
        if (location != null)
          MarkerLayer(
            markers: [
              Marker(
                width: 20,
                height: 20,
                point: LatLng(location!.latitude, location!.longitude),
                child: GestureDetector(
                  onTap: () {
                    animatedMapController.animateTo(
                      dest: LatLng(location!.latitude, location!.longitude),
                      curve: Curves.easeIn,
                      zoom: 18,
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: OurnegoColors.verdeCastleton,
                      border: Border.all(
                        color: OurnegoColors.verdeMenta,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: OurnegoColors.verdeCastleton.withAlpha(150),
                          spreadRadius: 1,
                          blurRadius: 5,
                        ),
                      ],
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        businessState.when(
          data: (businessesList) {
            return MarkerLayer(
              markers: businessesList.map((business) {
                final marker = markerUiMapper(business);
                if (isMarkerVisible) {
                  return Marker(
                    rotate: true,
                    point: LatLng(business.latitude, business.longitude),
                    child: GestureDetector(
                      onTap: () => onBusinessTap(business),
                      child: Container(
                        key: ValueKey('businessMarker-${business.id}'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: marker.foregroundColor,
                          ),
                          color: marker.backgroundColor,
                        ),
                        child: Icon(
                          marker.icon,
                          size: 18,
                          color: marker.foregroundColor,
                        ),
                      ),
                    ),
                  );
                }

                if (!isMarkerHidden) {
                  return Marker(
                    height: 12,
                    width: 12,
                    rotate: true,
                    point: LatLng(business.latitude, business.longitude),
                    child: GestureDetector(
                      onTap: () => onBusinessTap(business),
                      child: Container(
                        key: ValueKey('businessMarker-${business.id}'),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            width: 2,
                            color: marker.foregroundColor,
                          ),
                          color: marker.backgroundColor,
                        ),
                      ),
                    ),
                  );
                }

                return const Marker(point: LatLng(0, 0), child: SizedBox());
              }).toList(),
            );
          },
          error: (error, _) {
            debugPrint(error.toString());
            return Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 110, left: 16, right: 16),
                child: ActionChip(
                  key: const Key('businesses-load-error'),
                  avatar: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'No pudimos cargar los negocios. Reintentar',
                  ),
                  onPressed: onRetryBusinesses,
                ),
              ),
            );
          },
          loading: () => const MarkerLayer(markers: []),
        ),
        Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 90, left: 10),
            child: Row(
              children: [
                IconButton(
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(200),
                  iconSize: 25,
                  icon: const Icon(Icons.info_outline),
                  onPressed: () {
                    showDialog(
                      animationStyle: AnimationStyle(
                        curve: Curves.bounceInOut,
                        duration: Durations.medium1,
                      ),
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        title: const Text(
                          'Créditos del Mapa',
                          style: OurnegoTextStyles.body,
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLink(
                              context,
                              '© Mapbox',
                              'https://www.mapbox.com/about/maps/',
                            ),
                            const SizedBox(height: 10),
                            _buildLink(
                              context,
                              '© OpenStreetMap',
                              'https://www.openstreetmap.org/copyright',
                            ),
                            const SizedBox(height: 10),
                            _buildLink(
                              context,
                              'Mejorar este mapa',
                              'https://www.mapbox.com/map-feedback/',
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            style: ButtonStyle(
                              foregroundColor: WidgetStatePropertyAll(
                                Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text(
                              'Cerrar',
                              style: OurnegoTextStyles.body,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (!hasMapboxConfig)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'OSM',
                      style: OurnegoTextStyles.body.copyWith(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(180),
                      ),
                    ),
                  ),
                Container(
                  child: hasMapboxConfig
                      ? isDarkModeOn
                            ? Image.asset(
                                'assets/images/mapbox-logo-white.png',
                                width: 100,
                                height: 25,
                                opacity: const AlwaysStoppedAnimation(.7),
                              )
                            : Image.asset(
                                'assets/images/mapbox-logo-black.png',
                                width: 80,
                                height: 20,
                                opacity: const AlwaysStoppedAnimation(.7),
                              )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLink(BuildContext context, String text, String url) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
        launchUrl(Uri.parse(url));
      },
      child: Row(
        children: [
          Icon(
            Icons.link,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.6),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: OurnegoTextStyles.link.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
