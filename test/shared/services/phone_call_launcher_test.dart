import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:ournego/shared/services/phone_call_launcher.dart';

void main() {
  late List<String> directCalls;
  late List<Uri> opened;
  late int requests;

  PhoneCallLauncher build({
    required PermissionStatus status,
    PermissionStatus? afterRequest,
    bool? directResult = true,
    bool dialerOpens = true,
    bool supportsDirectCall = true,
  }) {
    return PhoneCallLauncher(
      readStatus: () async => status,
      requestPermission: () async {
        requests++;
        return afterRequest ?? status;
      },
      directCall: (number) async {
        directCalls.add(number);
        return directResult;
      },
      openUri: (uri) async {
        opened.add(uri);
        return dialerOpens;
      },
      supportsDirectCall: supportsDirectCall,
    );
  }

  setUp(() {
    directCalls = [];
    opened = [];
    requests = 0;
  });

  test('calls directly when the permission is granted', () async {
    final result = await build(
      status: PermissionStatus.granted,
    ).call('+52 (55) 1234-5678');

    expect(result, PhoneCallResult.directCall);
    expect(directCalls, ['+525512345678']);
    expect(opened, isEmpty);
    expect(requests, 0);
  });

  test('requests the permission when it was only denied', () async {
    final result = await build(
      status: PermissionStatus.denied,
      afterRequest: PermissionStatus.granted,
    ).call('5512345678');

    expect(result, PhoneCallResult.directCall);
    expect(requests, 1);
  });

  test('falls back to tel: when permanently denied', () async {
    final result = await build(
      status: PermissionStatus.permanentlyDenied,
    ).call('5512345678');

    expect(result, PhoneCallResult.dialer);
    expect(requests, 0);
    expect(directCalls, isEmpty);
    expect(opened.single.toString(), 'tel:5512345678');
  });

  test('falls back to tel: when the request ends permanently denied', () async {
    final result = await build(
      status: PermissionStatus.denied,
      afterRequest: PermissionStatus.permanentlyDenied,
    ).call('5512345678');

    expect(result, PhoneCallResult.dialer);
    expect(opened, hasLength(1));
  });

  test('does nothing when the user declines once', () async {
    final result = await build(
      status: PermissionStatus.denied,
    ).call('5512345678');

    expect(result, PhoneCallResult.declined);
    expect(directCalls, isEmpty);
    expect(opened, isEmpty);
  });

  test('falls back to tel: when the direct call fails', () async {
    final result = await build(
      status: PermissionStatus.granted,
      directResult: false,
    ).call('5512345678');

    expect(result, PhoneCallResult.dialer);
  });

  test('uses the dialer where direct calls are unsupported', () async {
    final result = await build(
      status: PermissionStatus.granted,
      supportsDirectCall: false,
    ).call('5512345678');

    expect(result, PhoneCallResult.dialer);
    expect(directCalls, isEmpty);
  });

  test('reports failure when the dialer cannot open', () async {
    final result = await build(
      status: PermissionStatus.permanentlyDenied,
      dialerOpens: false,
    ).call('5512345678');

    expect(result, PhoneCallResult.failed);
  });

  test('rejects numbers without digits', () async {
    final result = await build(status: PermissionStatus.granted).call('abc');

    expect(result, PhoneCallResult.failed);
    expect(directCalls, isEmpty);
  });
}
