import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:ournego/core/feedback/domain/repositories/feedback_repository.dart';

import '../../../failures.dart';

class SendFeedbackUsecase {
  final FeedbackRepository repository;

  SendFeedbackUsecase({required this.repository});

  Future<Either<Failure, bool>> call({
    required String message,
    required String model,
    required String os,
    required File attachment,
  }) async {
    return await repository.sendFeedback(
      message: message,
      model: model,
      os: os,
      attachment: attachment,
    );
  }
}
