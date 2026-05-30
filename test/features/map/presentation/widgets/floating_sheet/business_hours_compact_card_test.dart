import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/core/ournego_colors.dart';
import 'package:ournego/features/map/domain/entities/business_hours.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/components/business_hours_compact_card.dart';

void main() {
  Widget buildSubject(List<BusinessHours> hours, {DateTime? now}) {
    return MaterialApp(
      theme: OurnegoColors.lightTheme,
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: BusinessHoursCompactCard(hours: hours, now: now),
          ),
        ),
      ),
    );
  }

  testWidgets('shows open state and today schedule', (tester) async {
    await tester.pumpWidget(
      buildSubject(const [
        BusinessHours(dayOfWeek: 4, openMinutes: 9 * 60, closeMinutes: 18 * 60),
        BusinessHours(
          dayOfWeek: 5,
          openMinutes: 10 * 60,
          closeMinutes: 14 * 60,
        ),
      ], now: DateTime(2026, 5, 29, 11, 0)),
    );

    expect(find.text('Horario'), findsOneWidget);
    expect(find.text('Abierto'), findsOneWidget);
    expect(find.text('Hoy: 09:00 - 18:00'), findsOneWidget);
    expect(find.text('Lun'), findsOneWidget);
    expect(find.text('Vie'), findsOneWidget);
  });

  testWidgets('shows unknown state when there are no hours', (tester) async {
    await tester.pumpWidget(buildSubject(const []));

    expect(find.text('Sin horario'), findsOneWidget);
    expect(find.text('Horario no disponible'), findsOneWidget);
  });

  testWidgets('shows incomplete state for invalid today range', (tester) async {
    await tester.pumpWidget(
      buildSubject(const [
        BusinessHours(dayOfWeek: 4, openMinutes: 18 * 60, closeMinutes: 9 * 60),
      ], now: DateTime(2026, 5, 29, 12, 0)),
    );

    expect(find.text('Sin horario'), findsOneWidget);
    expect(find.text('Horario no disponible'), findsOneWidget);
  });
}
