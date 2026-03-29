import 'dart:io';

import 'package:dartz/dartz.dart';

import '../../../../core/failures.dart';

abstract class FeedbackRepository {
  Future<Either<Failure, bool>> sendFeedback({
    required String message,
    required String model,
    required String os,
    required File attachment,
  });
}
