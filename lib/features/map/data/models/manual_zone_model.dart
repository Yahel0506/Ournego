import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';

class ManualZoneModel extends ManualZone {
  const ManualZoneModel({required super.position, required super.label});

  factory ManualZoneModel.fromZone(ManualZone zone) {
    return ManualZoneModel(position: zone.position, label: zone.label);
  }

  factory ManualZoneModel.fromJson(Map<String, dynamic> json) {
    return ManualZoneModel(
      position: AppPosition(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
      ),
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'latitude': position.latitude,
    'longitude': position.longitude,
    'label': label,
  };
}
