import 'package:dartz/dartz.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:latlong2/latlong.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/presentation/controllers/map_session_storage.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_controller.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

typedef GetBusinessById =
    Future<Either<Failure, Business?>> Function(String businessId);
typedef IsFavoriteSnapshot = bool Function(String businessId);
typedef MissingBusinessReporter = void Function();
typedef TrackBusinessVisit =
    Future<void> Function({required String businessId, required String source});

class MapViewController {
  final AnimatedMapController animatedMapController;
  final FloatingSheetController floatingSheetController;
  final MapSessionStorage sessionStorage;
  final GetBusinessById getBusinessById;
  final IsFavoriteSnapshot isFavoriteSnapshot;
  final MissingBusinessReporter onMissingBusiness;
  final TrackBusinessVisit trackBusinessVisit;

  LatLng? _initialCenter;
  double? _initialZoom;
  String? _pendingDeepLinkBusinessId;
  bool _didReportMissingDeepLinkBusiness = false;
  bool _isResolvingDeepLink = false;

  MapViewController({
    required this.animatedMapController,
    required this.floatingSheetController,
    required this.sessionStorage,
    required this.getBusinessById,
    required this.isFavoriteSnapshot,
    required this.onMissingBusiness,
    required this.trackBusinessVisit,
    String? initialBusinessId,
  }) : _pendingDeepLinkBusinessId = initialBusinessId;

  LatLng? get initialCenter => _initialCenter;
  double? get initialZoom => _initialZoom;
  String? get pendingDeepLinkBusinessId => _pendingDeepLinkBusinessId;

  void updateDeepLinkBusinessId(String? businessId) {
    _pendingDeepLinkBusinessId = businessId;
    _didReportMissingDeepLinkBusiness = false;
  }

  Future<MapCameraState> restoreCameraState() async {
    final cameraState = await sessionStorage.loadCameraState();
    _initialCenter = cameraState.center;
    _initialZoom = cameraState.zoom;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_initialCenter != null) {
        animatedMapController.animateTo(
          dest: _initialCenter,
          zoom: _initialZoom ?? 15,
        );
      }
    });

    return cameraState;
  }

  Future<void> restoreSheetStateFromPrefs() async {
    if (_pendingDeepLinkBusinessId != null) {
      return;
    }

    final snapshot = await sessionStorage.loadSheetState();
    if (snapshot == null) {
      return;
    }

    floatingSheetController.restoreState(
      state: snapshot.state,
      activeBusiness: snapshot.activeBusiness,
      comparisonBusiness: snapshot.comparisonBusiness,
      minimizedBusinesses: snapshot.minimizedBusinesses,
    );
  }

  Future<void> persistMapAndSheetState({
    required bool isMarkerVisible,
    required bool isMarkerHidden,
  }) async {
    final camera = animatedMapController.mapController.camera;

    await sessionStorage.saveCameraState(
      center: camera.center,
      zoom: camera.zoom,
      isMarkerVisible: isMarkerVisible,
      isMarkerHidden: isMarkerHidden,
    );

    await sessionStorage.saveSheetState(
      state: floatingSheetController.state,
      activeBusiness: floatingSheetController.activeBusiness,
      comparisonBusiness: floatingSheetController.comparisonBusiness,
      minimizedBusinesses: floatingSheetController.minimizedBusinesses,
    );
  }

  void openBusinessSheet(
    Business business, {
    bool animateToBusiness = true,
    String source = 'map',
  }) {
    if (floatingSheetController.isComparisonMode) {
      return;
    }

    final isFavorite = isFavoriteSnapshot(business.id);
    floatingSheetController.openBusiness(
      SheetBusinessData.fromBusiness(business, isFavorite: isFavorite),
    );

    if (animateToBusiness) {
      animatedMapController.animateTo(
        dest: LatLng(business.latitude, business.longitude),
        zoom: 18,
      );
    }

    trackBusinessVisit(businessId: business.id, source: source);
  }

  Future<void> resolveDeepLinkBusiness() async {
    final targetId = _pendingDeepLinkBusinessId;
    if (targetId == null || targetId.isEmpty || _isResolvingDeepLink) {
      return;
    }

    _isResolvingDeepLink = true;
    final result = await getBusinessById(targetId);

    result.fold(
      (_) {
        _reportMissingDeepLinkBusiness();
      },
      (business) {
        if (business == null) {
          _reportMissingDeepLinkBusiness();
          return;
        }

        _pendingDeepLinkBusinessId = null;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          openBusinessSheet(business, source: 'deeplink');
        });
      },
    );

    _isResolvingDeepLink = false;
  }

  void _reportMissingDeepLinkBusiness() {
    if (_didReportMissingDeepLinkBusiness) {
      return;
    }

    _didReportMissingDeepLinkBusiness = true;
    _pendingDeepLinkBusinessId = null;
    onMissingBusiness();
  }
}
