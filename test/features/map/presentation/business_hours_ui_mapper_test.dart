import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/map/domain/entities/business_hours.dart';
import 'package:ournego/features/map/presentation/mappers/business_hours_ui_mapper.dart';
import 'package:ournego/features/map/presentation/models/map_search_models.dart';

void main() {
  group('getBusinessOpenState', () {
    test('returns open when current time is inside today range', () {
      final state = getBusinessOpenState(
        hours: const [
          BusinessHours(
            dayOfWeek: 4,
            openMinutes: 9 * 60,
            closeMinutes: 18 * 60,
          ),
        ],
        now: DateTime(2026, 5, 29, 10, 30),
      );

      expect(state, BusinessOpenState.open);
    });

    test('returns closed when current time is outside today range', () {
      final state = getBusinessOpenState(
        hours: const [
          BusinessHours(
            dayOfWeek: 4,
            openMinutes: 9 * 60,
            closeMinutes: 18 * 60,
          ),
        ],
        now: DateTime(2026, 5, 29, 20, 0),
      );

      expect(state, BusinessOpenState.closed);
    });

    test('returns closed when today has no configured hours', () {
      final state = getBusinessOpenState(
        hours: const [
          BusinessHours(
            dayOfWeek: 3,
            openMinutes: 9 * 60,
            closeMinutes: 18 * 60,
          ),
        ],
        now: DateTime(2026, 5, 29, 12, 0),
      );

      expect(state, BusinessOpenState.closed);
    });

    test('returns unknown when there are no hours', () {
      final state = getBusinessOpenState(
        hours: const [],
        now: DateTime(2026, 5, 29, 12, 0),
      );

      expect(state, BusinessOpenState.unknown);
    });

    test('returns unknown when all hours are invalid', () {
      final state = getBusinessOpenState(
        hours: const [
          BusinessHours(
            dayOfWeek: 4,
            openMinutes: 18 * 60,
            closeMinutes: 9 * 60,
          ),
        ],
        now: DateTime(2026, 5, 29, 12, 0),
      );

      expect(state, BusinessOpenState.unknown);
    });
  });

  group('mapBusinessHoursToUi', () {
    test('marks invalid day slot as incomplete and closed day as cerrado', () {
      final ui = mapBusinessHoursToUi(
        hours: const [
          BusinessHours(
            dayOfWeek: 0,
            openMinutes: 9 * 60,
            closeMinutes: 18 * 60,
          ),
          BusinessHours(
            dayOfWeek: 4,
            openMinutes: 18 * 60,
            closeMinutes: 9 * 60,
          ),
        ],
        now: DateTime(2026, 5, 29, 12, 0),
      );

      expect(ui.todayLabel, 'Horario por confirmar');
      expect(ui.rows[4].isIncomplete, isTrue);
      expect(ui.rows[4].scheduleLabel, 'Horario por confirmar');
      expect(ui.rows[1].scheduleLabel, 'Cerrado');
    });
  });
}
