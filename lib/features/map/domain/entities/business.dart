import 'package:ournego/features/map/domain/entities/business_type.dart';

class Business {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String address;
  final int? phoneNumber;
  final double latitude;
  final double longitude;
  final BusinessType type;
  final List<String> images;
  final bool isFavorite = false;

  Business({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.address,
    required this.phoneNumber,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.images,
  });
}
