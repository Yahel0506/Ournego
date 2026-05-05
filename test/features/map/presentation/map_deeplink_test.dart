import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_map_repository.dart';
import '../../../helpers/app_helper.dart';

Business _buildBusiness({required String id, required String name}) {
  return Business(
    id: id,
    name: name,
    description: 'Pan fresco todo el dia.',
    ownerId: 'owner-1',
    address: 'Av. Principal 123',
    phoneNumber: '521234567890',
    latitude: 19.4326,
    longitude: -99.1332,
    type: BusinessType.drinkAndEat,
    images: const [],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('deep link opens the requested business sheet', (tester) async {
    final business = _buildBusiness(id: 'biz-1', name: 'Panaderia Sol');
    final repository = FakeMapRepository(
      initialBusinesses: [business],
      businessById: {business.id: business},
    );

    final overrides = [
      ...mapOverrides(repository, mapTilesEnabled: false),
      ...authOverrides(
        FakeAuthRepository(state: FakeAuthState.unauthenticated),
        initialSessionStatus: false,
      ),
    ];

    await tester.pumpWidget(
      buildTestApp(
        overrides,
        startOnMap: true,
        initialLocation: '/negocio/${business.id}',
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text(business.name), findsWidgets);
  });

  testWidgets('deep link overrides stored sheet state', (tester) async {
    final deepLinkBusiness = _buildBusiness(
      id: 'biz-1',
      name: 'Panaderia Sol',
    );
    final storedBusiness = _buildBusiness(
      id: 'biz-2',
      name: 'Cafe Guardado',
    );

    final storedSheet = SheetBusinessData.fromBusiness(storedBusiness);

    SharedPreferences.setMockInitialValues({
      'map_sheet_state': 'collapsed',
      'map_sheet_active_business': jsonEncode(storedSheet.toJson()),
    });

    final repository = FakeMapRepository(
      initialBusinesses: [deepLinkBusiness, storedBusiness],
      businessById: {deepLinkBusiness.id: deepLinkBusiness},
    );

    final overrides = [
      ...mapOverrides(repository, mapTilesEnabled: false),
      ...authOverrides(
        FakeAuthRepository(state: FakeAuthState.unauthenticated),
        initialSessionStatus: false,
      ),
    ];

    await tester.pumpWidget(
      buildTestApp(
        overrides,
        startOnMap: true,
        initialLocation: '/negocio/${deepLinkBusiness.id}',
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text(deepLinkBusiness.name), findsWidgets);
    expect(find.text(storedBusiness.name), findsNothing);
  });

  testWidgets('missing business shows not found message', (tester) async {
    final repository = FakeMapRepository();
    final overrides = [
      ...mapOverrides(repository, mapTilesEnabled: false),
      ...authOverrides(
        FakeAuthRepository(state: FakeAuthState.unauthenticated),
        initialSessionStatus: false,
      ),
    ];

    await tester.pumpWidget(
      buildTestApp(
        overrides,
        startOnMap: true,
        initialLocation: '/negocio/biz-404',
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(
      find.text('No encontramos el negocio solicitado'),
      findsOneWidget,
    );
  });
}
