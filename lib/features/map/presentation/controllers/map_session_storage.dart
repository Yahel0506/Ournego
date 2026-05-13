import 'dart:convert';

import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_state.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

class MapCameraState {
  final LatLng? center;
  final double? zoom;
  final bool isMarkerVisible;
  final bool isMarkerHidden;

  const MapCameraState({
    required this.center,
    required this.zoom,
    required this.isMarkerVisible,
    required this.isMarkerHidden,
  });
}

class MapSheetStateSnapshot {
  final FloatingSheetState state;
  final SheetBusinessData? activeBusiness;
  final SheetBusinessData? comparisonBusiness;
  final List<SheetBusinessData> minimizedBusinesses;

  const MapSheetStateSnapshot({
    required this.state,
    required this.activeBusiness,
    required this.comparisonBusiness,
    required this.minimizedBusinesses,
  });
}

class MapSessionStorage {
  static const lastLatitudeKey = 'map_last_latitude';
  static const lastLongitudeKey = 'map_last_longitude';
  static const lastZoomKey = 'map_last_zoom';
  static const markerVisibleKey = 'map_marker_visible';
  static const markerHiddenKey = 'map_marker_hidden';
  static const sheetStateKey = 'map_sheet_state';
  static const sheetActiveBusinessKey = 'map_sheet_active_business';
  static const sheetComparisonBusinessKey = 'map_sheet_comparison_business';
  static const sheetMinimizedListKey = 'map_sheet_minimized_list';

  Future<MapCameraState> loadCameraState() async {
    final prefs = await SharedPreferences.getInstance();
    final lastLatitude = prefs.getDouble(lastLatitudeKey);
    final lastLongitude = prefs.getDouble(lastLongitudeKey);
    final lastZoom = prefs.getDouble(lastZoomKey);

    final center = (lastLatitude != null && lastLongitude != null)
        ? LatLng(lastLatitude, lastLongitude)
        : null;

    return MapCameraState(
      center: center,
      zoom: lastZoom,
      isMarkerVisible: prefs.getBool(markerVisibleKey) ?? true,
      isMarkerHidden: prefs.getBool(markerHiddenKey) ?? false,
    );
  }

  Future<void> saveCameraState({
    required LatLng center,
    required double zoom,
    required bool isMarkerVisible,
    required bool isMarkerHidden,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(lastLatitudeKey, center.latitude);
    await prefs.setDouble(lastLongitudeKey, center.longitude);
    await prefs.setDouble(lastZoomKey, zoom);
    await prefs.setBool(markerVisibleKey, isMarkerVisible);
    await prefs.setBool(markerHiddenKey, isMarkerHidden);
  }

  Future<MapSheetStateSnapshot?> loadSheetState() async {
    final prefs = await SharedPreferences.getInstance();
    final rawState = prefs.getString(sheetStateKey);
    final rawActiveBusiness = prefs.getString(sheetActiveBusinessKey);
    final rawComparisonBusiness = prefs.getString(sheetComparisonBusinessKey);
    final rawMinimizedList = prefs.getString(sheetMinimizedListKey);

    if (rawState == null &&
        rawActiveBusiness == null &&
        rawComparisonBusiness == null &&
        rawMinimizedList == null) {
      return null;
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

    return MapSheetStateSnapshot(
      state: FloatingSheetStateCodec.fromStorageValue(rawState ?? 'collapsed'),
      activeBusiness: parseBusiness(rawActiveBusiness),
      comparisonBusiness: parseBusiness(rawComparisonBusiness),
      minimizedBusinesses: parseMinimized(rawMinimizedList),
    );
  }

  Future<void> saveSheetState({
    required FloatingSheetState state,
    required SheetBusinessData? activeBusiness,
    required SheetBusinessData? comparisonBusiness,
    required List<SheetBusinessData> minimizedBusinesses,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sheetStateKey, state.storageValue);

    if (activeBusiness != null) {
      await prefs.setString(
        sheetActiveBusinessKey,
        jsonEncode(activeBusiness.toJson()),
      );
    } else {
      await prefs.remove(sheetActiveBusinessKey);
    }

    if (comparisonBusiness != null) {
      await prefs.setString(
        sheetComparisonBusinessKey,
        jsonEncode(comparisonBusiness.toJson()),
      );
    } else {
      await prefs.remove(sheetComparisonBusinessKey);
    }

    if (minimizedBusinesses.isNotEmpty) {
      final encoded = minimizedBusinesses.map((b) => b.toJson()).toList();
      await prefs.setString(sheetMinimizedListKey, jsonEncode(encoded));
    } else {
      await prefs.remove(sheetMinimizedListKey);
    }
  }
}
