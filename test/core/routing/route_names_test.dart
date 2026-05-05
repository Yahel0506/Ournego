import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/routing/route_names.dart';

void main() {
  test('negocioDeepLinkUrl builds canonical www URL', () {
    expect(
      negocioDeepLinkUrl('biz-1'),
      'https://www.ournego.com/negocio/biz-1',
    );
  });
}
