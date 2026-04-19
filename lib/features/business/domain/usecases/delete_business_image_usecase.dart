import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class DeleteBusinessImageUsecase {
  final BusinessRepository repository;

  DeleteBusinessImageUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required String imageUrl,
  }) async {
    return repository.deleteBusinessImage(
      businessId: businessId,
      imageUrl: imageUrl,
    );
  }
}
