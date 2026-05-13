import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';

class MapSearchFilters {
  final bool onlyOpenNow;
  final BusinessType? category;
  final double? maxDistanceMeters;

  const MapSearchFilters({
    this.onlyOpenNow = false,
    this.category,
    this.maxDistanceMeters,
  });

  MapSearchFilters copyWith({
    bool? onlyOpenNow,
    BusinessType? category,
    bool clearCategory = false,
    double? maxDistanceMeters,
    bool clearMaxDistanceMeters = false,
  }) {
    return MapSearchFilters(
      onlyOpenNow: onlyOpenNow ?? this.onlyOpenNow,
      category: clearCategory ? null : (category ?? this.category),
      maxDistanceMeters: clearMaxDistanceMeters
          ? null
          : (maxDistanceMeters ?? this.maxDistanceMeters),
    );
  }
}

class MapSearchResult {
  final Business? business;
  final BusinessType? category;
  final double? distanceMeters;
  final BusinessOpenState openState;

  const MapSearchResult.business(
    this.business, {
    required this.distanceMeters,
    required this.openState,
  }) : category = null;

  const MapSearchResult.category(this.category)
    : business = null,
      distanceMeters = null,
      openState = BusinessOpenState.unknown;

  bool get isCategory => category != null;
}

enum BusinessOpenState { open, closed, unknown }
