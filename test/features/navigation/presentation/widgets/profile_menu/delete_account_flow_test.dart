import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/navigation/presentation/widgets/profile_menu/delete_account_flow.dart';

void main() {
  Future<void> open(WidgetTester tester, List<Uri> launched) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => openDeleteAccountDialog(
              context,
              launch: (url) async {
                launched.add(url);
                return true;
              },
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('warns about the grace period and how to cancel', (tester) async {
    await open(tester, []);

    expect(find.textContaining('30 días'), findsOneWidget);
    expect(find.textContaining('inicia sesión en la app'), findsOneWidget);
  });

  testWidgets('continuing opens the verifiable web flow', (tester) async {
    final launched = <Uri>[];
    await open(tester, launched);

    await tester.tap(find.byKey(const ValueKey('confirmDeleteAccountButton')));
    await tester.pumpAndSettle();

    expect(launched, [deleteAccountUrl]);
    expect(deleteAccountUrl.path, '/delete-account');
  });

  testWidgets('cancelling does not open anything', (tester) async {
    final launched = <Uri>[];
    await open(tester, launched);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(launched, isEmpty);
  });
}
