import 'package:ournego/features/map/domain/entities/business_hours.dart';
import 'package:ournego/features/map/presentation/models/map_search_models.dart';

class BusinessHoursDayRow {
  final int dayOfWeek;
  final String shortLabel;
  final String fullLabel;
  final String scheduleLabel;
  final bool isToday;
  final bool isClosed;
  final bool isIncomplete;

  const BusinessHoursDayRow({
    required this.dayOfWeek,
    required this.shortLabel,
    required this.fullLabel,
    required this.scheduleLabel,
    required this.isToday,
    required this.isClosed,
    required this.isIncomplete,
  });
}

class BusinessHoursUiData {
  final BusinessOpenState openState;
  final String todayLabel;
  final List<BusinessHoursDayRow> rows;

  const BusinessHoursUiData({
    required this.openState,
    required this.todayLabel,
    required this.rows,
  });
}

BusinessHoursUiData mapBusinessHoursToUi({
  required List<BusinessHours> hours,
  required DateTime now,
}) {
  final today = now.weekday - 1;
  final validByDay = _groupValidHoursByDay(hours);
  final invalidDays = _invalidDays(hours);
  final rows = List<BusinessHoursDayRow>.generate(7, (day) {
    final slot = validByDay[day]?.firstOrNull;
    final isIncomplete = slot == null && invalidDays.contains(day);
    return BusinessHoursDayRow(
      dayOfWeek: day,
      shortLabel: _shortDayLabel(day),
      fullLabel: _fullDayLabel(day),
      scheduleLabel: slot != null
          ? _formatRange(slot)
          : isIncomplete
          ? 'Horario por confirmar'
          : 'Cerrado',
      isToday: day == today,
      isClosed: slot == null,
      isIncomplete: isIncomplete,
    );
  });

  final openState = getBusinessOpenState(hours: hours, now: now);
  final todayRow = rows[today];
  final todayLabel = todayRow.isIncomplete
      ? 'Horario por confirmar'
      : todayRow.scheduleLabel;

  return BusinessHoursUiData(
    openState: openState,
    todayLabel: todayLabel,
    rows: rows,
  );
}

BusinessOpenState getBusinessOpenState({
  required List<BusinessHours> hours,
  required DateTime now,
}) {
  if (hours.isEmpty) {
    return BusinessOpenState.unknown;
  }

  final validByDay = _groupValidHoursByDay(hours);
  if (validByDay.isEmpty) {
    return BusinessOpenState.unknown;
  }

  final today = now.weekday - 1;
  final todaySlots = validByDay[today];
  if (todaySlots == null || todaySlots.isEmpty) {
    return BusinessOpenState.closed;
  }

  final minutesNow = (now.hour * 60) + now.minute;
  for (final slot in todaySlots) {
    if (minutesNow >= slot.openMinutes && minutesNow < slot.closeMinutes) {
      return BusinessOpenState.open;
    }
  }

  return BusinessOpenState.closed;
}

Map<int, List<BusinessHours>> _groupValidHoursByDay(List<BusinessHours> hours) {
  final grouped = <int, List<BusinessHours>>{};
  for (final slot in hours) {
    if (!_isValidSlot(slot)) {
      continue;
    }

    grouped.putIfAbsent(slot.dayOfWeek, () => <BusinessHours>[]).add(slot);
  }

  for (final entry in grouped.entries) {
    entry.value.sort((a, b) => a.openMinutes.compareTo(b.openMinutes));
  }

  return grouped;
}

Set<int> _invalidDays(List<BusinessHours> hours) {
  return hours
      .where(
        (slot) =>
            !_isValidSlot(slot) && slot.dayOfWeek >= 0 && slot.dayOfWeek <= 6,
      )
      .map((slot) => slot.dayOfWeek)
      .toSet();
}

bool _isValidSlot(BusinessHours slot) {
  return slot.dayOfWeek >= 0 &&
      slot.dayOfWeek <= 6 &&
      slot.openMinutes >= 0 &&
      slot.openMinutes < 24 * 60 &&
      slot.closeMinutes > 0 &&
      slot.closeMinutes <= 24 * 60 &&
      slot.closeMinutes > slot.openMinutes;
}

String _formatRange(BusinessHours slot) {
  return '${_formatMinutes(slot.openMinutes)} - ${_formatMinutes(slot.closeMinutes)}';
}

String _formatMinutes(int totalMinutes) {
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
}

String _shortDayLabel(int dayOfWeek) {
  switch (dayOfWeek) {
    case 0:
      return 'Lun';
    case 1:
      return 'Mar';
    case 2:
      return 'Mié';
    case 3:
      return 'Jue';
    case 4:
      return 'Vie';
    case 5:
      return 'Sáb';
    case 6:
      return 'Dom';
    default:
      return '--';
  }
}

String _fullDayLabel(int dayOfWeek) {
  switch (dayOfWeek) {
    case 0:
      return 'Lunes';
    case 1:
      return 'Martes';
    case 2:
      return 'Miércoles';
    case 3:
      return 'Jueves';
    case 4:
      return 'Viernes';
    case 5:
      return 'Sábado';
    case 6:
      return 'Domingo';
    default:
      return 'Día inválido';
  }
}
