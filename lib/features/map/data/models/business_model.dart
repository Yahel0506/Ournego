import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';

class BusinessModel extends Business {
  BusinessModel({
    required super.id,
    required super.name,
    required super.description,
    required super.ownerId,
    required super.address,
    required super.phoneNumber,
    required super.latitude,
    required super.longitude,
    required super.type,
    required super.images,
  });

  factory BusinessModel.fromSupabase(Map<String, dynamic> data) {
    final rawImagesList = data['images'] as List<dynamic>;
    final List<String> images = rawImagesList.map((rawImage) {
      final image = rawImage as String;
      return image;
    }).toList();

    final BusinessType type =
        (data['type'] >= 0 && data['type'] < BusinessType.values.length)
        ? BusinessType.values[data['type']]
        : BusinessType.unknown;

    return BusinessModel(
      id: data['business_id'],
      name: data['name'],
      description: data['description'],
      ownerId: data['owner_id'],
      address: data['address'],
      phoneNumber: data['phone_number'],
      latitude: data['latitude'],
      longitude: data['longitude'],
      type: type,
      images: images,
    );
  }
}
