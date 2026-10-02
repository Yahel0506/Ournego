import 'package:dartz/dartz.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';
import 'package:ournego/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:ournego/features/feedback/domain/usecases/send_feedback_usecase.dart';
import 'package:ournego/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';

class _FakeFeedbackRepository implements FeedbackRepository {
  @override
  Future<Either<Failure, bool>> sendFeedback(FeedbackReport report) async {
    return const Right(true);
  }
}

void main() {
  testWidgets('opens feedback after its dialog route is disposed', (
    tester,
  ) async {
    late FeedbackController feedbackController;

    await tester.pumpWidget(
      BetterFeedback(
        child: ProviderScope(
          overrides: [
            sendFeedbackUsecaseProvider.overrideWith(
              (ref) =>
                  SendFeedbackUsecase(repository: _FakeFeedbackRepository()),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) {
                feedbackController = BetterFeedback.of(context);
                return Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          PageRouteBuilder<void>(
                            transitionDuration: Duration.zero,
                            reverseTransitionDuration: Duration.zero,
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const FeedbackDialogWidget(),
                          ),
                        );
                      },
                      child: const Text('Abrir feedback'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir feedback'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackDialogWidget), findsOneWidget);

    await tester.tap(find.text('Algo no funciona'));
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackDialogWidget), findsNothing);
    expect(feedbackController.isVisible, isTrue);
  });
}
