import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_preview_card.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';

const _business = OwnedBusinessProfile(
  id: 'b1',
  name: 'Cafetería',
  description: '',
  category: 0,
  address: 'Calle 1',
  phoneNumber: '5512345678',
  latitude: 0,
  longitude: 0,
  images: ['https://example.com/a.png', 'https://example.com/b.png'],
  hours: [],
);

void main() {
  late List<String> calls;
  late List<ContainerTransformOriginController> origins;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    calls = [];
    origins = [];
    await tester.pumpWidget(
      MaterialApp(
        theme: OurnegoTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            child: BusinessPanelPreviewCard(
              ownedBusiness: _business,
              onEditIdentity: (o) {},
              onAddGalleryImage: () {},
              onDeleteGalleryImage: (url, origin) {
                calls.add('delete:$url');
                origins.add(origin);
              },
              onEditLocation: (origin) {
                calls.add('location');
                origins.add(origin);
              },
              onEditPhone: (o) {},
              onEditHours: (o) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('the map and its header open the location editor from the map', (
    tester,
  ) async {
    await pump(tester);

    final button = tester.getCenter(find.bySemanticsLabel('Editar ubicación'));
    await tester.tap(find.bySemanticsLabel('Editar ubicación'));
    expect(calls, ['location']);

    final origin = origins.single.measure();
    expect(origin, isNotNull);
    // The origin is the whole map block (header and map), not a point.
    expect(origin!.rect.height, greaterThan(100));
    expect(origin.rect.contains(button), isTrue);
  });

  testWidgets('deleting an image reports it with the origin of its button', (
    tester,
  ) async {
    await pump(tester);

    await tester.tap(find.bySemanticsLabel('Eliminar imagen').first);
    expect(calls, ['delete:https://example.com/a.png']);
    final origin = origins.single.measure();
    expect(origin, isNotNull);
    expect(origin!.rect.size.shortestSide, lessThanOrEqualTo(40));
  });
}
