import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/entities/business_confirmation_answer.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';

import '../../../../fakes/fake_business_confirmation_repository.dart';

ProviderContainer _container(
  FakeBusinessConfirmationRepository repository, {
  String? userId = 'user-1',
}) {
  final container = ProviderContainer(
    overrides: [
      currentUserIdProvider.overrideWith((ref) => userId),
      businessConfirmationRepositoryProvider.overrideWithValue(repository),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts unanswered when the server has no row', () async {
    final container = _container(FakeBusinessConfirmationRepository());
    expect(
      await container.read(businessConfirmationProvider('b1').future),
      null,
    );
  });

  test(
    'reads the answer from the server row, not from local storage',
    () async {
      final repository = FakeBusinessConfirmationRepository(
        answers: {'b1': BusinessConfirmationAnswer.noExists},
      );
      final container = _container(repository);
      expect(
        await container.read(businessConfirmationProvider('b1').future),
        BusinessConfirmationAnswer.noExists,
      );
      expect(
        await container.read(businessConfirmationProvider('b2').future),
        null,
      );
    },
  );

  test('signed-out users never query the server', () async {
    final repository = FakeBusinessConfirmationRepository();
    final container = _container(repository, userId: null);
    expect(
      await container.read(businessConfirmationProvider('b1').future),
      null,
    );
    expect(repository.reads, 0);
  });

  test('submitting stores the answer and the state follows', () async {
    final repository = FakeBusinessConfirmationRepository();
    final container = _container(repository);
    await container.read(businessConfirmationProvider('b1').future);

    final failure = await container
        .read(businessConfirmationProvider('b1').notifier)
        .submit(BusinessConfirmationAnswer.yes);

    expect(failure, isNull);
    expect(
      container.read(businessConfirmationProvider('b1')).value,
      BusinessConfirmationAnswer.yes,
    );
    expect(repository.answers['b1'], BusinessConfirmationAnswer.yes);
  });

  test(
    'a failed submit returns the failure and keeps the question open',
    () async {
      final repository = FakeBusinessConfirmationRepository(
        failNextSubmit: true,
      );
      final container = _container(repository);
      await container.read(businessConfirmationProvider('b1').future);

      final failure = await container
          .read(businessConfirmationProvider('b1').notifier)
          .submit(BusinessConfirmationAnswer.unsure);

      expect(failure, isA<NetworkFailure>());
      expect(container.read(businessConfirmationProvider('b1')).value, isNull);
      expect(repository.answers, isEmpty);
    },
  );
}
