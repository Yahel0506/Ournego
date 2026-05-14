import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class UpsertBusinessHoursUsecase {
  final BusinessRepository repository;

  UpsertBusinessHoursUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required List<AppSchedule> hours,
  }) async {
    return repository.upsertBusinessHours(businessId: businessId, hours: hours);
  }
}
