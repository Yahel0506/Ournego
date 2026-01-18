import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/map/domain/entities/app_position.dart';

class LastPositionNotifier extends Notifier<AppPosition> {
  @override
  AppPosition build() {
    return AppPosition(latitude: 0, longitude: -88);
  }
}
