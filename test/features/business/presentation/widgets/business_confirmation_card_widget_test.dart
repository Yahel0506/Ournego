import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/business/presentation/widgets/business_confirmation_card_widget.dart';

import '../../../../fakes/fake_business_confirmation_repository.dart';

void main() {
  const title = '¿Conoces este negocio?';

  Future<void> pump(
    WidgetTester tester,
    FakeBusinessConfirmationRepository repository, {
    String? userId = 'user-1',
    String ownerId = 'owner-1',
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => userId),
          businessConfirmationRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: OurnegoTheme.light,
          home: Scaffold(
            body: BusinessConfirmationCardWidget(
              businessId: 'b1',
              ownerId: ownerId,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('shows the question with the three answers', (tester) async {
    await pump(tester, FakeBusinessConfirmationRepository());
    expect(find.text(title), findsOneWidget);
    expect(find.text('Sí, lo conozco'), findsOneWidget);
    expect(find.text('No existe / no es real'), findsOneWidget);
    expect(find.text('No estoy seguro'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('is hidden for the owner and for guests', (tester) async {
    await pump(tester, FakeBusinessConfirmationRepository(), userId: 'owner-1');
    expect(find.text(title), findsNothing);

    await pump(tester, FakeBusinessConfirmationRepository(), userId: null);
    expect(find.text(title), findsNothing);
  });

  testWidgets('is hidden when the server already holds an answer', (
    tester,
  ) async {
    await pump(
      tester,
      FakeBusinessConfirmationRepository(
        answers: {'b1': BusinessConfirmationAnswer.unsure},
      ),
    );
    expect(find.text(title), findsNothing);
  });

  for (final entry in {
    'Sí, lo conozco': BusinessConfirmationAnswer.yes,
    'No existe / no es real': BusinessConfirmationAnswer.noExists,
    'No estoy seguro': BusinessConfirmationAnswer.unsure,
  }.entries) {
    testWidgets('answering "${entry.key}" sends it and hides the card', (
      tester,
    ) async {
      final repository = FakeBusinessConfirmationRepository();
      await pump(tester, repository);

      await tester.tap(find.text(entry.key));
      await tester.pump();
      await tester.pump();

      expect(repository.submitted, [entry.value]);
      expect(find.text(title), findsNothing);
    });
  }

  testWidgets('a failed answer keeps the card and shows a retry message', (
    tester,
  ) async {
    final repository = FakeBusinessConfirmationRepository(failNextSubmit: true);
    await pump(tester, repository);

    await tester.tap(find.text('Sí, lo conozco'));
    await tester.pump();
    await tester.pump();

    expect(find.text(title), findsOneWidget);
    expect(find.textContaining('No se pudo enviar'), findsOneWidget);
    expect(repository.answers, isEmpty);
  });
}
