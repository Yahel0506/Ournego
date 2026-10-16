import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/shared/widgets/container_transform/show_ournego_window.dart';
import 'package:ournego/shared/widgets/ournego_alert_dialog.dart';
import 'package:ournego/shared/widgets/ournego_form_dialog.dart';
import 'package:ournego/shared/widgets/ournego_saving_dialog.dart';

const _field = Key('field');
const _save = Key('save');
const _open = Key('open');

/// Opens a form dialog whose save is [save]; [result] records how it closed.
Future<void> _pump(
  WidgetTester tester, {
  required Future<void> Function(String text) save,
  required void Function(bool? result) onClosed,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final controller = TextEditingController(text: 'hola');
  await tester.pumpWidget(
    MaterialApp(
      theme: OurnegoTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            key: _open,
            onPressed: () async => onClosed(
              await showOurnegoDialog<bool>(
                context: context,
                builder: (dialogContext) => OurnegoSavingDialog<void>(
                  save: (_) => save(controller.text),
                  builder: (context, isSaving, error, submit) =>
                      OurnegoFormDialog(
                        title: 'Editar',
                        isSaving: isSaving,
                        errorText: error,
                        primaryAction: OurnegoDialogAction(
                          key: _save,
                          label: 'Guardar',
                          onPressed: () => submit(null),
                        ),
                        secondaryAction: OurnegoDialogAction(
                          label: 'Cancelar',
                          onPressed: () =>
                              Navigator.of(dialogContext).pop(false),
                        ),
                        child: TextField(key: _field, controller: controller),
                      ),
                ),
              ),
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_open));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('it stays open while saving and closes with true when done', (
    tester,
  ) async {
    final pending = Completer<void>();
    bool? closed;
    var saves = 0;
    await _pump(
      tester,
      save: (_) {
        saves++;
        return pending.future;
      },
      onClosed: (r) => closed = r,
    );

    await tester.tap(find.byKey(_save));
    await tester.pump();
    expect(find.byType(OurnegoFormDialog), findsOneWidget);
    expect(
      tester.widget<OurnegoFormDialog>(find.byType(OurnegoFormDialog)).isSaving,
      isTrue,
    );

    // A second tap does not save twice, and back does not close it.
    await tester.tap(find.byKey(_save), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 600));
    expect(saves, 1);
    expect(find.byType(OurnegoFormDialog), findsOneWidget);
    expect(closed, isNull);

    pending.complete();
    await tester.pumpAndSettle();
    expect(find.byType(OurnegoFormDialog), findsNothing);
    expect(closed, isTrue);
  });

  testWidgets('a failed save keeps the dialog, its text and says so', (
    tester,
  ) async {
    bool? closed;
    await _pump(
      tester,
      save: (_) async => throw Exception('boom'),
      onClosed: (r) => closed = r,
    );
    await tester.enterText(find.byKey(_field), 'texto nuevo');

    await tester.tap(find.byKey(_save));
    await tester.pumpAndSettle();

    expect(find.byType(OurnegoFormDialog), findsOneWidget);
    expect(find.byKey(const Key('form-dialog-error')), findsOneWidget);
    expect(find.text('texto nuevo'), findsOneWidget);
    expect(closed, isNull);

    // It can be tried again and cancelled.
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(closed, isFalse);
  });

  testWidgets('saving reads what is in the field at that moment', (
    tester,
  ) async {
    String? saved;
    await _pump(tester, save: (text) async => saved = text, onClosed: (_) {});
    await tester.enterText(find.byKey(_field), 'cambiado');
    await tester.tap(find.byKey(_save));
    await tester.pumpAndSettle();
    expect(saved, 'cambiado');
  });
}
