import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';

// LAYER 1: Datasources
/// Raw auth events. Overridable so tests do not need an initialized Supabase.
final authEventsProvider = Provider<Stream<AuthState>>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final hasActiveSessionReaderProvider = Provider<bool Function()>((ref) {
  return () => Supabase.instance.client.auth.currentSession != null;
});

// LAYER 4: State
enum SessionExpiryStatus { none, expired }

/// Detects sessions lost without a user-initiated logout (revoked or
/// unrefreshable tokens). Offline refresh failures are retried by the SDK and
/// never emit `signedOut`, so they do not trigger this.
class SessionExpiryNotifier extends Notifier<SessionExpiryStatus> {
  bool _hadSession = false;

  @override
  SessionExpiryStatus build() {
    _hadSession = ref.read(hasActiveSessionReaderProvider)();
    final subscription = ref.read(authEventsProvider).listen(_onEvent);
    ref.onDispose(subscription.cancel);
    return SessionExpiryStatus.none;
  }

  void _onEvent(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.tokenRefreshed:
      case AuthChangeEvent.initialSession:
        _hadSession = data.session != null;
        if (data.session != null) state = SessionExpiryStatus.none;
      case AuthChangeEvent.signedOut:
        final userInitiated = ref
            .read(supabaseAuthDatasourceProvider)
            .consumeUserInitiatedSignOut();
        final lost = _hadSession && !userInitiated;
        _hadSession = false;
        if (lost) state = SessionExpiryStatus.expired;
      default:
        break;
    }
  }

  /// Called when the user dismisses or acts on the expiry dialog.
  void acknowledge() => state = SessionExpiryStatus.none;
}

final sessionExpiryProvider =
    NotifierProvider<SessionExpiryNotifier, SessionExpiryStatus>(
      SessionExpiryNotifier.new,
    );

/// Route to return to after the user signs in again following an expiry.
class PendingReturnLocationNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? location) => state = location;

  String? take() {
    final value = state;
    state = null;
    return value;
  }
}

final pendingReturnLocationProvider =
    NotifierProvider<PendingReturnLocationNotifier, String?>(
      PendingReturnLocationNotifier.new,
    );
