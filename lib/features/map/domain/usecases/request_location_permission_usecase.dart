import 'package:ournego/core/location/location_access_status.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

/// Shows the system permission dialog (when still possible) and returns the
/// resulting status.
class RequestLocationPermissionUsecase {
  final MapRepository repository;

  RequestLocationPermissionUsecase({required this.repository});

  Future<LocationAccessStatus> call() => repository.requestLocationPermission();
}
