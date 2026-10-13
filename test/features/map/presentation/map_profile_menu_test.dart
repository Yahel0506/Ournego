import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';

import '../../../fakes/fake_auth_repository.dart';
import '../../../fakes/fake_map_repository.dart';
import '../../../helpers/app_helper.dart';

const _profileButton = Key('mapProfileButton');
const _menu = Key('profileMenuDialog');
const _logIn = Key('profileMenuLogInButton');

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> _pumpMap(WidgetTester tester) async {
  final overrides = <Override>[
    ...mapOverrides(FakeMapRepository(), mapTilesEnabled: false),
    ...authOverrides(
      FakeAuthRepository(state: FakeAuthState.unauthenticated),
      initialSessionStatus: false,
    ),
  ];
  await tester.pumpWidget(buildTestApp(overrides, startOnMap: true));
  await _settle(tester);
}

Finder get _trigger => find.ancestor(
  of: find.byKey(_profileButton),
  matching: find.byType(ContainerTransformTrigger),
);

bool _buttonHidden(WidgetTester tester) {
  final opacity = tester.widget<Opacity>(
    find.descendant(of: _trigger, matching: find.byType(Opacity)).first,
  );
  return opacity.opacity == 0;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('the account menu grows out of the profile button', (
    tester,
  ) async {
    await _pumpMap(tester);
    final buttonRect = tester.getRect(find.byKey(_profileButton));
    expect(_buttonHidden(tester), isFalse);

    await tester.tap(find.byKey(_profileButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // From the first frame the content is in the tree (tests and screen
    // readers find it), while what is drawn is still the size of the button.
    expect(find.byKey(_menu), findsOneWidget);
    expect(find.byKey(_logIn), findsOneWidget);
    final start = tester
        .renderObject<RenderContainerTransformDestination>(
          find.byType(ContainerTransformDestination),
        )
        .lastPaintedRect!;
    expect(start.width, lessThan(buttonRect.width * 2));
    expect((start.center - buttonRect.center).distance, lessThan(80));

    await _settle(tester);
    final end = tester
        .renderObject<RenderContainerTransformDestination>(
          find.byType(ContainerTransformDestination),
        )
        .lastPaintedRect!;
    expect(end.width, greaterThan(250));
    expect(_buttonHidden(tester), isTrue);
  });

  testWidgets('the button comes back when the menu closes', (tester) async {
    await _pumpMap(tester);
    await tester.tap(find.byKey(_profileButton));
    await _settle(tester);
    expect(_buttonHidden(tester), isTrue);

    await tester.binding.handlePopRoute();
    await _settle(tester);

    expect(find.byKey(_menu), findsNothing);
    expect(_buttonHidden(tester), isFalse);
  });

  testWidgets('a second tap on the button while the menu closes is ignored', (
    tester,
  ) async {
    await _pumpMap(tester);
    await tester.tap(find.byKey(_profileButton));
    await _settle(tester);

    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.byKey(_profileButton), warnIfMissed: false);
    await _settle(tester);

    expect(find.byKey(_menu), findsNothing);
  });
}
