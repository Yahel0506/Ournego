import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/features/map/data/models/manual_zone_model.dart';

class LocalManualZoneDatasource {
  static const manualZoneKey = 'map_manual_zone';

  /// Returns null when nothing is saved or the stored value is unreadable.
  Future<ManualZoneModel?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(manualZoneKey);
    if (raw == null) return null;

    try {
      return ManualZoneModel.fromJson(json.decode(raw) as Map<String, dynamic>);
    } catch (_) {
      await prefs.remove(manualZoneKey);
      return null;
    }
  }

  Future<void> save(ManualZoneModel zone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(manualZoneKey, json.encode(zone.toJson()));
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(manualZoneKey);
  }
}
