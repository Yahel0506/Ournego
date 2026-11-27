import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/failures.dart';
import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/auth/presentation/providers/auth_providers.dart';
import 'package:ournego/features/business/domain/entities/business_report_reason.dart';
import 'package:ournego/features/business/presentation/providers/business_providers.dart';
import 'package:ournego/features/business/presentation/widgets/business_report_menu_button_widget.dart';

import '../../../../fakes/fake_business_report_repository.dart';

void main() {
  Future<void> pump(
    WidgetTester tester,
    FakeBusinessReportRepository repository, {
    String? userId = 'user-1',
    String ownerId = 'owner-1',
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserIdProvider.overrideWith((ref) => userId),
          businessReportRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: OurnegoTheme.light,
          home: Scaffold(
            body: Center(
              child: BusinessReportMenuButtonWidget(
                businessId: 'b1',
                ownerId: ownerId,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Future<void> openDialog(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('businessMoreButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('businessReportMenuEntry')));
    await tester.pumpAndSettle();
  }

  testWidgets('is hidden for the owner and for guests', (tester) async {
    await pump(tester, FakeBusinessReportRepository(), userId: 'owner-1');
    expect(find.byKey(const ValueKey('businessMoreButton')), findsNothing);

    await pump(tester, FakeBusinessReportRepository(), userId: null);
    expect(find.byKey(const ValueKey('businessMoreButton')), findsNothing);
  });

  testWidgets('the menu leads to the dialog with the six reasons', (
    tester,
  ) async {
    await pump(tester, FakeBusinessReportRepository());
    await openDialog(tester);

    expect(find.text('Reportar negocio'), findsOneWidget);
    for (final reason in BusinessReportReason.values) {
      expect(
        find.byKey(ValueKey('businessReportReason_${reason.wire}')),
        findsOneWidget,
      );
    }
    expect(find.text('No existe / es falso'), findsOneWidget);
    expect(find.text('Contenido inapropiado u ofensivo'), findsOneWidget);
  });

  testWidgets('sends the report and confirms without internal details', (
    tester,
  ) async {
    final repository = FakeBusinessReportRepository();
    await pump(tester, repository);
    await openDialog(tester);

    await tester.tap(find.byKey(const ValueKey('businessReportReason_closed')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('businessReportSubmitButton')));
    await tester.pumpAndSettle();

    expect(repository.submitted, hasLength(1));
    expect(repository.submitted.single.businessId, 'b1');
    expect(repository.submitted.single.reason, BusinessReportReason.closed);
    expect(
      find.text('Recibimos tu reporte. Gracias por avisarnos.'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('businessReportNoteField')), findsNothing);
  });

  testWidgets('needs a reason, and a note for "Otro"', (tester) async {
    final repository = FakeBusinessReportRepository();
    await pump(tester, repository);
    await openDialog(tester);

    await tester.tap(find.byKey(const ValueKey('businessReportSubmitButton')));
    await tester.pump();
    expect(find.text('Elige un motivo.'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('businessReportReason_other')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('businessReportSubmitButton')));
    await tester.pump();
    expect(find.text('Cuéntanos qué pasa en la nota.'), findsOneWidget);
    expect(repository.submitted, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('businessReportNoteField')),
      'Vende productos prohibidos',
    );
    await tester.tap(find.byKey(const ValueKey('businessReportSubmitButton')));
    await tester.pumpAndSettle();
    expect(repository.submitted.single.reason, BusinessReportReason.other);
    expect(repository.submitted.single.note, 'Vende productos prohibidos');
  });

  testWidgets('keeps the dialog open and explains a daily-limit failure', (
    tester,
  ) async {
    final repository = FakeBusinessReportRepository(
      failure: BusinessReportLimitFailure(),
    );
    await pump(tester, repository);
    await openDialog(tester);

    await tester.tap(
      find.byKey(const ValueKey('businessReportReason_no_exists')),
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('businessReportSubmitButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Llegaste al límite de reportes de hoy. Inténtalo mañana.'),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('businessReportNoteField')),
      findsOneWidget,
    );
  });
}
