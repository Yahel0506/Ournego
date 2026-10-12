import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

/// Reads the current location permission/service state without prompting.
class CheckLocationAccessUsecase {
  final MapRepository repository;

  CheckLocationAccessUsecase({required this.repository});

  Future<LocationAccessStatus> call() => repository.checkLocationAccessStatus();
}
