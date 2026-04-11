import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';
import 'package:ournego/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:ournego/features/feedback/domain/usecases/send_feedback_usecase.dart';

class _FakeFeedbackRepository implements FeedbackRepository {
  FeedbackReport? capturedReport;

  @override
  Future<Either<Failure, bool>> sendFeedback(FeedbackReport report) async {
    capturedReport = report;
    return const Right(true);
  }
}

void main() {
  group('SendFeedbackUsecase', () {
    test('builds FeedbackReport and delegates to repository', () async {
      final repository = _FakeFeedbackRepository();
      final usecase = SendFeedbackUsecase(repository: repository);
      final attachment = File('/tmp/feedback.png');

      final result = await usecase(
        message: 'There is a bug',
        model: 'iPhone 16',
        os: 'iOS 19',
        attachment: attachment,
      );

      expect(result, const Right<Failure, bool>(true));
      expect(repository.capturedReport, isNotNull);
      expect(repository.capturedReport!.message, 'There is a bug');
      expect(repository.capturedReport!.model, 'iPhone 16');
      expect(repository.capturedReport!.os, 'iOS 19');
      expect(repository.capturedReport!.attachment.path, attachment.path);
    });
  });
}
