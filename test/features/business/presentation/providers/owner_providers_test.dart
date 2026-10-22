import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dartz/dartz.dart';
import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/repositories/business_repository.dart';
import 'package:ournego/features/business/domain/usecases/check_if_owner_usecase.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';

class _FakeCheckIfOwner extends CheckIfOwnerUsecase {
  _FakeCheckIfOwner(this.value) : super(repository: _NoRepo());
  final bool value;
  int calls = 0;

  @override
  Future<Either<Failure, bool>> call() async {
    calls++;
    return Right(value);
  }
}

class _NoRepo implements BusinessRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _UserId extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? v) => state = v;
}

void main() {
  test('isOwnerProvider refetches when the signed-in user changes', () async {
    final userId = NotifierProvider<_UserId, String?>(_UserId.new);
    final fake = _FakeCheckIfOwner(true);
    final container = ProviderContainer(
      overrides: [
        currentUserIdProvider.overrideWith((ref) => ref.watch(userId)),
        checkIfOwnerUsecaseProvider.overrideWithValue(fake),
      ],
    );
    addTearDown(container.dispose);

    expect(await container.read(isOwnerProvider.future), isTrue);
    expect(fake.calls, 1);

    // Logging in must not reuse the stale value.
    container.read(userId.notifier).set('user-1');
    expect(await container.read(isOwnerProvider.future), isTrue);
    expect(fake.calls, 2);
  });
}
