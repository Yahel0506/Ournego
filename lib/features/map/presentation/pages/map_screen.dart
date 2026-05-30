import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/mapbox_config.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/routing/route_names.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
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
import 'package:ournego/features/map/presentation/widgets/map_controls_widget.dart';
import 'package:ournego/features/map/presentation/widgets/map_search_overlay_widget.dart';
import 'package:ournego/features/map/presentation/widgets/top_navigation_bar_widget.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';
import 'package:ournego/shared/widgets/information_card_widget.dart';
import 'package:ournego/shared/widgets/nego/nego.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_content_container.dart';
import 'package:ournego/shared/widgets/ournego_information_dialog.dart';
import 'package:ournego/shared/widgets/ournego_snackbars.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MapScreen extends ConsumerStatefulWidget {
  final String? initialBusinessId;

  const MapScreen({super.key, this.initialBusinessId});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  static const double _sheetBottomOffset = 96;
  static const double _sheetTopGap = 12;
  static const double _searchPanelGap = 12;

  late final _animatedMapController = AnimatedMapController(vsync: this);
  late final AnimationController _searchPanelAnimationController;
  late final Animation<double> _searchPanelOpacity;
  late final Animation<Offset> _searchPanelSlide;
  late ProviderSubscription<AsyncValue<AppPosition>> _providerSubscription;
  late ProviderSubscription<MapVoiceSearchState> _voiceSubscription;
  late final FloatingSheetController _floatingSheetController;
  late final MapViewController _viewController;

  final _businessMarkerUiMapper = BusinessMarkerUiMapper();
  final _searchBusinessesUsecase = const SearchBusinessesUsecase();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  bool _isLocationModalOpen = false;
  bool _isSearchPanelVisible = false;
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

  Future<void> _showSessionErrorDialog() {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return OurnegoInformationDialog(
          title: 'No se pudo verificar tu sesion',
          description:
              'Intenta de nuevo en unos segundos. Si el problema continua, envianos feedback.',
          imagePath: 'assets/images/generic_error.png',
          actions: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    Navigator.of(dialogContext).pop();
                    if (ref.read(isFeedbackDialogOpenProvider)) {
                      return;
                    }
                    ref.read(isFeedbackDialogOpenProvider.notifier).setIsOpen();
                    await showDialog<void>(
                      context: context,
                      builder: (_) => const FeedbackDialogWidget(),
                    );
                    ref
                        .read(isFeedbackDialogOpenProvider.notifier)
                        .setIsClosed();
                  },
                  child: const Text('Feedback'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Entiendo'),
                ),
              ),
            ],
          ),
        );
      },
    );
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
      await _showSessionErrorDialog();
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

    _providerSubscription = ref.listenManual<AsyncValue<AppPosition>>(
      mapProvider,
      (previous, next) {
        next.whenOrNull(
          data: (data) {
            if (_viewController.initialCenter == null) {
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
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    final location = mapState.asData?.value;
    final businessState = ref.watch(businessesStreamProvider);
    final searchResults = _searchBusinessesUsecase(
      businesses: businessState.asData?.value ?? const <Business>[],
      query: _searchQuery,
      filters: _searchFilters,
      now: DateTime.now(),
      userLatitude: location?.latitude,
      userLongitude: location?.longitude,
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

    return Scaffold(
      key: const ValueKey('mapScreen'),
      resizeToAvoidBottomInset: false,
      body: Stack(
        alignment: Alignment.topCenter,
        children: [
          MapCanvasWidget(
            animatedMapController: _animatedMapController,
            initialCenter:
                _viewController.initialCenter ??
                LatLng(19.7000112, -103.4654738),
            initialZoom: _viewController.initialZoom ?? 12,
            mapTilesEnabled: mapTilesEnabled,
            hasMapboxConfig: hasMapboxConfig,
            isDarkModeOn: isDarkModeOn,
            mapboxUsername: myUsername,
            mapboxStyleId: currentStyleId,
            mapboxAccessToken: myAccessToken,
            location: location,
            businessState: businessState,
            isMarkerVisible: _isMarkerVisible,
            isMarkerHidden: _isMarkerHidden,
            onCameraChanged: (zoom) async {
              checkMinZoom(zoom);
              await _persistMapAndSheetState();
            },
            onBusinessTap: (business) {
              _viewController.openBusinessSheet(business, source: 'map');
            },
            markerUiMapper: _businessMarkerUiMapper.call,
          ),
          if (!_showSearchPanel && isOwnerState.value == false)
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
              _syncSearchPanelVisibility();
              await ref.read(mapVoiceSearchProvider.notifier).toggleListening();
            },
            onSearchTap: () {
              if (!mounted) return;
              _syncSearchPanelVisibility();
            },
            onSearchChanged: (value) {
              if (!mounted) return;
              setState(() {
                _searchQuery = value;
              });
              _syncSearchPanelVisibility();
            },
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

  Future<void> _handleMyLocationTap() async {
    final currentLocation = ref.read(mapProvider).asData?.value;
    if (currentLocation != null) {
      _animatedMapController.animateTo(
        dest: LatLng(currentLocation.latitude, currentLocation.longitude),
        zoom: 15,
        rotation: 0,
      );
      return;
    }

    await _retryLocationRequest(requestPermissionIfNeeded: true);

    final refreshedState = ref.read(mapProvider);
    final refreshedLocation = refreshedState.asData?.value;
    if (refreshedLocation != null) {
      _animatedMapController.animateTo(
        dest: LatLng(refreshedLocation.latitude, refreshedLocation.longitude),
        zoom: 15,
        rotation: 0,
      );
      return;
    }

    final locationError = refreshedState.asError?.error;
    if (locationError != null) {
      await _showLocationErrorSheet(locationError);
    }
  }

  void _closeSearchOverlay() {
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
        _searchFocusNode.hasFocus || _searchQuery.trim().isNotEmpty;
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
    _syncSearchPanelVisibility();
  }
}
