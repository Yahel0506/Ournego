import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/auth/data/datasources/supabase_auth_datasource.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/auth/presentation/providers/session_expiry_providers.dart';

class _FakeDatasource implements SupabaseAuthDatasource {
  bool userInitiated = false;

  @override
  bool consumeUserInitiatedSignOut() {
    final value = userInitiated;
    userInitiated = false;
    return value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late StreamController<AuthState> events;
  late _FakeDatasource datasource;

  ProviderContainer build({required bool hasSession}) {
    final container = ProviderContainer(
      overrides: [
        authEventsProvider.overrideWithValue(events.stream),
        hasActiveSessionReaderProvider.overrideWithValue(() => hasSession),
        supabaseAuthDatasourceProvider.overrideWithValue(datasource),
      ],
    );
    addTearDown(container.dispose);
    container.listen(sessionExpiryProvider, (_, _) {});
    return container;
  }

  setUp(() {
    events = StreamController<AuthState>.broadcast();
    datasource = _FakeDatasource();
    addTearDown(events.close);
  });

  test('signedOut without user action marks the session expired', () async {
    final container = build(hasSession: true);
    events.add(AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionExpiryProvider), SessionExpiryStatus.expired);
  });

  test('user-initiated logout is not an expiry', () async {
    final container = build(hasSession: true);
    datasource.userInitiated = true;
    events.add(AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionExpiryProvider), SessionExpiryStatus.none);
  });

  test('guests signing out of nothing do not trigger the dialog', () async {
    final container = build(hasSession: false);
    events.add(AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    expect(container.read(sessionExpiryProvider), SessionExpiryStatus.none);
  });

  test('acknowledge resets the state', () async {
    final container = build(hasSession: true);
    events.add(AuthState(AuthChangeEvent.signedOut, null));
    await Future<void>.delayed(Duration.zero);
    container.read(sessionExpiryProvider.notifier).acknowledge();
    expect(container.read(sessionExpiryProvider), SessionExpiryStatus.none);
  });
}
