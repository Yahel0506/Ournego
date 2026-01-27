import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class CheckIfOwnerUsecase {
  final BusinessRepository repository;

  CheckIfOwnerUsecase({required this.repository});

  Future<Either<Failure, bool>> call() async {
    return await repository.checkIfOwner();
  }
}
