import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class UpsertBusinessLocationUsecase {
  final BusinessRepository repository;

  UpsertBusinessLocationUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required String address,
    required double latitude,
    required double longitude,
  }) async {
    return repository.upsertBusinessLocation(
      businessId: businessId,
      address: address,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
