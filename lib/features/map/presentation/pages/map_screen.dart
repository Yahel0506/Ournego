import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/mapbox_config.dart';
import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/presentation/mappers/business_marker_ui_mapper.dart';
import 'package:ournego/features/map/presentation/models/business_marker_ui_model.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_controller.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_state.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/ournego_floating_sheet.dart';
import 'package:ournego/features/map/presentation/widgets/top_navigation_bar_widget.dart';
import 'package:ournego/features/navigation/presentation/widgets/navigation_bar_widget.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? initialBusinessId;

  const MapScreen({super.key, this.initialBusinessId});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  static const _lastLatitudeKey = 'map_last_latitude';
  static const _lastLongitudeKey = 'map_last_longitude';
  static const _lastZoomKey = 'map_last_zoom';
  static const _markerVisibleKey = 'map_marker_visible';
  static const _markerHiddenKey = 'map_marker_hidden';
  static const _sheetStateKey = 'map_sheet_state';
  static const _sheetActiveBusinessKey = 'map_sheet_active_business';
  static const _sheetComparisonBusinessKey = 'map_sheet_comparison_business';
  static const _sheetMinimizedListKey = 'map_sheet_minimized_list';

  late final _animatedMapController = AnimatedMapController(vsync: this);
  late ProviderSubscription<AsyncValue<AppPosition>> _providerSubscription;
  late final FloatingSheetController _floatingSheetController;

  final _businessMarkerUiMapper = BusinessMarkerUiMapper();

  LatLng? _initialCenter;
  double? _initialZoom;
  bool _isLocationModalOpen = false;
  String? _pendingDeepLinkBusinessId;
  bool _didReportMissingDeepLinkBusiness = false;
  bool _isResolvingDeepLink = false;

  double get _expandedHeight {
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final topPadding = mq.padding.top;
    final bottomPadding = mq.padding.bottom;
    final topBarHeight = _readWidgetHeight(topNavigationBarKey, fallback: 56);
    final navBarHeight = _readWidgetHeight(appNavigationBarKey, fallback: 72);

    return screenHeight -
        topPadding -
        topBarHeight -
        navBarHeight -
        bottomPadding +
        90;
  }

  double get _collapsedHeight {
    final screenHeight = MediaQuery.of(context).size.height;
    return (screenHeight * 0.24);
  }

  double _readWidgetHeight(GlobalKey key, {required double fallback}) {
    final targetContext = key.currentContext;
    if (targetContext == null) {
      return fallback;
    }

    final renderObject = targetContext.findRenderObject();
    if (renderObject is RenderBox && renderObject.hasSize) {
      return renderObject.size.height;
    }

    return fallback;
  }

  Future<void> _restoreCamera() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLatitude = prefs.getDouble(_lastLatitudeKey);
    final lastLongitude = prefs.getDouble(_lastLongitudeKey);
    final lastZoom = prefs.getDouble(_lastZoomKey);

    _isMarkerVisible = prefs.getBool(_markerVisibleKey) ?? true;
    _isMarkerHidden = prefs.getBool(_markerHiddenKey) ?? false;

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

  Future<void> _restoreSheetStateFromPrefs() async {
    // If a deep link is pending, skip restoring previous sheet state.
    // The target business sheet will be opened by _handleDeepLinkBusinessOpen.
    if (_pendingDeepLinkBusinessId != null) return;

    final prefs = await SharedPreferences.getInstance();
    final rawState = prefs.getString(_sheetStateKey);
    final rawActiveBusiness = prefs.getString(_sheetActiveBusinessKey);
    final rawComparisonBusiness = prefs.getString(_sheetComparisonBusinessKey);
    final rawMinimizedList = prefs.getString(_sheetMinimizedListKey);

    if (rawState == null &&
        rawActiveBusiness == null &&
        rawComparisonBusiness == null &&
        rawMinimizedList == null) {
      return;
    }

    SheetBusinessData? parseBusiness(String? raw) {
      if (raw == null || raw.isEmpty) return null;

      try {
        final json = jsonDecode(raw) as Map<String, dynamic>;
        return SheetBusinessData.fromJson(json);
      } catch (_) {
        return null;
      }
    }

    List<SheetBusinessData> parseMinimized(String? raw) {
      if (raw == null || raw.isEmpty) return const [];

      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(SheetBusinessData.fromJson)
            .toList(growable: false);
      } catch (_) {
        return const [];
      }
    }

    final restoredState = FloatingSheetStateCodec.fromStorageValue(
      rawState ?? 'collapsed',
    );
    final activeBusiness = parseBusiness(rawActiveBusiness);
    final comparisonBusiness = parseBusiness(rawComparisonBusiness);
    final minimizedList = parseMinimized(rawMinimizedList);

    _floatingSheetController.restoreState(
      state: restoredState,
      activeBusiness: activeBusiness,
      comparisonBusiness: comparisonBusiness,
      minimizedBusinesses: minimizedList,
    );
  }

  Future<void> _persistMapAndSheetState() async {
    final prefs = await SharedPreferences.getInstance();
    final camera = _animatedMapController.mapController.camera;

    await prefs.setDouble(_lastLatitudeKey, camera.center.latitude);
    await prefs.setDouble(_lastLongitudeKey, camera.center.longitude);
    await prefs.setDouble(_lastZoomKey, camera.zoom);
    await prefs.setBool(_markerVisibleKey, _isMarkerVisible);
    await prefs.setBool(_markerHiddenKey, _isMarkerHidden);

    final activeBusiness = _floatingSheetController.activeBusiness;
    final comparisonBusiness = _floatingSheetController.comparisonBusiness;
    final minimizedBusinesses = _floatingSheetController.minimizedBusinesses;

    await prefs.setString(
      _sheetStateKey,
      _floatingSheetController.state.storageValue,
    );

    if (activeBusiness != null) {
      await prefs.setString(
        _sheetActiveBusinessKey,
        jsonEncode(activeBusiness.toJson()),
      );
    } else {
      await prefs.remove(_sheetActiveBusinessKey);
    }

    if (comparisonBusiness != null) {
      await prefs.setString(
        _sheetComparisonBusinessKey,
        jsonEncode(comparisonBusiness.toJson()),
      );
    } else {
      await prefs.remove(_sheetComparisonBusinessKey);
    }

    if (minimizedBusinesses.isNotEmpty) {
      final encoded = minimizedBusinesses.map((b) => b.toJson()).toList();
      await prefs.setString(_sheetMinimizedListKey, jsonEncode(encoded));
    } else {
      await prefs.remove(_sheetMinimizedListKey);
    }
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
      // ⚠️ OUT OF SCOPE — OurnegoFloatingSheet migration
      // Este showModalBottomSheet maneja errores de permisos de ubicación.
      // NO modificar, mover ni eliminar como parte de esta tarea.
      // Relacionado con: _showLocationErrorSheet() / permisos GPS
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

  void _openBusinessSheet(Business business, {bool animateToBusiness = true}) {
    if (_floatingSheetController.isComparisonMode) {
      return;
    }

    final favoriteAsync = ref.read(
      isBusinessFavoriteStreamProvider(business.id),
    );
    final isFavorite = favoriteAsync.value ?? false;

    _floatingSheetController.openBusiness(
      SheetBusinessData.fromBusiness(business, isFavorite: isFavorite),
    );

    if (animateToBusiness) {
      _animatedMapController.animateTo(
        dest: LatLng(business.latitude, business.longitude),
        zoom: 18,
      );
    }
  }

  void _reportMissingDeepLinkBusiness() {
    if (_didReportMissingDeepLinkBusiness || !mounted) {
      return;
    }

    _didReportMissingDeepLinkBusiness = true;
    _pendingDeepLinkBusinessId = null;
    ScaffoldMessenger.of(context).showSnackBar(
      OurnegoSnackbars.info('No encontramos el negocio solicitado'),
    );
  }

  Future<void> _resolveDeepLinkBusiness() async {
    final targetId = _pendingDeepLinkBusinessId;
    if (targetId == null || targetId.isEmpty || _isResolvingDeepLink) {
      return;
    }

    _isResolvingDeepLink = true;
    final usecase = ref.read(getBusinessByIdUsecaseProvider);
    final result = await usecase(targetId);

    if (!mounted) {
      _isResolvingDeepLink = false;
      return;
    }

    result.fold((_) => _reportMissingDeepLinkBusiness(), (business) {
      if (business == null) {
        _reportMissingDeepLinkBusiness();
        return;
      }

      _pendingDeepLinkBusinessId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openBusinessSheet(business);
      });
    });

    _isResolvingDeepLink = false;
  }

  @override
  void initState() {
    super.initState();
    _pendingDeepLinkBusinessId = widget.initialBusinessId;
    _floatingSheetController = FloatingSheetController();
    _floatingSheetController.addListener(_persistMapAndSheetState);

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

    _resolveDeepLinkBusiness();

    _restoreCamera();
    _restoreSheetStateFromPrefs();
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBusinessId == widget.initialBusinessId) {
      return;
    }

    _pendingDeepLinkBusinessId = widget.initialBusinessId;
    _didReportMissingDeepLinkBusiness = false;

    _resolveDeepLinkBusiness();
  }

  @override
  void dispose() {
    _floatingSheetController.removeListener(_persistMapAndSheetState);
    _animatedMapController.dispose();
    _providerSubscription.close();
    _floatingSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapTilesEnabled = ref.watch(mapTilesEnabledProvider);
    final mapState = ref.watch(mapProvider);
    final location = mapState.asData?.value;
    final businessState = ref.watch(businessesStreamProvider);
    final topBarHeight = _readWidgetHeight(topNavigationBarKey, fallback: 68);
    final isWide = MediaQuery.of(context).size.width > 600;

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
      key: const ValueKey('mapScreen'),
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
                checkMinZoom(camera.zoom);
                await _persistMapAndSheetState();
              },
            ),
            children: [
              if (mapTilesEnabled && hasMapboxConfig)
                TileLayer(
                  urlTemplate:
                      'https://api.mapbox.com/styles/v1/$myUsername/$currentStyleId/tiles/256/{z}/{x}/{y}@2x?access_token=$myAccessToken',
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
                  key: Key(currentStyleId),
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
                              _openBusinessSheet(business);
                            },
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
                      } else if (!_isMarkerHidden) {
                        return Marker(
                          height: 12,
                          width: 12,
                          rotate: true,
                          point: LatLng(business.latitude, business.longitude),
                          child: GestureDetector(
                            onTap: () {
                              _openBusinessSheet(business);
                            },
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
                  padding: const EdgeInsets.only(bottom: 90, left: 10),
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
                      _MapControlButton(
                        icon: Icons.add,
                        onPressed: () async {
                          final double currentZoom =
                              _animatedMapController.mapController.camera.zoom;

                          _animatedMapController.animateTo(
                            zoom: currentZoom + 1,
                            duration: Durations.short4,
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      _MapControlButton(
                        icon: Icons.remove,
                        onPressed: () async {
                          final double currentZoom =
                              _animatedMapController.mapController.camera.zoom;

                          _animatedMapController.animateTo(
                            zoom: currentZoom - 1,
                            duration: Durations.short4,
                          );
                        },
                      ),
                      SizedBox(height: 12),
                      _MapControlButton(
                        icon: Icons.my_location_rounded,
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
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                ],
              ),
              SizedBox(height: 100),
            ],
          ),
          OurnegoFloatingSheet(
            controller: _floatingSheetController,
            collapsedHeight: _collapsedHeight,
            expandedHeight: _expandedHeight,
            maxWidth: isWide ? 600 : double.infinity,
            bottomOffset: 96.0,
            sideStackTop:
                MediaQuery.of(context).padding.top + topBarHeight + 10,
            onFavorite: _onFavorite,
            onContact: _onContact,
            onCatalog: _onCatalog,
            onReviews: _onReviews,
            onShare: _onShare,
          ),
        ],
      ),
    );
  }

  Future<bool> _onFavorite(SheetBusinessData business) async {
    if (business.id.isEmpty) {
      return false;
    }

    final previousIsFavorite = !business.isFavorite;

    final result = await ref
        .read(businessFavoritesUsecaseProvider)
        .toggleFavorite(business.id, previousIsFavorite);

    return result.fold(
      (failure) {
        if (failure is AuthenticationRequiredFailure) {
          if (context.mounted) {
            context.push(AuthRoutes.authSelection);
          }
          return false;
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            OurnegoSnackbars.info('No se pudo actualizar favorito'),
          );
        }
        return false;
      },
      (_) {
        ref.invalidate(isBusinessFavoriteStreamProvider(business.id));
        return true;
      },
    );
  }

  Future<void> _onContact(SheetBusinessData business) async {
    if (business.phoneNumber == null) {
      if (!context.mounted) return;
      showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return OurnegoAlertDialog(
            title: 'Sin teléfono disponible',
            content:
                'Lamentablemente, este negocio no cuenta con número de teléfono :(',
            actionLabel: 'Entiendo',
            onAction: () => Navigator.of(dialogContext).pop(),
          );
        },
      );
      return;
    }

    final uri = Uri.parse('https://wa.me/${business.phoneNumber}');
    await launchUrl(uri);
  }

  void _onCatalog(SheetBusinessData business) {
    ScaffoldMessenger.of(context).showSnackBar(
      OurnegoSnackbars.info(
        'Catálogo de ${business.name} próximamente disponible',
      ),
    );
  }

  void _onReviews(SheetBusinessData business) {
    ScaffoldMessenger.of(context).showSnackBar(
      OurnegoSnackbars.info(
        'Reseñas de ${business.name} próximamente disponibles',
      ),
    );
  }

  Future<void> _onShare(SheetBusinessData business) async {
    if (business.id.isEmpty) {
      return;
    }

    await Share.share(negocioDeepLinkUrl(business.id), subject: business.name);
  }
}

class _MapControlButton extends StatefulWidget {
  final IconData icon;
  final Future<void> Function() onPressed;

  const _MapControlButton({required this.icon, required this.onPressed});

  @override
  State<_MapControlButton> createState() => _MapControlButtonState();
}

class _MapControlButtonState extends State<_MapControlButton> {
  bool _isPressed = false;

  Future<void> _handleTap() async {
    if (!mounted) return;

    setState(() {
      _isPressed = true;
    });

    await widget.onPressed();

    if (!mounted) return;

    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedScale(
      duration: const Duration(milliseconds: 140),
      scale: _isPressed ? 0.94 : 1,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Material(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          elevation: 5,
          shadowColor: Colors.black.withValues(alpha: 0.2),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _handleTap,
            child: Icon(widget.icon, size: 22, color: colorScheme.onSurface),
          ),
        ),
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
