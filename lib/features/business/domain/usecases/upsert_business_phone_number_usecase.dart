import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class UpsertBusinessPhoneNumberUsecase {
  final BusinessRepository repository;

  UpsertBusinessPhoneNumberUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required String phoneNumber,
  }) async {
    return repository.upsertBusinessPhoneNumber(
      businessId: businessId,
      phoneNumber: phoneNumber,
    );
  }
}
