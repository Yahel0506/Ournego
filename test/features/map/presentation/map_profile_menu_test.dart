import 'package:flutter/material.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/features/feedback/domain/entities/feedback_report.dart';
import 'package:ournego/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:ournego/features/feedback/domain/usecases/send_feedback_usecase.dart';
import 'package:ournego/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:ournego/features/feedback/presentation/widgets/feedback_dialog_widget.dart';
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

class _FakeFeedbackRepository implements FeedbackRepository {
  @override
  Future<Either<Failure, bool>> sendFeedback(FeedbackReport report) async =>
      const Right(true);
}

Future<void> _pumpMap(WidgetTester tester) async {
  final overrides = <Override>[
    sendFeedbackUsecaseProvider.overrideWith(
      (ref) => SendFeedbackUsecase(repository: _FakeFeedbackRepository()),
    ),
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

  group('the window that follows grows out of the tapped item', () {
    Finder feedbackSurface() => find.descendant(
      of: find.byType(FeedbackDialogWidget),
      matching: find.byType(ContainerTransformDestination),
    );

    Rect painted(WidgetTester tester) => tester
        .renderObject<RenderContainerTransformDestination>(feedbackSurface())
        .lastPaintedRect!;

    testWidgets('feedback starts as wide as the item and comes back to the '
        'profile button', (tester) async {
      await _pumpMap(tester);
      final button = tester.getRect(find.byKey(_profileButton));
      await tester.tap(find.byKey(_profileButton));
      await _settle(tester);
      final item = tester.getRect(
        find.byKey(const ValueKey('profileMenuFeedbackButton')),
      );

      await tester.tap(find.byKey(const ValueKey('profileMenuFeedbackButton')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // It grows out of the item the user touched, not from the button.
      final early = painted(tester);
      expect((early.center - item.center).distance, lessThan(120));
      expect(early.width, greaterThan(item.width * 0.6));

      await _settle(tester);
      expect(find.byType(FeedbackDialogWidget), findsOneWidget);
      // The profile button is not the origin: not covered while it is open.
      expect(_buttonHidden(tester), isFalse);

      // Once the item is gone it goes back to the profile button.
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(_buttonHidden(tester), isTrue);
      var last = painted(tester);
      for (var i = 0; i < 120; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        if (feedbackSurface().evaluate().isEmpty) break;
        last = painted(tester);
      }
      expect((last.center - button.center).distance, lessThan(60));
      await _settle(tester);
      expect(_buttonHidden(tester), isFalse);
    });

    testWidgets('two taps in the same frame choose only the first item', (
      tester,
    ) async {
      await _pumpMap(tester);
      await tester.tap(find.byKey(_profileButton));
      await _settle(tester);

      await tester.tap(find.byKey(const ValueKey('profileMenuFeedbackButton')));
      // Same frame: the menu has not even started to close.
      await tester.tap(
        find.byKey(const ValueKey('profileMenuLocationButton')),
        warnIfMissed: false,
      );
      await _settle(tester);

      expect(find.byType(FeedbackDialogWidget), findsOneWidget);
    });
  });
}
