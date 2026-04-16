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
}
