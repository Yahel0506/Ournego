import 'package:flutter/foundation.dart';

import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

/// How a call request ended.
enum PhoneCallResult {
  /// The call started directly, without the dialer.
  directCall,

  /// The dialer was opened with the number (`tel:` fallback).
  dialer,

  /// The user declined the permission this time; nothing was launched.
  declined,

  /// Neither the direct call nor the dialer could be started.
  failed,
}

/// Calls a phone number directly when `CALL_PHONE` is granted and falls back
/// to the dialer (`tel:`, no permission needed) when the permission is
/// permanently denied or restricted and can no longer be requested.
class PhoneCallLauncher {
  PhoneCallLauncher({
    Future<PermissionStatus> Function()? readStatus,
    Future<PermissionStatus> Function()? requestPermission,
    Future<bool?> Function(String number)? directCall,
    Future<bool> Function(Uri uri)? openUri,
    bool? supportsDirectCall,
  }) : _readStatus = readStatus ?? (() => Permission.phone.status),
       _requestPermission = requestPermission ?? Permission.phone.request,
       _directCall = directCall ?? FlutterPhoneDirectCaller.callNumber,
       _openUri = openUri ?? launchUrl,
       _supportsDirectCall =
           supportsDirectCall ??
           (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  final Future<PermissionStatus> Function() _readStatus;
  final Future<PermissionStatus> Function() _requestPermission;
  final Future<bool?> Function(String number) _directCall;
  final Future<bool> Function(Uri uri) _openUri;
  final bool _supportsDirectCall;

  /// Keeps digits and a leading "+" so the dialer accepts the number.
  static String sanitize(String raw) => raw.replaceAll(RegExp(r'[^\d+]'), '');

  Future<PhoneCallResult> call(String rawNumber) async {
    final number = sanitize(rawNumber);
    if (number.isEmpty) return PhoneCallResult.failed;

    // Direct calling only exists on Android; elsewhere the dialer is the call.
    if (!_supportsDirectCall) return _dial(number);

    var status = await _readStatus();
    if (status.isDenied) {
      status = await _requestPermission();
    }

    if (status.isGranted) {
      final started = await _directCall(number);
      if (started == true) return PhoneCallResult.directCall;
      // The plugin could not place the call; the dialer still can.
      return _dial(number);
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      return _dial(number);
    }

    return PhoneCallResult.declined;
  }

  Future<PhoneCallResult> _dial(String number) async {
    try {
      final opened = await _openUri(Uri(scheme: 'tel', path: number));
      return opened ? PhoneCallResult.dialer : PhoneCallResult.failed;
    } catch (e) {
      debugPrint('Could not open the dialer: $e');
      return PhoneCallResult.failed;
    }
  }
}
