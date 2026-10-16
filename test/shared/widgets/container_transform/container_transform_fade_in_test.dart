import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/shared/widgets/container_transform/container_transform_destination.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_dialog_surface.dart';

const _late = Key('late');

double _opacityOf(WidgetTester tester) {
  final opacities = find.ancestor(
    of: find.byKey(_late),
    matching: find.byType(Opacity),
  );
  if (opacities.evaluate().isEmpty) return 1;
  return tester.widget<Opacity>(opacities.first).opacity;
}

void main() {
  testWidgets('late content is hidden at first and fully shown at the end', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              key: const Key('open'),
              onPressed: () => showOurnegoDialog<void>(
                context: context,
                builder: (_) => const Material(
                  type: MaterialType.transparency,
                  child: Center(
                    child: OurnegoDialogSurface(
                      child: ContainerTransformFadeIn(
                        child: SizedBox(key: _late, height: 100, width: 200),
                      ),
                    ),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('open')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    expect(_opacityOf(tester), 0);

    await tester.pumpAndSettle();
    expect(_opacityOf(tester), 1);
  });

  testWidgets('outside a container transform it is the plain child', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ContainerTransformFadeIn(child: SizedBox(key: _late)),
      ),
    );
    expect(_opacityOf(tester), 1);
  });
}
