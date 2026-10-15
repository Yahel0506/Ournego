import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/features/map/domain/entities/business.dart';
import 'package:ournego/features/map/domain/entities/business_type.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';
import 'package:ournego/shared/widgets/ournego_popover_surface.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_map_repository.dart';
import '../../../helpers/app_helper.dart';

Business _business({String? phone}) => Business(
  id: 'biz-1',
  name: 'Panaderia Sol',
  description: 'Pan fresco todo el dia.',
  ownerId: 'owner-1',
  address: 'Av. Principal 123',
  phoneNumber: phone,
  latitude: 19.4326,
  longitude: -99.1332,
  type: BusinessType.drinkAndEat,
  images: const [],
  visitCount: 0,
  hours: const [],
);

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pump(WidgetTester tester, {Business? business}) async {
  final repository = FakeMapRepository(
    initialBusinesses: [?business],
    businessById: {if (business != null) business.id: business},
  );
  final overrides = <Override>[
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
      initialLocation: business == null ? null : '/negocio/${business.id}',
    ),
  );
  await _settle(tester);
}

Finder _triggerOf(Finder child) =>
    find.ancestor(of: child, matching: find.byType(ContainerTransformTrigger));

bool _hidden(WidgetTester tester, Finder child) {
  final opacity = tester.widget<Opacity>(
    find
        .descendant(of: _triggerOf(child).first, matching: find.byType(Opacity))
        .first,
  );
  return opacity.opacity == 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('"Contactar" without a phone number', () {
    final message = find.byIcon(Icons.chat_rounded);
    final notice = find.byKey(const ValueKey('noPhonePopover'));

    testWidgets('the notice is a popover that grows out of the button', (
      tester,
    ) async {
      await _pump(tester, business: _business());
      expect(message, findsOneWidget);
      final button = tester.getRect(message);

      await tester.tap(message);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final early = tester
          .renderObject<RenderContainerTransformDestination>(
            find.descendant(
              of: notice,
              matching: find.byType(ContainerTransformDestination),
            ),
          )
          .lastPaintedRect!;
      expect((early.center - button.center).distance, lessThan(120));

      await _settle(tester);
      expect(notice, findsOneWidget);
      expect(find.byType(OurnegoPopoverSurface), findsOneWidget);
      expect(find.text('Sin teléfono disponible'), findsOneWidget);
      // No dialog: no scrim and the map stays usable behind it.
      expect(find.byType(OurnegoFormDialog), findsNothing);
      expect(_hidden(tester, message), isTrue);
    });

    testWidgets('a tap outside closes it and the button comes back', (
      tester,
    ) async {
      await _pump(tester, business: _business());
      await tester.tap(message);
      await _settle(tester);
      expect(notice, findsOneWidget);

      await tester.tapAt(const Offset(780, 300));
      await _settle(tester);

      expect(notice, findsNothing);
      expect(_hidden(tester, message), isFalse);
    });

    testWidgets('with a phone number nothing opens', (tester) async {
      await _pump(tester, business: _business(phone: '521234567890'));
      await tester.tap(message);
      await _settle(tester);

      expect(notice, findsNothing);
    });
  });

  group('map credits', () {
    final info = find.byIcon(Icons.info_outline_rounded);

    testWidgets('grow out of the "i" button and go back to it', (tester) async {
      await _pump(tester);
      final button = tester.getRect(info);

      await tester.tap(info);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      final early = tester
          .renderObject<RenderContainerTransformDestination>(
            find.byType(ContainerTransformDestination),
          )
          .lastPaintedRect!;
      expect((early.center - button.center).distance, lessThan(80));

      await _settle(tester);
      expect(find.byType(OurnegoFormDialog), findsOneWidget);
      expect(_hidden(tester, info), isTrue);

      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.byType(OurnegoFormDialog), findsNothing);
      expect(_hidden(tester, info), isFalse);
    });
  });
}
