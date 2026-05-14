import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/business/domain/entities/business_panel_metrics.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';

class GetBusinessPanelMetricsUsecase {
  final BusinessRepository repository;

  GetBusinessPanelMetricsUsecase({required this.repository});

  Future<Either<Failure, BusinessPanelMetrics>> call({
    required String businessId,
  }) {
    return repository.getBusinessPanelMetrics(businessId: businessId);
  }
}
