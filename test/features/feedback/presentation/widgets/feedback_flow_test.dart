import 'package:dartz/dartz.dart';
import 'package:feedback/feedback.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';
import 'package:ournego/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:ournego/features/feedback/domain/usecases/send_feedback_usecase.dart';
import 'package:ournego/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_flow.dart';
import 'package:ournego/features/navigation/presentation/providers/navigation_provider.dart';

class _FakeFeedbackRepository implements FeedbackRepository {
  @override
  Future<Either<Failure, bool>> sendFeedback(FeedbackReport report) async {
    return const Right(true);
  }
}

void main() {
  late ProviderContainer container;

  Future<void> pump(
    WidgetTester tester, {
    required Future<void> Function(BuildContext, WidgetRef) onOpen,
  }) async {
    // The information dialog is taller than the default 600 px test surface.
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: BetterFeedback(
          child: MaterialApp(
            theme: OurnegoTheme.light,
            home: Consumer(
              builder: (context, ref, _) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => onOpen(context, ref),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  setUp(() {
    container = ProviderContainer(
      overrides: [
        sendFeedbackUsecaseProvider.overrideWith(
          (ref) => SendFeedbackUsecase(repository: _FakeFeedbackRepository()),
        ),
      ],
    );
  });
  tearDown(() => container.dispose());

  testWidgets('the error dialog offers feedback and a way to dismiss', (
    tester,
  ) async {
    await pump(
      tester,
      onOpen: (context, ref) => showErrorWithFeedbackDialog(
        context,
        ref,
        title: 'Algo falló',
        description: 'Detalle del error',
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Algo falló'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);

    await tester.tap(find.text('Entiendo'));
    await tester.pumpAndSettle();
    expect(find.text('Algo falló'), findsNothing);
    expect(find.byType(FeedbackDialogWidget), findsNothing);
  });

  testWidgets('"Feedback" closes the error and opens the feedback dialog', (
    tester,
  ) async {
    await pump(
      tester,
      onOpen: (context, ref) => showErrorWithFeedbackDialog(
        context,
        ref,
        title: 'Algo falló',
        description: 'Detalle del error',
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Feedback'));
    await tester.pumpAndSettle();

    expect(find.text('Algo falló'), findsNothing);
    expect(find.byType(FeedbackDialogWidget), findsOneWidget);
    expect(container.read(isFeedbackDialogOpenProvider), isTrue);
  });

  testWidgets('a second request while one is open does not stack a dialog', (
    tester,
  ) async {
    late BuildContext hostContext;
    late WidgetRef hostRef;
    await pump(
      tester,
      onOpen: (context, ref) {
        hostContext = context;
        hostRef = ref;
        return openFeedbackDialog(context, ref);
      },
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackDialogWidget), findsOneWidget);

    await openFeedbackDialog(hostContext, hostRef);
    await tester.pumpAndSettle();
    expect(find.byType(FeedbackDialogWidget), findsOneWidget);
  });

  testWidgets('the open flag is cleared when the dialog is dismissed', (
    tester,
  ) async {
    await pump(tester, onOpen: openFeedbackDialog);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(container.read(isFeedbackDialogOpenProvider), isTrue);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(FeedbackDialogWidget), findsNothing);
    expect(container.read(isFeedbackDialogOpenProvider), isFalse);
  });

  testWidgets('the session error uses the shared copy', (tester) async {
    await pump(tester, onOpen: showSessionErrorDialog);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('No se pudo verificar tu sesion'), findsOneWidget);
  });
}
