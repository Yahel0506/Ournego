import 'package:ournego/features/business/domain/entities/app_schedule.dart';
import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';

/// `dd/MM/yyyy HH:mm`, kept dependency-free like `formatReviewDate`.
String formatReviewDateTime(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} '
      '${two(date.hour)}:${two(date.minute)}';
}

/// What happened in one history row, in the reviewer's words.
String reviewLogEntryLabel(ReviewLogEntry entry) {
  final byReviewer = entry.actorRole == ReviewActorRole.reviewer;
  switch (entry.to) {
    case BusinessReviewStatus.pending:
      if (entry.from == null) return 'Solicitud de alta enviada';
      if (entry.from == BusinessReviewStatus.approved) {
        return 'Volvió a revisión por cambios en datos públicos';
      }
      return byReviewer
          ? 'Reabierta por revisión'
          : 'Reenviada a revisión por la dueña';
    case BusinessReviewStatus.approved:
      return 'Aprobada';
    case BusinessReviewStatus.rejected:
      return 'Rechazada';
    case BusinessReviewStatus.withdrawn:
      return byReviewer ? 'Retirada del mapa' : 'Retirada por la dueña';
  }
}

String reviewActorLabel(ReviewLogEntry entry) {
  switch (entry.actorRole) {
    case ReviewActorRole.reviewer:
      return 'Revisión';
    case ReviewActorRole.owner:
      return 'Dueña';
    case ReviewActorRole.system:
      return 'Sistema';
  }
}

/// `Lun 09:00-18:00 · Mar 09:00-18:00`, Monday first.
String reviewHoursSummary(List<AppSchedule> hours) {
  const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
  String time(int minutes) {
    final h = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }

  final sorted = [...hours]..sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
  return sorted
      .where((h) => h.dayOfWeek >= 0 && h.dayOfWeek <= 6)
      .map(
        (h) =>
            '${days[h.dayOfWeek]} ${time(h.openMinutes)}-'
            '${time(h.closeMinutes)}',
      )
      .join(' · ');
}
