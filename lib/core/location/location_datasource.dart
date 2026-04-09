import 'package:ournego/core/location/app_position.dart';

abstract class LocationDatasource {
  Future<AppPosition> getCurrentLocation({
    bool requestPermissionIfNeeded = true,
  });
}
