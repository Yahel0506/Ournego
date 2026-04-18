import 'package:dartz/dartz.dart';
import 'package:ournego/features/business/domain/entities/business_image_data.dart';

import '../../../../core/failures.dart';
import '../entities/app_schedule.dart';
import '../repositories/business_repository.dart';

class RegisterBusinessUsecase {
  final BusinessRepository repository;

  RegisterBusinessUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String name,
    required String description,
    required int category,
    required String address,
    required double latitude,
    required double longitude,
    required BusinessImageData image,
    required String phoneNumber,
    required List<AppSchedule> hours,
  }) async {
    return await repository.registerBusiness(
      name: name,
      description: description,
      category: category,
      address: address,
      latitude: latitude,
      longitude: longitude,
      image: image,
      phoneNumber: phoneNumber,
      hours: hours,
    );
  }
}
