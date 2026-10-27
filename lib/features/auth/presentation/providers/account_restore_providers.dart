import 'package:flutter/foundation.dart' show debugPrint;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/auth/presentation/providers/session_expiry_providers.dart';

// LAYER 4: State
enum AccountRestoreStatus { none, restored }

/// Cancels a scheduled account deletion when someone signs in (email or
/// Google) or a session is restored at startup (D10 of the OUR-142 plan).
///
/// It runs off the auth events, so it never blocks the sign-in or the router's
/// profile guard. A failed call (offline, expired token) leaves the user
/// unchecked and is retried on the next auth event for that user: the token
/// refresh, a new sign-in or the next app start.
class AccountRestoreNotifier extends Notifier<AccountRestoreStatus> {
  final Set<String> _checkedUserIds = {};
  String? _inFlightUserId;
  String? _currentUserId;

  @override
  AccountRestoreStatus build() {
    final subscription = ref.read(authEventsProvider).listen(_onEvent);
    ref.onDispose(subscription.cancel);
    return AccountRestoreStatus.none;
  }

  void _onEvent(AuthState data) {
    switch (data.event) {
      case AuthChangeEvent.signedIn:
      case AuthChangeEvent.initialSession:
      case AuthChangeEvent.tokenRefreshed:
        final userId = data.session?.user.id;
        _currentUserId = userId;
        if (userId != null) _cancelDeletionFor(userId);
      case AuthChangeEvent.signedOut:
        // A deletion requested from the web revokes the sessions; signing in
        // again in this same run must check again.
        _currentUserId = null;
        _checkedUserIds.clear();
        state = AccountRestoreStatus.none;
      default:
        break;
    }
  }

  Future<void> _cancelDeletionFor(String userId) async {
    if (_checkedUserIds.contains(userId) || _inFlightUserId == userId) return;
    _inFlightUserId = userId;
    final result = await ref.read(cancelMyDeletionUsecaseProvider)();
    if (!ref.mounted) return;
    _inFlightUserId = null;

    result.fold(
      (failure) => debugPrint(
        'cancel_my_deletion failed (${failure.runtimeType}); retrying later',
      ),
      (cancelled) {
        _checkedUserIds.add(userId);
        if (cancelled && _currentUserId == userId) {
          state = AccountRestoreStatus.restored;
        }
      },
    );
  }

  /// Called once the notice has been shown and closed.
  void acknowledge() => state = AccountRestoreStatus.none;
}

final accountRestoreProvider =
    NotifierProvider<AccountRestoreNotifier, AccountRestoreStatus>(
      AccountRestoreNotifier.new,
    );
