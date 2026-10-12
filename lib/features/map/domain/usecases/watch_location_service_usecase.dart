import 'package:ournego/features/map/domain/repositories/map_repository.dart';

/// Emits `true`/`false` whenever the device location service is toggled.
class WatchLocationServiceUsecase {
  final MapRepository repository;

  WatchLocationServiceUsecase({required this.repository});

  Stream<bool> call() => repository.watchLocationService();
}
