import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

class GetBusinessesUsecase {
  final MapRepository repository;

  GetBusinessesUsecase({required this.repository});

  Stream<List<Business>> call() {
    return repository.getBusinesses();
  }
}
