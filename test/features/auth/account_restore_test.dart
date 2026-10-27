import 'dart:async';
import 'dart:collection';

import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/auth/domain/repositories/auth_repository.dart';
import 'package:ournego/features/auth/presentation/providers/account_restore_providers.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/auth/presentation/providers/session_expiry_providers.dart';

/// Answers `cancelMyDeletion` from a queue; `Right(false)` once it is empty.
class _FakeAuthRepository implements AuthRepository {
  final Queue<Either<Failure, bool>> results = Queue();
  int calls = 0;

  @override
  Future<Either<Failure, bool>> cancelMyDeletion() async {
    calls++;
    return results.isEmpty ? const Right(false) : results.removeFirst();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Session sessionFor(String userId) => Session(
  accessToken: 'token-$userId',
  tokenType: 'bearer',
  user: User(
    id: userId,
    appMetadata: const {},
    userMetadata: const {},
    aud: 'authenticated',
    createdAt: '2026-10-27T00:00:00Z',
  ),
);

void main() {
  late StreamController<AuthState> events;
  late _FakeAuthRepository repository;

  ProviderContainer build() {
    final container = ProviderContainer(
      overrides: [
        authEventsProvider.overrideWithValue(events.stream),
        authRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    container.listen(accountRestoreProvider, (_, _) {});
    return container;
  }

  Future<void> emit(AuthChangeEvent event, [Session? session]) async {
    events.add(AuthState(event, session));
    await Future<void>.delayed(Duration.zero);
  }

  setUp(() {
    events = StreamController<AuthState>.broadcast();
    repository = _FakeAuthRepository();
    addTearDown(events.close);
  });

  test(
    'signing in cancels a scheduled deletion and asks for the notice',
    () async {
      final container = build();
      repository.results.add(const Right(true));

      await emit(AuthChangeEvent.signedIn, sessionFor('u1'));

      expect(repository.calls, 1);
      expect(
        container.read(accountRestoreProvider),
        AccountRestoreStatus.restored,
      );
    },
  );

  test('a session restored at startup is checked too', () async {
    final container = build();
    repository.results.add(const Right(true));

    await emit(AuthChangeEvent.initialSession, sessionFor('u1'));

    expect(repository.calls, 1);
    expect(
      container.read(accountRestoreProvider),
      AccountRestoreStatus.restored,
    );
  });

  test('nothing to cancel shows nothing and is not asked again', () async {
    final container = build();

    await emit(AuthChangeEvent.initialSession, sessionFor('u1'));
    await emit(AuthChangeEvent.tokenRefreshed, sessionFor('u1'));
    await emit(AuthChangeEvent.signedIn, sessionFor('u1'));

    expect(repository.calls, 1);
    expect(container.read(accountRestoreProvider), AccountRestoreStatus.none);
  });

  test('guests without a session never call the RPC', () async {
    build();
    await emit(AuthChangeEvent.initialSession);
    expect(repository.calls, 0);
  });

  test('a network failure does not block and is retried later', () async {
    final container = build();
    repository.results
      ..add(Left(NetworkFailure()))
      ..add(const Right(true));

    await emit(AuthChangeEvent.initialSession, sessionFor('u1'));
    expect(container.read(accountRestoreProvider), AccountRestoreStatus.none);

    await emit(AuthChangeEvent.tokenRefreshed, sessionFor('u1'));
    expect(repository.calls, 2);
    expect(
      container.read(accountRestoreProvider),
      AccountRestoreStatus.restored,
    );
  });

  test('signing in again after a sign-out checks again', () async {
    // The web request revokes the sessions: the app signs out and the person
    // signs back in during the same run.
    final container = build();
    await emit(AuthChangeEvent.initialSession, sessionFor('u1'));
    await emit(AuthChangeEvent.signedOut);

    repository.results.add(const Right(true));
    await emit(AuthChangeEvent.signedIn, sessionFor('u1'));

    expect(repository.calls, 2);
    expect(
      container.read(accountRestoreProvider),
      AccountRestoreStatus.restored,
    );
  });

  test('concurrent events for the same user call the RPC once', () async {
    build();
    events
      ..add(AuthState(AuthChangeEvent.initialSession, sessionFor('u1')))
      ..add(AuthState(AuthChangeEvent.signedIn, sessionFor('u1')));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.calls, 1);
  });

  test('signing out clears a pending notice', () async {
    final container = build();
    repository.results.add(const Right(true));
    await emit(AuthChangeEvent.signedIn, sessionFor('u1'));

    await emit(AuthChangeEvent.signedOut);

    expect(container.read(accountRestoreProvider), AccountRestoreStatus.none);
  });

  test('acknowledge resets the state', () async {
    final container = build();
    repository.results.add(const Right(true));
    await emit(AuthChangeEvent.signedIn, sessionFor('u1'));

    container.read(accountRestoreProvider.notifier).acknowledge();

    expect(container.read(accountRestoreProvider), AccountRestoreStatus.none);
  });
}
