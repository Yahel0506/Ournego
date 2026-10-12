import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/geocoding/locationiq_geocoding_datasource.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/core/network/network_error_classifier.dart';
import 'package:ournego/features/map/data/datasources/local_manual_zone_datasource.dart';
import 'package:ournego/features/map/data/models/manual_zone_model.dart';
import 'package:ournego/features/map/domain/entities/manual_zone.dart';
import 'package:ournego/features/map/domain/repositories/manual_zone_repository.dart';

class ManualZoneRepositoryImpl implements ManualZoneRepository {
  static const minQueryLength = 3;
  static const unnamedZoneLabel = 'Zona seleccionada en el mapa';

  final LocationIqGeocodingDatasource geocodingDatasource;
  final LocalManualZoneDatasource localDatasource;

  ManualZoneRepositoryImpl({
    required this.geocodingDatasource,
    required this.localDatasource,
  });

  @override
  Future<Either<Failure, List<ManualZone>>> searchZones(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < minQueryLength) {
      return const Right(<ManualZone>[]);
    }

    try {
      final suggestions = await geocodingDatasource.getAddressSuggestions(
        trimmed,
      );
      final zones = <ManualZone>[];
      final seenLabels = <String>{};
      for (final suggestion in suggestions) {
        final label = _labelFromSuggestion(suggestion);
        if (label.isEmpty || !seenLabels.add(label)) continue;
        zones.add(
          ManualZone(
            position: AppPosition(
              latitude: (suggestion['lat'] as num).toDouble(),
              longitude: (suggestion['lon'] as num).toDouble(),
            ),
            label: label,
          ),
        );
      }
      return Right(zones);
    } catch (error) {
      return Left(isNetworkError(error) ? NetworkFailure() : ServerFailure());
    }
  }

  @override
  Future<ManualZone> resolveZoneFromPoint(AppPosition position) async {
    String? label;
    try {
      final address = await geocodingDatasource.reverse(
        latitude: position.latitude,
        longitude: position.longitude,
      );
      label = _labelFromAddress(address);
    } catch (_) {
      // Offline or unknown place: the point itself is still a valid zone.
    }

    return ManualZone(
      position: AppPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
      label: label ?? unnamedZoneLabel,
    );
  }

  @override
  Future<Either<Failure, ManualZone?>> getSavedZone() async {
    try {
      return Right(await localDatasource.load());
    } catch (_) {
      return Left(LocalFailure());
    }
  }

  @override
  Future<Either<Failure, void>> saveZone(ManualZone zone) async {
    try {
      await localDatasource.save(ManualZoneModel.fromZone(zone));
      return const Right(null);
    } catch (_) {
      return Left(LocalFailure());
    }
  }

  @override
  Future<Either<Failure, void>> clearSavedZone() async {
    try {
      await localDatasource.clear();
      return const Right(null);
    } catch (_) {
      return Left(LocalFailure());
    }
  }

  String _labelFromSuggestion(Map<String, dynamic> suggestion) {
    String part(String key) => (suggestion[key] as String? ?? '').trim();

    final name = part('name');
    final city = part('city');
    final parts = <String>[
      if (name.isNotEmpty) name,
      // Skip the city when the name already says it ("Mi Centro Ciudad Guzmán").
      if (city.isNotEmpty && !name.contains(city)) city,
    ];
    if (parts.isEmpty) {
      final state = part('state');
      if (state.isNotEmpty) parts.add(state);
    }
    return parts.join(', ');
  }

  String? _labelFromAddress(Map<String, dynamic> address) {
    String? value(String key) {
      final raw = (address[key] as String?)?.trim();
      return (raw == null || raw.isEmpty) ? null : raw;
    }

    final area =
        value('suburb') ??
        value('neighbourhood') ??
        value('quarter') ??
        value('city_district');
    final town =
        value('city') ?? value('town') ?? value('village') ?? value('county');

    if (area != null && town != null && area != town) return '$area, $town';
    return area ?? town;
  }
}
