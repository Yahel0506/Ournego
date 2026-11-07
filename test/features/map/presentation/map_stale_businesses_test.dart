import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_map_repository.dart';
import '../../../helpers/app_helper.dart';

const _chip = Key('stale-businesses-chip');
const _retry = Key('businesses-load-error');

Business _business() => Business(
  id: 'biz-1',
  name: 'Panaderia Sol',
  description: 'Pan fresco todo el dia.',
  ownerId: 'owner-1',
  address: 'Av. Principal 123',
  phoneNumber: '521234567890',
  latitude: 19.4326,
  longitude: -99.1332,
  type: BusinessType.drinkAndEat,
  images: const [],
  visitCount: 0,
  hours: const [],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<FakeMapRepository> _pumpMapWithBusiness(WidgetTester tester) async {
  final repository = FakeMapRepository();
  final overrides = <Override>[
    ...mapOverrides(repository, mapTilesEnabled: false),
    ...authOverrides(
      FakeAuthRepository(state: FakeAuthState.unauthenticated),
      initialSessionStatus: false,
    ),
  ];
  await tester.pumpWidget(buildTestApp(overrides, startOnMap: true));
  await _settle(tester);
  repository.setBusinesses([_business()]);
  await _settle(tester);
  return repository;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('a failed stream keeps the markers and warns they are stale', (
    tester,
  ) async {
    final repository = await _pumpMapWithBusiness(tester);
    expect(find.byKey(const ValueKey('businessMarker-biz-1')), findsOneWidget);
    expect(find.byKey(_chip), findsNothing);

    repository.emitBusinessesError();
    await _settle(tester);

    expect(find.byKey(const ValueKey('businessMarker-biz-1')), findsOneWidget);
    expect(find.byKey(_chip), findsOneWidget);
    expect(find.text('Negocios desactualizados'), findsOneWidget);
    expect(find.byKey(_retry), findsNothing);
  });

  testWidgets('the notice goes away once businesses load again', (
    tester,
  ) async {
    final repository = await _pumpMapWithBusiness(tester);
    repository.emitBusinessesError();
    await _settle(tester);
    expect(find.byKey(_chip), findsOneWidget);

    repository.setBusinesses([_business()]);
    await _settle(tester);

    expect(find.byKey(_chip), findsNothing);
    expect(find.byKey(const ValueKey('businessMarker-biz-1')), findsOneWidget);
  });
}
