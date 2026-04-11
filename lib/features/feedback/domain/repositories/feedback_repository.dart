import 'package:dartz/dartz.dart';
import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';

import '../../../../core/failures.dart';

abstract class FeedbackRepository {
  Future<Either<Failure, bool>> sendFeedback(FeedbackReport report);
}
