import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:ournego/core/routing/container_transform_page.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_origin.dart';
import 'package:ournego/shared/widgets/container_transform/container_transform_shared_element.dart';

const _origin = ContainerTransformOriginData(
  rect: Rect.fromLTWH(40, 600, 300, 60),
  radius: 20,
  color: Color(0xFF223344),
);

GoRouter _router() => GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Scaffold(
        body: Center(
          child: TextButton(
            key: const Key('go'),
            onPressed: () => context.push('/next', extra: state.extra),
            child: const Text('home'),
          ),
        ),
      ),
    ),
    GoRoute(
      path: '/next',
      pageBuilder: (context, state) {
        final extra = state.extra;
        if (extra is ContainerTransformRouteExtra) {
          return ContainerTransformPage<void>(
            key: state.pageKey,
            origin: extra.origin,
            child: Scaffold(
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ContainerTransformSharedElement(
                      from: extra.sharedFrom,
                      child: const SizedBox.square(
                        dimension: 50,
                        child: ColoredBox(key: Key('nego'), color: Colors.teal),
                      ),
                    ),
                    const Text('next'),
                  ],
                ),
              ),
            ),
          );
        }
        return MaterialPage<void>(
          key: state.pageKey,
          child: const Scaffold(body: Center(child: Text('next'))),
        );
      },
    ),
  ],
);

Rect _painted(WidgetTester tester) => tester
    .renderObject<RenderContainerTransformDestination>(
      find.byType(ContainerTransformDestination),
    )
    .lastPaintedRect!;

Future<GoRouter> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = _router();
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  return router;
}

void main() {
  testWidgets('with an origin the page grows out of it to fill the screen', (
    tester,
  ) async {
    final router = await _pump(tester);
    router.push('/next', extra: const ContainerTransformRouteExtra(_origin));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final early = _painted(tester);
    expect(early.height, lessThan(800));
    expect((early.center - _origin.rect.center).distance, lessThan(120));
    expect(find.text('home'), findsOneWidget, reason: 'the page below shows');

    await tester.pumpAndSettle();
    final full = _painted(tester);
    expect(full.left, closeTo(0, 1));
    expect(full.top, closeTo(0, 1));
    expect(full.width, closeTo(400, 1));
    expect(full.height, closeTo(800, 1));
    expect(find.text('next'), findsOneWidget);
  });

  testWidgets('going back shrinks it into where it came from', (tester) async {
    final router = await _pump(tester);
    router.push('/next', extra: const ContainerTransformRouteExtra(_origin));
    await tester.pumpAndSettle();

    router.pop();
    await tester.pump();
    var smallest = 800.0;
    for (var i = 0; i < 90; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      final painted = find.byType(ContainerTransformDestination);
      if (painted.evaluate().isEmpty) break;
      final h = _painted(tester).height;
      if (h < smallest) smallest = h;
    }
    expect(smallest, lessThan(200));
    await tester.pumpAndSettle();
    expect(find.text('next'), findsNothing);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('without an origin it is a standard page', (tester) async {
    final router = await _pump(tester);
    router.push('/next');
    await tester.pumpAndSettle();

    expect(find.byType(ContainerTransformDestination), findsNothing);
    expect(find.text('next'), findsOneWidget);
  });

  testWidgets('a shared element flies from where it was to its place', (
    tester,
  ) async {
    final router = await _pump(tester);
    const from = Rect.fromLTWH(20, 650, 50, 50);
    router.push(
      '/next',
      extra: const ContainerTransformRouteExtra(_origin, sharedFrom: from),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    // The real one waits, invisible; the flying copy is near where it was.
    final copies = find.byKey(const Key('nego'));
    expect(copies, findsNWidgets(2));
    final flying = tester.getCenter(copies.last);
    expect((flying - from.center).distance, lessThan(120));

    await tester.pumpAndSettle();
    expect(copies, findsOneWidget);
    final rest = tester.getCenter(copies);
    expect((rest.dx - 200).abs(), lessThan(1));
  });

  testWidgets('without a place to come from it is just the child', (
    tester,
  ) async {
    final router = await _pump(tester);
    router.push('/next', extra: const ContainerTransformRouteExtra(_origin));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(find.byKey(const Key('nego')), findsOneWidget);
    await tester.pumpAndSettle();
  });

  group('predictive back', () {
    /// Sends what Android's back gesture sends to the framework.
    Future<void> send(WidgetTester tester, String method, [double? progress]) {
      final call = MethodCall(method, <String, Object?>{
        'touchOffset': <double>[10, 400],
        'progress': progress ?? 0.0,
        'swipeEdge': 0,
      });
      return tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        SystemChannels.backGesture.name,
        SystemChannels.backGesture.codec.encodeMethodCall(call),
        (_) {},
      );
    }

    testWidgets('the swipe drives the page and letting go commits it', (
      tester,
    ) async {
      final router = await _pump(tester);
      router.push('/next', extra: const ContainerTransformRouteExtra(_origin));
      await tester.pumpAndSettle();
      final open = _painted(tester).height;
      await send(tester, 'startBackGesture');
      await send(tester, 'updateBackGestureProgress', 0.5);
      await tester.pump();
      final mid = _painted(tester).height;
      expect(mid, lessThan(open));
      expect(mid, greaterThan(100));

      await send(tester, 'commitBackGesture');
      await tester.pumpAndSettle();
      expect(find.text('next'), findsNothing);
      expect(find.text('home'), findsOneWidget);
    });

    testWidgets('cancelling springs the page back open', (tester) async {
      final router = await _pump(tester);
      router.push('/next', extra: const ContainerTransformRouteExtra(_origin));
      await tester.pumpAndSettle();

      await send(tester, 'startBackGesture');
      await send(tester, 'updateBackGestureProgress', 0.4);
      await tester.pump();
      await send(tester, 'cancelBackGesture');
      await tester.pumpAndSettle();

      expect(find.text('next'), findsOneWidget);
      expect(_painted(tester).height, closeTo(800, 1));
    });
  });

  testWidgets('measure takes the rect of the element tapped', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    late ContainerTransformRouteExtra extra;
    await tester.pumpWidget(
      MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.only(left: 30, top: 50),
            child: Builder(
              builder: (context) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => extra = ContainerTransformRouteExtra.measure(
                  context,
                  radius: 12,
                  color: Colors.red,
                ),
                child: const SizedBox(key: Key('box'), width: 120, height: 40),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('box')));
    expect(extra.origin.rect, const Rect.fromLTWH(30, 50, 120, 40));
    expect(extra.origin.radius, 12);
  });
}
