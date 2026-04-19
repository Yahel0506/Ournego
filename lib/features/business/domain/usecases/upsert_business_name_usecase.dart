import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class UpsertBusinessNameUsecase {
  final BusinessRepository repository;

  UpsertBusinessNameUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required String name,
  }) async {
    return repository.upsertBusinessName(businessId: businessId, name: name);
  }
}
