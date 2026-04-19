import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class UpsertBusinessCategoryUsecase {
  final BusinessRepository repository;

  UpsertBusinessCategoryUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required int category,
  }) async {
    return repository.upsertBusinessCategory(
      businessId: businessId,
      category: category,
    );
  }
}
