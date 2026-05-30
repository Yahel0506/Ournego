import 'package:geolocator/geolocator.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/mappers/business_hours_ui_mapper.dart';
import 'package:ournego/features/map/presentation/models/map_search_models.dart';

class SearchBusinessesUsecase {
  const SearchBusinessesUsecase();

  List<MapSearchResult> call({
    required List<Business> businesses,
    required String query,
    required MapSearchFilters filters,
    required DateTime now,
    required double? userLatitude,
    required double? userLongitude,
  }) {
    final trimmedQuery = query.trim().toLowerCase();
    if (trimmedQuery.isEmpty) {
      return const <MapSearchResult>[];
    }

    final tokens = trimmedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return const <MapSearchResult>[];
    }

    final List<_BusinessRanking> ranked = <_BusinessRanking>[];
    for (final business in businesses) {
      if (filters.category != null && business.type != filters.category) {
        continue;
      }

      final distanceMeters = _distanceMetersFromLocation(
        business: business,
        userLatitude: userLatitude,
        userLongitude: userLongitude,
      );
      if (filters.maxDistanceMeters != null && distanceMeters != null) {
        if (distanceMeters > filters.maxDistanceMeters!) {
          continue;
        }
      }

      final openState = _businessOpenState(business, now);
      if (filters.onlyOpenNow && openState != BusinessOpenState.open) {
        continue;
      }

      final name = business.name.toLowerCase();
      final description = business.description.toLowerCase();
      final address = business.address.toLowerCase();
      final category = businessTypeLabel(business.type).toLowerCase();

      double textScore = 0;
      for (final token in tokens) {
        final inName = name.contains(token);
        final inDescription = description.contains(token);
        final inAddress = address.contains(token);
        final inCategory = category.contains(token);

        if (!inName && !inDescription && !inAddress && !inCategory) {
          continue;
        }

        if (name == token) {
          textScore += 120;
        } else if (name.startsWith(token)) {
          textScore += 80;
        } else if (inName) {
          textScore += 50;
        }

        if (inCategory) {
          textScore += 32;
        }
        if (inAddress) {
          textScore += 14;
        }
        if (inDescription) {
          textScore += 8;
        }
      }

      if (textScore <= 0) {
        continue;
      }

      double distanceScore = 0;
      if (distanceMeters != null) {
        distanceScore = (3000 - distanceMeters.clamp(0, 3000)) / 60;
      }

      final visitScore = business.visitCount.clamp(0, 5000) / 12;
      final totalScore = textScore + distanceScore + visitScore;
      ranked.add(
        _BusinessRanking(
          business: business,
          totalScore: totalScore,
          distanceMeters: distanceMeters,
          openState: openState,
        ),
      );
    }

    ranked.sort((a, b) => b.totalScore.compareTo(a.totalScore));
    final categoryEntries = _matchingCategoryResults(tokens);
    final businessEntries = ranked
        .take(10)
        .map(
          (entry) => MapSearchResult.business(
            entry.business,
            distanceMeters: entry.distanceMeters,
            openState: entry.openState,
          ),
        )
        .toList(growable: false);

    return <MapSearchResult>[...categoryEntries, ...businessEntries];
  }
}

String businessTypeLabel(BusinessType type) {
  switch (type) {
    case BusinessType.drinkAndEat:
      return 'Bebida y comida';
    case BusinessType.shop:
      return 'Tienda';
    case BusinessType.personalService:
      return 'Servicio personal';
    case BusinessType.professionalService:
      return 'Servicio profesional';
    case BusinessType.healthAndWellness:
      return 'Salud y bienestar';
    case BusinessType.education:
      return 'Educacion';
    case BusinessType.constructionAndHome:
      return 'Construccion y hogar';
    case BusinessType.transportation:
      return 'Transporte';
    case BusinessType.entertainment:
      return 'Entretenimiento';
    case BusinessType.technology:
      return 'Tecnologia';
    case BusinessType.informalBusiness:
      return 'Negocio informal';
    case BusinessType.mixed:
      return 'Mezcla de categorias';
    case BusinessType.unknown:
      return 'Otro';
  }
}

List<MapSearchResult> _matchingCategoryResults(List<String> tokens) {
  final entries = <MapSearchResult>[];
  for (final type in BusinessType.values) {
    if (type == BusinessType.unknown) {
      continue;
    }
    final label = businessTypeLabel(type).toLowerCase();
    final matches = tokens.any((token) => label.contains(token));
    if (matches) {
      entries.add(MapSearchResult.category(type));
    }
  }
  return entries;
}

double? _distanceMetersFromLocation({
  required Business business,
  required double? userLatitude,
  required double? userLongitude,
}) {
  if (userLatitude == null || userLongitude == null) {
    return null;
  }

  return Geolocator.distanceBetween(
    userLatitude,
    userLongitude,
    business.latitude,
    business.longitude,
  );
}

BusinessOpenState _businessOpenState(Business business, DateTime now) {
  return getBusinessOpenState(hours: business.hours, now: now);
}

class _BusinessRanking {
  final Business business;
  final double totalScore;
  final double? distanceMeters;
  final BusinessOpenState openState;

  const _BusinessRanking({
    required this.business,
    required this.totalScore,
    required this.distanceMeters,
    required this.openState,
  });
}
