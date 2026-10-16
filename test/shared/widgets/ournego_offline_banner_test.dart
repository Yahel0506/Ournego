import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/network/connectivity_providers.dart';
import 'package:ournego/core/theme/tokens/ournego_color_tokens.dart';
import 'package:ournego/shared/widgets/ournego_offline_banner.dart';

const _banner = Key('offline-banner');
const _content = Key('content');

Color _color(WidgetTester tester) =>
    (tester.widget<AnimatedContainer>(find.byKey(_banner)).decoration!
            as BoxDecoration)
        .color!;

Future<StreamController<bool>> _pump(WidgetTester tester) async {
  final connection = StreamController<bool>();
  addTearDown(connection.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        connectivityStatusProvider.overrideWith((ref) => connection.stream),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: OurnegoOfflineBanner(
            child: SizedBox.expand(key: _content, child: Text('app')),
          ),
        ),
      ),
    ),
  );
  connection.add(true);
  await tester.pumpAndSettle();
  return connection;
}

void main() {
  testWidgets('offline: the banner covers the content, it does not push it', (
    tester,
  ) async {
    final connection = await _pump(tester);
    expect(find.byKey(_banner), findsNothing);
    final top = tester.getTopLeft(find.byKey(_content)).dy;

    connection.add(false);
    await tester.pumpAndSettle();

    expect(find.byKey(_banner), findsOneWidget);
    expect(_color(tester), OurnegoColorTokens.error);
    expect(tester.getTopLeft(find.byKey(_content)).dy, top);
  });

  testWidgets('back online: it turns green in place, stays and leaves', (
    tester,
  ) async {
    final connection = await _pump(tester);
    connection.add(false);
    await tester.pumpAndSettle();
    final place = tester.getRect(find.byKey(_banner));

    connection.add(true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Conexión restablecida'), findsOneWidget);
    expect(_color(tester), OurnegoColorTokens.success);
    expect(tester.getRect(find.byKey(_banner)), place);
    expect(find.byType(SnackBar), findsNothing);

    await tester.pump(OurnegoOfflineBanner.restoredFor);
    await tester.pumpAndSettle();
    expect(find.byKey(_banner), findsNothing);
  });

  testWidgets('going offline again while restored shows the red banner', (
    tester,
  ) async {
    final connection = await _pump(tester);
    connection.add(false);
    await tester.pumpAndSettle();
    connection.add(true);
    await tester.pump(const Duration(milliseconds: 400));

    connection.add(false);
    await tester.pumpAndSettle();
    expect(find.byKey(_banner), findsOneWidget);
    expect(_color(tester), OurnegoColorTokens.error);
    expect(find.text('Conexión restablecida'), findsNothing);
  });
}
