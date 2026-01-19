import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';

import '../repositories/map_repository.dart';

class BusinessFavoritesUsecase {
  final MapRepository repository;

  BusinessFavoritesUsecase({required this.repository});

  Future<Either<Failure, void>> toggleFavorite(String businessId, bool isFavorite) async {
    if (isFavorite) {
      return repository.removeBusinessFromFavorites(businessId);
    } else {
      return repository.addBusinessToFavorites(businessId);
    }
  }

  Stream<bool> isFavorite(String businessId) {
    return repository.isBusinessFavorite(businessId);
  }
}