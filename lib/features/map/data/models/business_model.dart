import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory BusinessModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    final GeoPoint geo = data['location'];

    late final BusinessType type;

    switch (data['type']) {
      case 0:
        type = BusinessType.drinkAndEat;
      case 1:
        type = BusinessType.shop;
      case 2:
        type = BusinessType.personalService;
      case 3:
        type = BusinessType.professionalService;
      case 4:
        type = BusinessType.healthAndWellness;
      case 5:
        type = BusinessType.education;
      case 6:
        type = BusinessType.constructionAndHome;
      case 7:
        type = BusinessType.transportation;
      case 8:
        type = BusinessType.entertainment;
      case 9:
        type = BusinessType.technology;
      case 10:
        type = BusinessType.informalBusiness;
      case 11:
        type = BusinessType.mixed;
      default:
        type = BusinessType.unknown;
    }

    return BusinessModel(
      id: data['id'],
      name: data['name'],
      description: data['description'],
      ownerId: data['owner_id'],
      address: data['address'],
      phoneNumber: data['phone_number'],
      latitude: geo.latitude,
      longitude: geo.longitude,
      type: type,
      images: data['images'],
    );
  }

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
