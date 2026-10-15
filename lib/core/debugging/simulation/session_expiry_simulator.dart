import 'package:supabase_flutter/supabase_flutter.dart';

enum SessionExpiryOutcome { expired, noSession, notExpired }

/// Expires the current session the way a revoked refresh token does: the
/// SDK is asked to refresh with a token the server does not know, which
/// removes the session and emits the real `signedOut` (session expired)
/// event that drives the "Tu sesión venció" dialog.
class SessionExpirySimulator {
  SessionExpirySimulator({
    required bool Function() hasSession,
    required Future<void> Function(String refreshToken) refresh,
  }) : _hasSession = hasSession,
       _refresh = refresh;

  factory SessionExpirySimulator.supabase() => SessionExpirySimulator(
    hasSession: () => Supabase.instance.client.auth.currentSession != null,
    refresh: (token) async {
      await Supabase.instance.client.auth.refreshSession(token);
    },
  );

  static const _revokedToken = 'ournego-debug-revoked-refresh-token';

  final bool Function() _hasSession;
  final Future<void> Function(String refreshToken) _refresh;

  Future<SessionExpiryOutcome> expireNow() async {
    if (!_hasSession()) return SessionExpiryOutcome.noSession;
    try {
      await _refresh(_revokedToken);
    } catch (_) {
      // The SDK rethrows the refresh failure after handling it.
    }
    return _hasSession()
        ? SessionExpiryOutcome.notExpired
        : SessionExpiryOutcome.expired;
  }
}
