import 'dart:io';

import 'package:dartz/dartz.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';
import 'package:ournego/features/feedback/domain/repositories/feedback_repository.dart';

class SendFeedbackUsecase {
  final FeedbackRepository repository;

  SendFeedbackUsecase({required this.repository});

  Future<Either<Failure, bool>> call({
    required String message,
    required String model,
    required String os,
    required File attachment,
  }) async {
    final report = FeedbackReport(
      message: message,
      model: model,
      os: os,
      attachment: attachment,
    );

    return await repository.sendFeedback(report);
  }
}
