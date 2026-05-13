import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/map/domain/repositories/map_repository.dart';

class TrackBusinessVisitUsecase {
  final MapRepository repository;

  TrackBusinessVisitUsecase({required this.repository});

  Future<Either<Failure, void>> call({
    required String businessId,
    required String source,
  }) {
    return repository.trackBusinessVisit(
      businessId: businessId,
      source: source,
    );
  }
}
