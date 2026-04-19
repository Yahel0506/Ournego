import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class InsertBusinessImageUsecase {
  final BusinessRepository repository;

  InsertBusinessImageUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required BusinessImageData image,
  }) async {
    return repository.insertBusinessImage(businessId: businessId, image: image);
  }
}
