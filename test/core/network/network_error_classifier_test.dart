import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ournego/core/network/network_error_classifier.dart';

void main() {
  group('isNetworkError', () {
    test('detects connectivity-related errors', () {
      expect(isNetworkError(const SocketException('offline')), isTrue);
      expect(isNetworkError(TimeoutException('slow')), isTrue);
      expect(isNetworkError(http.ClientException('failed')), isTrue);
      expect(isNetworkError(AuthRetryableFetchException(message: 'x')), isTrue);
    });

    test('ignores unrelated errors', () {
      expect(isNetworkError(StateError('boom')), isFalse);
      expect(isNetworkError(const AuthException('Invalid login')), isFalse);
    });
  });

  group('isSessionExpiredError', () {
    test('detects invalid sessions', () {
      expect(
        isSessionExpiredError(
          const AuthException('gone', code: 'refresh_token_not_found'),
        ),
        isTrue,
      );
      expect(
        isSessionExpiredError(const AuthException('nope', statusCode: '401')),
        isTrue,
      );
      expect(
        isSessionExpiredError(
          const PostgrestException(message: 'JWT expired', code: 'PGRST301'),
        ),
        isTrue,
      );
    });

    test('ignores credential errors and network errors', () {
      expect(
        isSessionExpiredError(const AuthException('Invalid login credentials')),
        isFalse,
      );
      expect(isSessionExpiredError(const SocketException('offline')), isFalse);
    });
  });
}
