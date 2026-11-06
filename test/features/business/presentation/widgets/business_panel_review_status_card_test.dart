import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/theme/ournego_theme.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/business/domain/entities/owned_business_profile.dart';
import 'package:ournego/features/business/presentation/widgets/business_panel/business_panel_review_status_card.dart';
import 'package:ournego/shared/widgets/buttons/buttons.dart';

OwnedBusinessProfile _business(
  BusinessReviewStatus status, {
  String? reason,
  DateTime? submittedAt,
  DateTime? reviewedAt,
}) {
  return OwnedBusinessProfile(
    id: 'b1',
    name: 'Cafetería',
    description: '',
    category: 0,
    address: 'Calle 1',
    phoneNumber: null,
    latitude: 0,
    longitude: 0,
    images: const [],
    hours: const [],
    reviewStatus: status,
    rejectionReason: reason,
    submittedAt: submittedAt,
    reviewedAt: reviewedAt,
  );
}

void main() {
  final button = find.byKey(const Key('requestReviewButton'));

  Future<void> pump(
    WidgetTester tester,
    OwnedBusinessProfile business, {
    bool enabled = true,
  }) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: OurnegoTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: BusinessPanelReviewStatusCard(
              ownedBusiness: business,
              onRequestReview: enabled ? () {} : null,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pending shows the waiting state, the date and no button', (
    tester,
  ) async {
    await pump(
      tester,
      _business(
        BusinessReviewStatus.pending,
        submittedAt: DateTime(2026, 11, 6),
      ),
    );
    expect(find.text('En revisión'), findsOneWidget);
    expect(find.text('Enviada el 06/11/2026.'), findsOneWidget);
    expect(button, findsNothing);
  });

  testWidgets('approved shows it is public and warns about re-review', (
    tester,
  ) async {
    await pump(tester, _business(BusinessReviewStatus.approved));
    expect(find.text('Publicado'), findsOneWidget);
    expect(find.textContaining('volverá a revisión'), findsOneWidget);
    expect(button, findsNothing);
  });

  testWidgets('rejected shows the reason and lets the owner resubmit', (
    tester,
  ) async {
    var taps = 0;
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: OurnegoTheme.light,
        home: Scaffold(
          body: BusinessPanelReviewStatusCard(
            ownedBusiness: _business(
              BusinessReviewStatus.rejected,
              reason: 'Falta la dirección',
            ),
            onRequestReview: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text('No aprobado'), findsOneWidget);
    expect(find.text('Motivo: Falta la dirección'), findsOneWidget);
    expect(find.text('Reenviar a revisión'), findsOneWidget);
    await tester.tap(button);
    expect(taps, 1);
  });

  testWidgets('rejected without a reason does not invent one', (tester) async {
    await pump(tester, _business(BusinessReviewStatus.rejected));
    expect(find.byKey(const Key('reviewStatusReason')), findsNothing);
    expect(button, findsOneWidget);
  });

  testWidgets('withdrawn can ask for publication again', (tester) async {
    await pump(tester, _business(BusinessReviewStatus.withdrawn));
    expect(find.text('Retirado'), findsOneWidget);
    expect(find.text('Solicitar publicación'), findsOneWidget);
  });

  testWidgets('the button is disabled while another change is saving', (
    tester,
  ) async {
    await pump(
      tester,
      _business(BusinessReviewStatus.rejected),
      enabled: false,
    );
    expect(button, findsOneWidget);
    expect(tester.widget<OurnegoButton>(button).onPressed, isNull);
  });
}
