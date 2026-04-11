import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/mapbox_config.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/features/map/presentation/mappers/business_marker_ui_mapper.dart';
import 'package:ournego/features/map/presentation/models/business_marker_ui_model.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/map/presentation/widgets/business_information_widget.dart';
import 'package:ournego/features/map/presentation/widgets/top_navigation_bar_widget.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  late final _animatedMapController = AnimatedMapController(vsync: this);
  late ProviderSubscription<AsyncValue<AppPosition>> _providerSubscription;

  final _businessMarkerUiMapper = BusinessMarkerUiMapper();

  final _modalController = DraggableScrollableController();

  LatLng? _initialCenter;
  double? _initialZoom;
  bool _isLocationModalOpen = false;

  Future<void> _restoreCamera() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLatitude = prefs.getDouble('lastLatitude');
    final lastLongitude = prefs.getDouble('lastLongitude');
    final lastZoom = prefs.getDouble('lastZoom');

    if (lastLatitude != null && lastLongitude != null) {
      _initialCenter = LatLng(lastLatitude, lastLongitude);
    }
    _initialZoom = lastZoom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialCenter != null) {
        _animatedMapController.animateTo(
          dest: _initialCenter,
          zoom: _initialZoom ?? 15,
        );
      }
    });

    setState(() {});
  }

  bool _isMarkerVisible = true;
  bool _isMarkerHidden = false;

  void checkMinZoom(double zoom) {
    final bool shouldBeVisible = zoom >= 17;
    final bool shouldBeHidden = zoom < 13.5;

    if (_isMarkerVisible != shouldBeVisible) {
      setState(() {
        _isMarkerVisible = shouldBeVisible;
      });
    }
    if (_isMarkerHidden != shouldBeHidden) {
      setState(() {
        _isMarkerHidden = shouldBeHidden;
      });
    }
  }

  Future<void> _retryLocationRequest({
    bool requestPermissionIfNeeded = true,
  }) async {
    await ref
        .read(mapProvider.notifier)
        .refreshLocation(requestPermissionIfNeeded: requestPermissionIfNeeded);
  }

  Future<void> _showLocationErrorSheet(Object error) async {
    if (_isLocationModalOpen || !mounted) {
      return;
    }

    _isLocationModalOpen = true;

    final isDenied = error is LocationPermissionDeniedFailure;
    final isDeniedForever = error is LocationPermissionDeniedForeverFailure;
    final isServiceDisabled = error is LocationServiceDisabledFailure;

    final title = isDenied
        ? 'El permiso de ubicacion fue denegado'
        : isDeniedForever
        ? 'El permiso de ubicacion fue negado permanentemente'
        : isServiceDisabled
        ? 'Los servicios de ubicacion estan desactivados'
        : 'No se pudo obtener tu ubicacion';

    final description = isDenied
        ? 'Otorga el permiso para usar la funcion de mapa.'
        : isDeniedForever
        ? 'Habilitalo manualmente desde ajustes para usar el mapa.'
        : isServiceDisabled
        ? 'Activa el GPS o los servicios de ubicacion del dispositivo.'
        : 'Verifica el permiso y la señal GPS, luego intenta de nuevo.';

    final actionLabel = isDeniedForever
        ? 'Abrir ajustes'
        : isServiceDisabled
        ? 'Activar ubicacion'
        : 'Reintentar';

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: true,
      builder: (modalContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                InformationCardWidget(
                  title: title,
                  description: description,
                  imagePath: 'assets/images/location_error.png',
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(modalContext).pop(),
                          child: const Text('Cerrar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            Navigator.of(modalContext).pop();

                            if (isDeniedForever) {
                              await Geolocator.openAppSettings();
                              return;
                            }

                            if (isServiceDisabled) {
                              await Geolocator.openLocationSettings();
                              return;
                            }

                            await _retryLocationRequest(
                              requestPermissionIfNeeded: true,
                            );
                          },
                          child: Text(actionLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    _isLocationModalOpen = false;
  }

  @override
  void initState() {
    super.initState();

    _providerSubscription = ref.listenManual<AsyncValue<AppPosition>>(
      mapProvider,
      (previous, next) {
        next.whenOrNull(
          data: (data) {
            if (_initialCenter == null) {
              _animatedMapController.animateTo(
                dest: LatLng(data.latitude, data.longitude),
                zoom: 15,
              );
            }
          },
          error: (error, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _showLocationErrorSheet(error);
            });
          },
        );
      },
    );
    _restoreCamera();
  }

  @override
  void dispose() {
    _animatedMapController.dispose();
    _modalController.dispose();
    _providerSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapState = ref.watch(mapProvider);
    final location = mapState.asData?.value;
    final businessState = ref.watch(businessesStreamProvider);

    final bool isWide = MediaQuery.of(context).size.width > 600;

    final bool isDarkModeOn =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    final String myAccessToken = MapboxConfig.accessToken;
    final String myUsername = MapboxConfig.username;

    final String styleIdDark = MapboxConfig.styleIdDark;
    final String styleIdLight = MapboxConfig.styleIdLight;

    final String currentStyleId = isDarkModeOn ? styleIdDark : styleIdLight;
    final bool hasMapboxConfig =
        myAccessToken.isNotEmpty &&
        myUsername.isNotEmpty &&
        currentStyleId.isNotEmpty;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          FlutterMap(
            mapController: _animatedMapController.mapController,
            options: MapOptions(
              backgroundColor: Theme.of(context).colorScheme.surface,
              initialCenter: _initialCenter ?? LatLng(19.7000112, -103.4654738),
              initialZoom: _initialZoom ?? 12,
              minZoom: 3,
              maxZoom: 21,
              onPositionChanged: (camera, hasGesture) async {
                final prefs = await SharedPreferences.getInstance();
                final position = camera.center;
                prefs.setDouble('lastLatitude', position.latitude);
                prefs.setDouble('lastLongitude', position.longitude);
                prefs.setDouble('lastZoom', camera.zoom);
                checkMinZoom(camera.zoom);
              },
            ),
            children: [
              if (hasMapboxConfig)
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/$myUsername/$currentStyleId/tiles/256/{z}/{x}/{y}@2x?access_token=$myAccessToken',
                  userAgentPackageName: 'com.ournego.app',
                  tileProvider: NetworkTileProvider(
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
                  key: Key(currentStyleId),
                )
              else
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.ournego.app',
                  tileProvider: NetworkTileProvider(
                    silenceExceptions: true,
                    headers: {
                      'User-Agent': 'com.ournego.app',
                    },
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
                      point: LatLng(location.latitude, location.longitude),
                      child: GestureDetector(
                        onTap: () {
                          _animatedMapController.animateTo(
                            dest: LatLng(location.latitude, location.longitude),
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
                                color: OurnegoColors.verdeCastleton.withAlpha(
                                  150,
                                ),
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
                      final BusinessMarkerUiModel marker =
                          _businessMarkerUiMapper(business);

                      if (_isMarkerVisible) {
                        return Marker(
                          rotate: true,
                          point: LatLng(business.latitude, business.longitude),
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(selectedBusiness.notifier)
                                  .selectedBusiness(business);

                              _animatedMapController.animateTo(
                                dest: LatLng(
                                  business.latitude,
                                  business.longitude,
                                ),
                                zoom: 18,
                              );

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_modalController.isAttached) {
                                  _modalController.animateTo(
                                    0.25,
                                    duration: Durations.medium1,
                                    curve: Curves.linearToEaseOut,
                                  );
                                }
                              });
                            },
                            child: Container(
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
                      } else if (!_isMarkerHidden) {
                        return Marker(
                          height: 12,
                          width: 12,
                          rotate: true,
                          point: LatLng(business.latitude, business.longitude),
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(selectedBusiness.notifier)
                                  .selectedBusiness(business);

                              _animatedMapController.animateTo(
                                dest: LatLng(
                                  business.latitude,
                                  business.longitude,
                                ),
                                zoom: 18,
                              );

                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (_modalController.isAttached) {
                                  _modalController.animateTo(
                                    0.25,
                                    duration: Durations.medium1,
                                    curve: Curves.linearToEaseOut,
                                  );
                                }
                              });
                            },
                            child: Container(
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
                      } else {
                        return const Marker(
                          point: LatLng(0, 0),
                          child: SizedBox(),
                        );
                      }
                    }).toList(),
                  );
                },
                error: (error, _) {
                  debugPrint(error.toString());
                  return const SizedBox();
                },
                loading: () => const MarkerLayer(markers: []),
              ),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 40, left: 10),
                  child: Row(
                    children: [
                      IconButton(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withAlpha(200),
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
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface,
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
          ),
          TopNavigationBarWidget(),
          Column(
            children: [
              Spacer(),
              Row(
                children: [
                  Spacer(),
                  Column(
                    children: [
                      FloatingActionButton(
                        heroTag: 'btnZoomIn',
                        onPressed: () {
                          final double currentZoom =
                              _animatedMapController.mapController.camera.zoom;

                          _animatedMapController.animateTo(
                            zoom: currentZoom + 1,
                            duration: Durations.short4,
                          );
                        },
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        child: Icon(Icons.zoom_in),
                      ),
                      SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'btnZoomOut',
                        onPressed: () {
                          final double currentZoom =
                              _animatedMapController.mapController.camera.zoom;

                          _animatedMapController.animateTo(
                            zoom: currentZoom - 1,
                            duration: Durations.short4,
                          );
                        },
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        child: Icon(Icons.zoom_out),
                      ),
                      SizedBox(height: 12),
                      FloatingActionButton(
                        heroTag: 'btnLocation',
                        onPressed: () async {
                          final currentLocation = ref
                              .read(mapProvider)
                              .asData
                              ?.value;

                          if (currentLocation != null) {
                            _animatedMapController.animateTo(
                              dest: LatLng(
                                currentLocation.latitude,
                                currentLocation.longitude,
                              ),
                              zoom: 15,
                              rotation: 0,
                            );
                            return;
                          }

                          await _retryLocationRequest(
                            requestPermissionIfNeeded: true,
                          );

                          final refreshedState = ref.read(mapProvider);
                          final refreshedLocation =
                              refreshedState.asData?.value;

                          if (refreshedLocation != null) {
                            _animatedMapController.animateTo(
                              dest: LatLng(
                                refreshedLocation.latitude,
                                refreshedLocation.longitude,
                              ),
                              zoom: 15,
                              rotation: 0,
                            );
                            return;
                          }

                          final locationError = refreshedState.asError?.error;
                          if (locationError != null) {
                            await _showLocationErrorSheet(locationError);
                          }
                        },
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.secondaryContainer,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onSurface,
                        child: Icon(Icons.location_searching),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                ],
              ),
              SizedBox(height: 60),
            ],
          ),
          Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: isWide ? 600 : double.maxFinite,
              child: NotificationListener<DraggableScrollableNotification>(
                onNotification: (notification) {
                  final double currentSize = notification.extent;

                  int newState;

                  if (currentSize == 0.95) {
                    newState = 2; // Está cerca de 0.9
                  } else if (currentSize > 0.25) {
                    newState = 1; // Está cerca de 0.5
                  } else {
                    newState = 0; // Está cerca de 0.2
                  }

                  final int currentStateInProvider = ref.read(modalState);

                  if (newState != currentStateInProvider) {
                    ref.read(modalState.notifier).changeStateTo(newState);
                  }

                  return true;
                },
                child: DraggableScrollableSheet(
                  controller: _modalController,
                  shouldCloseOnMinExtent: false,
                  snap: true,
                  snapSizes: [0.25, 0.6, 0.95],
                  initialChildSize: 0.0,
                  minChildSize: 0.0,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    {
                      return BusinessInformationWidget(
                        scrollController: scrollController,
                      );
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _buildLink(BuildContext context, String text, String url) {
  return GestureDetector(
    onTap: () {
      Navigator.of(context).pop();
      launchUrl(Uri.parse(url));
    },
    child: Row(
      children: [
        const Icon(Icons.link, color: Colors.grey, size: 16),
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
