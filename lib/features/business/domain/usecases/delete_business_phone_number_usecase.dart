import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class DeleteBusinessPhoneNumberUsecase {
  final BusinessRepository repository;

  DeleteBusinessPhoneNumberUsecase({required this.repository});

  Future<Either<Failure, void>> call({required String businessId}) async {
    return repository.deleteBusinessPhoneNumber(businessId: businessId);
  }
}
