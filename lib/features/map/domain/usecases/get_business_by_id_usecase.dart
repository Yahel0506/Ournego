import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

class GetBusinessByIdUsecase {
  final MapRepository repository;

  GetBusinessByIdUsecase({required this.repository});

  Future<Either<Failure, Business?>> call(String businessId) {
    return repository.getBusinessById(businessId);
  }
}
