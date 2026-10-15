import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_info_grid.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';

const _business = OwnedBusinessProfile(
  id: 'b1',
  name: 'Cafetería',
  description: '',
  category: 0,
  address: 'Calle 1',
  phoneNumber: '5512345678',
  latitude: 0,
  longitude: 0,
  images: [],
  hours: [],
);

void main() {
  final edits = find.byIcon(Icons.edit_rounded);
  final dialog = find.byType(OurnegoFormDialog);

  Future<List<String>> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final calls = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: OurnegoTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Builder(
              builder: (context) => BusinessPanelInfoGrid(
                ownedBusiness: _business,
                onEditLocation: () => calls.add('location'),
                onEditPhone: (origin) {
                  calls.add('phone');
                  showOurnegoDialog<void>(
                    context: context,
                    origin: origin,
                    builder: (_) => OurnegoFormDialog(
                      title: 'Editar telefono',
                      primaryAction: OurnegoDialogAction(
                        label: 'Guardar',
                        onPressed: () {},
                      ),
                      child: const Text('campo'),
                    ),
                  );
                },
                onEditHours: (origin) => calls.add('hours'),
              ),
            ),
          ),
        ),
      ),
    );
    return calls;
  }

  testWidgets('each tile reports its own edit', (tester) async {
    final calls = await pump(tester);
    expect(edits, findsNWidgets(3));

    await tester.tap(edits.at(0));
    await tester.tap(edits.at(2));
    expect(calls, ['location', 'hours']);
  });

  testWidgets('the phone editor grows out of its tile', (tester) async {
    await pump(tester);
    final tile = tester.getRect(
      find
          .ancestor(
            of: edits.at(1),
            matching: find.byType(ContainerTransformTrigger),
          )
          .first,
    );

    await tester.tap(edits.at(1));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final early = tester
        .renderObject<RenderContainerTransformDestination>(
          find.byType(ContainerTransformDestination),
        )
        .lastPaintedRect!;
    expect((early.center - tile.center).distance, lessThan(120));
    expect(early.width, greaterThan(tile.width * 0.5));

    await tester.pumpAndSettle();
    expect(dialog, findsOneWidget);

    // The tile steps aside while its editor is open and comes back.
    Opacity tileOpacity() => tester.widget<Opacity>(
      find
          .descendant(
            of: find
                .ancestor(
                  of: edits.at(1),
                  matching: find.byType(ContainerTransformTrigger),
                )
                .first,
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(tileOpacity().opacity, 0);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(dialog, findsNothing);
    expect(tileOpacity().opacity, 1);
  });
}
