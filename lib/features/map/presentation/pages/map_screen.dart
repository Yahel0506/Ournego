import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/core/mapbox_config.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_flow.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/domain/entities/map_location_state.dart';
import 'package:ournego/features/map/domain/entities/reference_location.dart';
import 'package:ournego/features/map/presentation/controllers/map_session_storage.dart';
import 'package:ournego/features/map/presentation/controllers/map_view_controller.dart';
import 'package:ournego/features/map/presentation/controllers/search_businesses_usecase.dart';
import 'package:ournego/features/map/presentation/mappers/business_marker_ui_mapper.dart';
import 'package:ournego/features/map/presentation/models/map_search_models.dart';
import 'package:ournego/features/map/presentation/providers/map_providers.dart';
import 'package:ournego/features/map/presentation/providers/notifiers/map_voice_search_notifier.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_controller.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_state.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/ournego_floating_sheet.dart';
import 'package:ournego/features/map/presentation/widgets/map_canvas_widget.dart';
import 'package:ournego/features/map/presentation/widgets/location_access_sheet_widget.dart';
import 'package:ournego/features/map/presentation/widgets/map_controls_widget.dart';
import 'package:ournego/features/map/presentation/widgets/map_location_banner_widget.dart';
import 'package:ournego/features/map/presentation/widgets/map_search_overlay_widget.dart';
import 'package:ournego/features/map/presentation/widgets/top_navigation_bar_widget.dart';
import 'package:ournego/features/map/presentation/widgets/zone_picker_sheet_widget.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? initialBusinessId;

  const MapScreen({super.key, this.initialBusinessId});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  static const double _sheetBottomOffset = 96;
  static const double _sheetTopGap = 12;
  static const double _searchPanelGap = 12;

  late final _animatedMapController = AnimatedMapController(vsync: this);
  late final AnimationController _searchPanelAnimationController;
  late final Animation<double> _searchPanelOpacity;
  late final Animation<Offset> _searchPanelSlide;
  late ProviderSubscription<AsyncValue<MapLocationState>> _providerSubscription;
  late ProviderSubscription<MapVoiceSearchState> _voiceSubscription;
  late final FloatingSheetController _floatingSheetController;
  late final MapViewController _viewController;

  final _businessMarkerUiMapper = BusinessMarkerUiMapper();
  final _searchBusinessesUsecase = const SearchBusinessesUsecase();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  /// Keeps keyboard focus inside the screen after the search field lets go of
  /// it, so Esc still reaches [_handleBackOrEscape].
  final _keysFocusNode = FocusNode(
    debugLabel: 'mapScreenKeys',
    skipTraversal: true,
  );

  bool _isLocationModalOpen = false;
  bool _isZonePickerOpen = false;
  bool _isSearchPanelVisible = false;

  /// The user dismissed the panel (back, Esc, tap on the map) but the query
  /// stays in the bar. Cleared as soon as they interact with the bar again.
  bool _isSearchPanelDismissed = false;
  String _searchQuery = '';
  MapSearchFilters _searchFilters = const MapSearchFilters();

  double get _expandedHeight {
    final mq = MediaQuery.of(context);
    final screenHeight = mq.size.height;
    final maxHeight =
        screenHeight - _topNavigationHeight - _sheetBottomOffset - _sheetTopGap;

    return maxHeight.clamp(220.0, screenHeight);
  }

  double get _collapsedHeight {
    final screenHeight = MediaQuery.of(context).size.height;
    final collapsed = screenHeight * 0.24;
    return collapsed.clamp(160.0, _expandedHeight);
  }

  double get _topNavigationHeight {
    return _readWidgetHeight(topNavigationBarKey, fallback: 68);
  }

  double get _currentSheetHeight {
    if (!_floatingSheetController.hasActiveBusiness) {
      return 0;
    }

    if (_floatingSheetController.isComparisonMode ||
        _floatingSheetController.state == FloatingSheetState.expanded) {
      return _expandedHeight;
    }

    if (_floatingSheetController.state == FloatingSheetState.collapsed) {
      return _collapsedHeight;
    }

    return 0;
  }

  double get _searchPanelBottomInset {
    final sheetHeight = _currentSheetHeight;
    if (sheetHeight <= 0) {
      return 12;
    }

    return _sheetBottomOffset + sheetHeight + _searchPanelGap;
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

  Future<void> _persistMapAndSheetState() async {
    await _viewController.persistMapAndSheetState(
      isMarkerVisible: _isMarkerVisible,
      isMarkerHidden: _isMarkerHidden,
    );
  }

  bool _isMarkerVisible = true;
  bool _isMarkerHidden = false;

  bool get _showSearchPanel {
    return _isSearchPanelVisible;
  }

  static const List<double> _distanceOptionsMeters = <double>[1000, 3000, 7000];
  static const List<BusinessType> _searchCategoryOptions = <BusinessType>[
    BusinessType.drinkAndEat,
    BusinessType.shop,
    BusinessType.personalService,
    BusinessType.professionalService,
    BusinessType.healthAndWellness,
    BusinessType.education,
    BusinessType.constructionAndHome,
    BusinessType.transportation,
    BusinessType.entertainment,
    BusinessType.technology,
    BusinessType.informalBusiness,
    BusinessType.mixed,
  ];

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

  void _onLocationStatusChanged(LocationAccessStatus status) {
    if (!mounted) {
      return;
    }

    switch (status) {
      case LocationAccessStatus.permissionDenied ||
          LocationAccessStatus.permissionDeniedForever:
        _showLocationAccessSheet(status);
      case LocationAccessStatus.serviceDisabled:
        // Native "turn on location" dialog; if declined, the banner remains.
        // Skipped when the system already offered it during this outage.
        if (ref.read(mapProvider).asData?.value.serviceDialogOffered != true) {
          ref.read(mapProvider.notifier).enableLocationService();
        }
      case LocationAccessStatus.granted || LocationAccessStatus.unavailable:
        break;
    }
  }

  /// Opens Nego's explanation sheet and runs what the user picked. Only one
  /// location sheet can be open at a time.
  Future<void> _showLocationAccessSheet(LocationAccessStatus status) async {
    if (_isLocationModalOpen || !mounted) {
      return;
    }

    _isLocationModalOpen = true;
    final action = await showLocationAccessSheet(context, status: status);
    _isLocationModalOpen = false;

    if (!mounted) {
      return;
    }

    switch (action) {
      case LocationAccessSheetAction.allow:
        await ref.read(mapProvider.notifier).requestPermission();
      case LocationAccessSheetAction.chooseZone:
        await _openZonePicker();
      case LocationAccessSheetAction.openSettings:
        await Geolocator.openAppSettings();
      case LocationAccessSheetAction.continueWithoutLocation || null:
        break;
    }
  }

  AppPosition _mapCenterOrReference() {
    try {
      final center = _animatedMapController.mapController.camera.center;
      return AppPosition(
        latitude: center.latitude,
        longitude: center.longitude,
      );
    } catch (_) {
      // The map is not attached yet: fall back to the current reference.
      return (ref.read(mapProvider).asData?.value.reference ??
              ReferenceLocation.defaultZone)
          .position;
    }
  }

  Future<void> _openZonePicker() async {
    if (_isZonePickerOpen || !mounted) {
      return;
    }

    _isZonePickerOpen = true;
    final result = await showZonePickerSheet(
      context,
      mapCenter: _mapCenterOrReference(),
      currentZone: ref.read(mapProvider).asData?.value.manualZone,
    );
    _isZonePickerOpen = false;

    if (!mounted || result == null) {
      return;
    }

    final notifier = ref.read(mapProvider.notifier);
    switch (result) {
      case ZonePicked(:final zone):
        await notifier.setManualZone(zone);
        _moveCameraTo(zone.position);
      case ZoneCleared():
        await notifier.clearManualZone();
        _moveCameraTo(ReferenceLocation.defaultZone.position);
    }
  }

  void _moveCameraTo(AppPosition position) {
    try {
      _animatedMapController.animateTo(
        dest: LatLng(position.latitude, position.longitude),
        zoom: 15,
        rotation: 0,
      );
    } catch (_) {
      // The map is not attached yet; the initial center will be used.
    }
  }

  Future<void> _onLocationBannerAction() async {
    final status = ref.read(mapProvider).asData?.value.status;
    switch (status) {
      case LocationAccessStatus.permissionDenied:
        await ref.read(mapProvider.notifier).requestPermission();
      case LocationAccessStatus.permissionDeniedForever:
        await Geolocator.openAppSettings();
      case LocationAccessStatus.serviceDisabled:
        await ref.read(mapProvider.notifier).enableLocationService();
      case LocationAccessStatus.granted ||
          LocationAccessStatus.unavailable ||
          null:
        break;
    }
  }

  Future<void> _onRegisterBusinessTap() async {
    try {
      final isLogged = ref.read(authSessionStatusProvider);
      if (!context.mounted) return;

      if (isLogged) {
        context.push(BusinessRoutes.form);
      } else {
        context.push(AuthRoutes.authSelection);
      }
    } catch (_) {
      if (!context.mounted) return;
      await showSessionErrorDialog(context, ref);
    }
  }

  @override
  void initState() {
    super.initState();
    _searchPanelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
      reverseDuration: const Duration(milliseconds: 220),
    );
    _searchPanelOpacity = CurvedAnimation(
      parent: _searchPanelAnimationController,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _searchPanelSlide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(_searchPanelOpacity);

    _floatingSheetController = FloatingSheetController();
    _viewController = MapViewController(
      animatedMapController: _animatedMapController,
      floatingSheetController: _floatingSheetController,
      sessionStorage: MapSessionStorage(),
      initialBusinessId: widget.initialBusinessId,
      getBusinessById: (businessId) {
        final usecase = ref.read(getBusinessByIdUsecaseProvider);
        return usecase(businessId);
      },
      isFavoriteSnapshot: (businessId) {
        final favoriteAsync = ref.read(
          isBusinessFavoriteStreamProvider(businessId),
        );
        return favoriteAsync.value ?? false;
      },
      onMissingBusiness: () {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          OurnegoSnackbars.info('No encontramos el negocio solicitado'),
        );
      },
      trackBusinessVisit: ({required businessId, required source}) async {
        final usecase = ref.read(trackBusinessVisitUsecaseProvider);
        await usecase(businessId: businessId, source: source);
      },
    );
    _floatingSheetController.addListener(_persistMapAndSheetState);

    WidgetsBinding.instance.addObserver(this);
    _providerSubscription = ref.listenManual<AsyncValue<MapLocationState>>(
      mapProvider,
      (previous, next) {
        final previousState = previous?.asData?.value;
        final nextState = next.asData?.value;
        if (nextState == null) {
          return;
        }

        final reference = nextState.reference;
        final referenceChanged =
            previousState?.reference.position.latitude !=
                reference.position.latitude ||
            previousState?.reference.position.longitude !=
                reference.position.longitude;
        if (_viewController.initialCenter == null &&
            referenceChanged &&
            reference.source != ReferenceLocationSource.defaultZone) {
          _animatedMapController.animateTo(
            dest: LatLng(
              reference.position.latitude,
              reference.position.longitude,
            ),
            zoom: 15,
          );
        }

        if (nextState.status != previousState?.status) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _onLocationStatusChanged(nextState.status);
          });
        }
      },
    );
    _voiceSubscription = ref.listenManual<MapVoiceSearchState>(
      mapVoiceSearchProvider,
      (previous, next) {
        if (!mounted) {
          return;
        }
        if (previous?.eventId == next.eventId) {
          return;
        }

        if (next.errorMessage != null && next.errorMessage!.isNotEmpty) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(OurnegoSnackbars.info(next.errorMessage!));
          return;
        }

        if (previous?.isListening != next.isListening) {
          if (next.isListening) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              OurnegoSnackbars.info('Escuchando... habla para buscar.'),
            );
          } else {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          }
        }

        if (next.transcript.trim().isNotEmpty) {
          _applyVoiceTranscript(next.transcript);
        }
      },
    );

    _viewController.resolveDeepLinkBusiness();
    _viewController.restoreCameraState().then((cameraState) {
      if (!mounted) return;
      setState(() {
        _isMarkerVisible = cameraState.isMarkerVisible;
        _isMarkerHidden = cameraState.isMarkerHidden;
      });
    });
    _viewController.restoreSheetStateFromPrefs();
    _searchFocusNode.addListener(() {
      if (!mounted) return;
      if (_searchFocusNode.hasFocus) {
        _isSearchPanelDismissed = false;
      }
      _syncSearchPanelVisibility();
    });
  }

  @override
  void didUpdateWidget(covariant MapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialBusinessId == widget.initialBusinessId) {
      return;
    }

    _viewController.updateDeepLinkBusinessId(widget.initialBusinessId);
    _viewController.resolveDeepLinkBusiness();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _keysFocusNode.dispose();
    _searchPanelAnimationController.dispose();
    _floatingSheetController.removeListener(_persistMapAndSheetState);
    _animatedMapController.dispose();
    _providerSubscription.close();
    _voiceSubscription.close();
    _floatingSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mapTilesEnabled = ref.watch(mapTilesEnabledProvider);
    final mapState = ref.watch(mapProvider);
    final locationState = mapState.asData?.value;
    final location = locationState?.gpsPosition;
    final reference = locationState?.reference ?? ReferenceLocation.defaultZone;
    final showLocationBanner =
        !_showSearchPanel && locationStatusNeedsBanner(locationState?.status);
    final showZoneChip =
        !_showSearchPanel && locationState != null && !reference.isGps;
    final businessState = ref.watch(businessesStreamProvider);
    final searchResults = _searchBusinessesUsecase(
      businesses: businessState.asData?.value ?? const <Business>[],
      query: _searchQuery,
      filters: _searchFilters,
      now: DateTime.now(),
      userLatitude: reference.position.latitude,
      userLongitude: reference.position.longitude,
    );
    final voiceState = ref.watch(mapVoiceSearchProvider);
    final isOwnerState = ref.watch(isOwnerProvider);
    final topBarHeight = _topNavigationHeight;
    final isWide = MediaQuery.of(context).size.width > 600;

    final bool isDarkModeOn =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    // In tests (and in some environments), MapboxConfig may be uninitialized.
    // Only read it when tiles are actually enabled.
    final String myAccessToken = mapTilesEnabled
        ? MapboxConfig.accessToken
        : '';
    final String myUsername = mapTilesEnabled ? MapboxConfig.username : '';
    final String styleIdDark = mapTilesEnabled ? MapboxConfig.styleIdDark : '';
    final String styleIdLight = mapTilesEnabled
        ? MapboxConfig.styleIdLight
        : '';

    final String currentStyleId = isDarkModeOn ? styleIdDark : styleIdLight;
    final bool hasMapboxConfig =
        mapTilesEnabled &&
        myAccessToken.isNotEmpty &&
        myUsername.isNotEmpty &&
        currentStyleId.isNotEmpty;

    final scaffold = Scaffold(
      key: const ValueKey('mapScreen'),
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          MapCanvasWidget(
            animatedMapController: _animatedMapController,
            initialCenter:
                _viewController.initialCenter ??
                LatLng(
                  ReferenceLocation.defaultZone.position.latitude,
                  ReferenceLocation.defaultZone.position.longitude,
                ),
            initialZoom: _viewController.initialZoom ?? 12,
            mapTilesEnabled: mapTilesEnabled,
            hasMapboxConfig: hasMapboxConfig,
            isDarkModeOn: isDarkModeOn,
            mapboxUsername: myUsername,
            mapboxStyleId: currentStyleId,
            mapboxAccessToken: myAccessToken,
            location: location,
            businessState: businessState,
            onRetryBusinesses: () => ref.invalidate(businessesStreamProvider),
            isMarkerVisible: _isMarkerVisible,
            isMarkerHidden: _isMarkerHidden,
            onCameraChanged: (zoom) async {
              checkMinZoom(zoom);
              await _persistMapAndSheetState();
            },
            onBusinessTap: (business) {
              _viewController.openBusinessSheet(business, source: 'map');
            },
            onMapTap: () {
              if (_isSearchPanelVisible) _dismissSearchPanel();
            },
            markerUiMapper: _businessMarkerUiMapper.call,
          ),
          if (!_showSearchPanel &&
              !showLocationBanner &&
              !showZoneChip &&
              isOwnerState.value == false)
            Positioned(
              top: topBarHeight + 8,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: _onRegisterBusinessTap,
                child: OurnegoContentContainer(
                  hasBlur: true,
                  customHorizontalPadding: 16,
                  customVerticalPadding: 12,
                  borderRadius: 20,
                  child: Row(
                    children: [
                      const NegoAvatar(
                        size: 36,
                        mood: NegoMood.excited,
                        interactive: false,
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Text(
                          'Registra tu negocio y crece.',
                          style: OurnegoTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (showLocationBanner || showZoneChip)
            Positioned(
              top: topBarHeight + 8,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showLocationBanner)
                    MapLocationBanner(
                      status: locationState!.status,
                      onAction: _onLocationBannerAction,
                    ),
                  if (showLocationBanner && showZoneChip)
                    const SizedBox(height: 8),
                  if (showZoneChip)
                    OurnegoGlassChip(
                      key: const Key('zone-chip'),
                      label: 'Zona: ${reference.label}',
                      actionLabel: 'Cambiar',
                      semanticLabel: 'Zona: ${reference.label}. Cambiar',
                      onPressed: _openZonePicker,
                    ),
                ],
              ),
            ),
          Positioned.fill(
            child: IgnorePointer(
              ignoring: !_showSearchPanel,
              child: FadeTransition(
                opacity: _searchPanelOpacity,
                child: SlideTransition(
                  position: _searchPanelSlide,
                  child: MapSearchOverlayWidget(
                    results: searchResults,
                    query: _searchQuery,
                    hasData: businessState.hasValue,
                    location: location,
                    referenceLabel: reference.isGps ? null : reference.label,
                    topBarHeight: topBarHeight,
                    bottomInset: _searchPanelBottomInset,
                    filters: _searchFilters,
                    categoryOptions: _searchCategoryOptions,
                    distanceOptionsMeters: _distanceOptionsMeters,
                    onClear: _clearSearchState,
                    onClose: _closeSearchOverlay,
                    onOpenNowChanged: (selected) {
                      setState(() {
                        _searchFilters = _searchFilters.copyWith(
                          onlyOpenNow: selected,
                        );
                      });
                    },
                    onCategoryChanged: (category) {
                      setState(() {
                        _searchFilters = _searchFilters.copyWith(
                          category: category,
                          clearCategory: category == null,
                        );
                      });
                    },
                    onDistanceChanged: (distance) {
                      setState(() {
                        _searchFilters = _searchFilters.copyWith(
                          maxDistanceMeters: distance,
                          clearMaxDistanceMeters: distance == null,
                        );
                      });
                    },
                    onBusinessSelected: (business) {
                      _searchController.text = business.name;
                      _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: _searchController.text.length),
                      );
                      _viewController.openBusinessSheet(
                        business,
                        source: 'search',
                      );
                      _closeSearchOverlay();
                    },
                  ),
                ),
              ),
            ),
          ),

          if (!_showSearchPanel)
            Column(
              children: [
                Spacer(),
                Row(
                  children: [
                    Spacer(),
                    MapControlsWidget(
                      showDebugButton: kDebugMode,
                      onDebugTap: () async {
                        context.go(DebuggingRoutes.debugPanel);
                      },
                      onZoomInTap: () async {
                        final currentZoom =
                            _animatedMapController.mapController.camera.zoom;
                        _animatedMapController.animateTo(
                          zoom: currentZoom + 1,
                          duration: Durations.short4,
                        );
                      },
                      onZoomOutTap: () async {
                        final currentZoom =
                            _animatedMapController.mapController.camera.zoom;
                        _animatedMapController.animateTo(
                          zoom: currentZoom - 1,
                          duration: Durations.short4,
                        );
                      },
                      onMyLocationTap: _handleMyLocationTap,
                      hasLocationAccess:
                          locationState?.gpsPosition != null ||
                          !locationStatusNeedsBanner(locationState?.status),
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
            bottomOffset: _sheetBottomOffset,
            sideStackTop: topBarHeight + 10,
            onFavorite: _onFavorite,
            onContact: _onContact,
            onCatalog: _onCatalog,
            onReviews: _onReviews,
            onShare: _onShare,
          ),
          TopNavigationBarWidget(
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            isVoiceListening: voiceState.isListening,
            onVoiceSearchTap: () async {
              if (!_searchFocusNode.hasFocus) {
                _searchFocusNode.requestFocus();
              }
              _revealSearchPanel();
              await ref.read(mapVoiceSearchProvider.notifier).toggleListening();
            },
            onSearchTap: () {
              if (!mounted) return;
              _revealSearchPanel();
            },
            onSearchChanged: (value) {
              if (!mounted) return;
              setState(() {
                _searchQuery = value;
              });
              _revealSearchPanel();
            },
          ),
        ],
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): _handleBackOrEscape,
      },
      child: Focus(
        focusNode: _keysFocusNode,
        autofocus: true,
        child: ListenableBuilder(
          listenable: _floatingSheetController,
          child: scaffold,
          builder: (context, child) => PopScope(
            canPop:
                !_isSearchPanelVisible &&
                !_floatingSheetController.canHandleBack,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) _handleBackOrEscape();
            },
            child: child!,
          ),
        ),
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
      showOurnegoDialog<void>(
        context: context,
        builder: (dialogContext) {
          return OurnegoAlertDialog(
            title: 'Sin teléfono disponible',
            content:
                'Lamentablemente, este negocio no cuenta con número de teléfono :(',
            primaryAction: OurnegoDialogAction(
              label: 'Entiendo',
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
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

  void _centerOnLocation(AppPosition position) {
    _animatedMapController.animateTo(
      dest: LatLng(position.latitude, position.longitude),
      zoom: 15,
      rotation: 0,
    );
  }

  Future<void> _handleMyLocationTap() async {
    final notifier = ref.read(mapProvider.notifier);
    final current = ref.read(mapProvider).asData?.value;

    final gps = current?.gpsPosition;
    if (gps != null) {
      _centerOnLocation(gps);
      return;
    }

    switch (current?.status) {
      case LocationAccessStatus.permissionDenied ||
          LocationAccessStatus.permissionDeniedForever:
        await _showLocationAccessSheet(current!.status);
        return;
      case LocationAccessStatus.serviceDisabled:
        await notifier.enableLocationService();
      case LocationAccessStatus.granted ||
          LocationAccessStatus.unavailable ||
          null:
        await notifier.recheck();
    }

    if (!mounted) {
      return;
    }
    final refreshed = ref.read(mapProvider).asData?.value.gpsPosition;
    if (refreshed != null) {
      _centerOnLocation(refreshed);
      return;
    }

    final status = ref.read(mapProvider).asData?.value.status;
    if (status == LocationAccessStatus.unavailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        OurnegoSnackbars.info(
          'No pudimos obtener tu ubicación. Inténtalo de nuevo.',
        ),
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(mapProvider.notifier).recheck();
    }
  }

  /// Back and Esc step back one level: the search panel first, then the sheet.
  void _handleBackOrEscape() {
    if (_isSearchPanelVisible) {
      _dismissSearchPanel();
      return;
    }
    _floatingSheetController.handleBack();
  }

  /// Hides the panel but keeps the query in the bar. Focusing or editing the
  /// bar again brings the same results back.
  void _dismissSearchPanel() {
    _isSearchPanelDismissed = true;
    if (_searchFocusNode.hasFocus) {
      _keysFocusNode.requestFocus();
    }
    _syncSearchPanelVisibility();
  }

  void _revealSearchPanel() {
    _isSearchPanelDismissed = false;
    _syncSearchPanelVisibility();
  }

  /// The close button: hides the panel and clears the query.
  void _closeSearchOverlay() {
    _isSearchPanelDismissed = false;
    _searchFocusNode.unfocus();
    setState(() {
      _searchQuery = '';
      _searchController.clear();
    });
    _syncSearchPanelVisibility();
  }

  void _clearSearchState() {
    setState(() {
      _searchFilters = const MapSearchFilters();
      _searchQuery = '';
      _searchController.clear();
    });
    _syncSearchPanelVisibility();
  }

  void _syncSearchPanelVisibility() {
    final shouldShow =
        !_isSearchPanelDismissed &&
        (_searchFocusNode.hasFocus || _searchQuery.trim().isNotEmpty);
    if (shouldShow == _isSearchPanelVisible) {
      return;
    }

    setState(() {
      _isSearchPanelVisible = shouldShow;
    });

    if (shouldShow) {
      _searchPanelAnimationController.forward();
    } else {
      _searchPanelAnimationController.reverse();
    }
  }

  void _applyVoiceTranscript(String transcript) {
    _searchController.text = transcript;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
    if (!_searchFocusNode.hasFocus) {
      _searchFocusNode.requestFocus();
    }
    setState(() {
      _searchQuery = transcript;
    });
    _revealSearchPanel();
  }
}
