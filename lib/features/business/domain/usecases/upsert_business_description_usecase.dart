import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class UpsertBusinessDescriptionUsecase {
  final BusinessRepository repository;

  UpsertBusinessDescriptionUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required String description,
  }) async {
    return repository.upsertBusinessDescription(
      businessId: businessId,
      description: description,
    );
  }
}
