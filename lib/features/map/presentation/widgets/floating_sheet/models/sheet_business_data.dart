import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';

class SheetBusinessData {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String address;
  final String? phoneNumber;
  final BusinessType type;
  final bool isFavorite;
  final double? rating;
  final List<String> images;

  const SheetBusinessData({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.address,
    required this.phoneNumber,
    required this.type,
    this.isFavorite = false,
    this.rating,
    required this.images,
  });

  factory SheetBusinessData.fromBusiness(
    Business business, {
    bool isFavorite = false,
    double? rating,
  }) {
    return SheetBusinessData(
      id: business.id,
      name: business.name,
      description: business.description,
      ownerId: business.ownerId,
      address: business.address,
      phoneNumber: business.phoneNumber,
      type: business.type,
      isFavorite: isFavorite,
      rating: rating,
      images: business.images,
    );
  }

  SheetBusinessData copyWith({bool? isFavorite, double? rating}) {
    return SheetBusinessData(
      id: id,
      name: name,
      description: description,
      ownerId: ownerId,
      address: address,
      phoneNumber: phoneNumber,
      type: type,
      isFavorite: isFavorite ?? this.isFavorite,
      rating: rating ?? this.rating,
      images: images,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'address': address,
      'phoneNumber': phoneNumber,
      'type': type.index,
      'isFavorite': isFavorite,
      'rating': rating,
      'images': images,
    };
  }

  factory SheetBusinessData.fromJson(Map<String, dynamic> json) {
    final rawTypeIndex = json['type'] as int?;
    final type =
        rawTypeIndex != null &&
            rawTypeIndex >= 0 &&
            rawTypeIndex < BusinessType.values.length
        ? BusinessType.values[rawTypeIndex]
        : BusinessType.unknown;

    final rawImages = json['images'] as List<dynamic>? ?? [];
    final images = rawImages.map((e) => e as String).toList(growable: false);

    return SheetBusinessData(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      ownerId: json['ownerId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      type: type,
      isFavorite: json['isFavorite'] as bool? ?? false,
      rating: (json['rating'] as num?)?.toDouble(),
      images: images,
    );
  }
}
