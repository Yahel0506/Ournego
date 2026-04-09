import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/location/app_position.dart';

class LastPositionNotifier extends Notifier<AppPosition> {
  @override
  AppPosition build() {
    return AppPosition(latitude: 0, longitude: -88);
  }
}
