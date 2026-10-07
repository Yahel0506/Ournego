import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/network/socket_exception_stub.dart'
    if (dart.library.io) 'package:ournego/core/network/socket_exception_io.dart';

/// Returns `true` when [error] means the device could not reach the server.
bool isNetworkError(Object error) {
  if (error is TimeoutException) return true;
  if (error is http.ClientException) return true;
  if (error is AuthRetryableFetchException) return true;
  return isSocketException(error);
}

/// Returns `true` when [error] means the session is no longer valid.
bool isSessionExpiredError(Object error) {
  if (error is AuthException) {
    final code = error.code ?? '';
    return error.statusCode == '401' ||
        code == 'refresh_token_not_found' ||
        code == 'refresh_token_already_used' ||
        code == 'session_not_found' ||
        code == 'session_expired' ||
        code == 'bad_jwt';
  }
  if (error is PostgrestException) {
    return error.code == 'PGRST301' ||
        error.code == 'PGRST303' ||
        error.message.toLowerCase().contains('jwt expired');
  }
  return false;
}
