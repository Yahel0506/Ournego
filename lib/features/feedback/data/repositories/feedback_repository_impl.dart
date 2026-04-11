import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/feedback/data/datasources/feedback_datasource.dart';
import 'package:ournego/features/feedback/data/models/feedback_report_model.dart';
import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';
import 'package:ournego/features/feedback/domain/repositories/feedback_repository.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackDatasource datasource;

  FeedbackRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, bool>> sendFeedback(FeedbackReport report) async {
    try {
      final model = FeedbackReportModel.fromEntity(report);
      await datasource.sendFeedback(model);
      return const Right(true);
    } catch (e) {
      debugPrint('Error sending feedback: ${e.toString()}');
      return Left(ServerFailure());
    }
  }
}
