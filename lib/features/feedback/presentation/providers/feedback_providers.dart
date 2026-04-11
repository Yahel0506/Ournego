import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ournego/features/feedback/data/datasources/feedback_datasource.dart';
import 'package:ournego/features/feedback/data/repositories/feedback_repository_impl.dart';
import 'package:ournego/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:ournego/features/feedback/domain/usecases/send_feedback_usecase.dart';

final feedbackDatasourceProvider = Provider<FeedbackDatasource>((ref) {
  return FeedbackDatasource();
});

final feedbackRepositoryProvider = Provider<FeedbackRepository>((ref) {
  return FeedbackRepositoryImpl(
    datasource: ref.watch(feedbackDatasourceProvider),
  );
});

final sendFeedbackUsecaseProvider = Provider<SendFeedbackUsecase>((ref) {
  final repository = ref.watch(feedbackRepositoryProvider);
  return SendFeedbackUsecase(repository: repository);
});
