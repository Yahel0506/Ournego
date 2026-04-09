import 'package:dartz/dartz.dart';
import 'package:ournego/core/location/app_position.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

import '../../../../core/failures.dart';

class GetAddressesSuggestionsUsecase {
  final BusinessRepository repository;

  GetAddressesSuggestionsUsecase({required this.repository});

  Future<Either<Failure, List<AppPosition>>> call(String query) async {
    return repository.getAddressesSuggestions(query);
  }
}
