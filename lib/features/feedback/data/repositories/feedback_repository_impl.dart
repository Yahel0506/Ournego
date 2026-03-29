import 'dart:io';

import 'package:dartz/dartz.dart';
import 'package:flutter/cupertino.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/feedback/data/datasources/feedback_datasource.dart';
import 'package:ournego/features/feedback/domain/repositories/feedback_repository.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackDatasource datasource;

  FeedbackRepositoryImpl({required this.datasource});

  @override
  Future<Either<Failure, bool>> sendFeedback({
    required String message,
    required String model,
    required String os,
    required File attachment,
  }) async {
    try {
      await datasource.sendFeedback(
        message: message,
        model: model,
        os: os,
        attachment: attachment,
      );
      return Right(true);
    } catch (e) {
      debugPrint('Error sending feedback: ${e.toString()}');
      return Left(ServerFailure());
    }
  }
}
