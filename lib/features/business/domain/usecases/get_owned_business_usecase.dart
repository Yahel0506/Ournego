import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class GetOwnedBusinessUsecase {
  final BusinessRepository repository;

  GetOwnedBusinessUsecase({required this.repository});

  Future<Either<Failure, OwnedBusinessProfile?>> call() async {
    return repository.getOwnedBusiness();
  }
}
