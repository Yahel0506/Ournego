import 'package:flutter_test/flutter_test.dart';

import 'package:ournego/features/business/domain/entities/business_review_status.dart';
import 'package:ournego/features/moderation/domain/entities/review_log_entry.dart';
import 'package:ournego/features/moderation/presentation/widgets/review_labels.dart';

ReviewLogEntry _entry(
  BusinessReviewStatus? from,
  BusinessReviewStatus to,
  ReviewActorRole role,
) => ReviewLogEntry(
  id: 1,
  from: from,
  to: to,
  actorRole: role,
  actorId: null,
  reason: null,
  createdAt: DateTime(2026, 11, 3, 9, 5),
);

void main() {
  test('formats date and time', () {
    expect(
      formatReviewDateTime(DateTime(2026, 11, 3, 9, 5)),
      '03/11/2026 09:05',
    );
  });

  test('describes every kind of change', () {
    const s = BusinessReviewStatus.values;
    String label(
      BusinessReviewStatus? from,
      BusinessReviewStatus to,
      ReviewActorRole r,
    ) => reviewLogEntryLabel(_entry(from, to, r));
    expect(
      label(null, s[0], ReviewActorRole.owner),
      'Solicitud de alta enviada',
    );
    expect(
      label(
        BusinessReviewStatus.approved,
        BusinessReviewStatus.pending,
        ReviewActorRole.owner,
      ),
      'Volvió a revisión por cambios en datos públicos',
    );
    expect(
      label(
        BusinessReviewStatus.rejected,
        BusinessReviewStatus.pending,
        ReviewActorRole.owner,
      ),
      'Reenviada a revisión por la dueña',
    );
    expect(
      label(
        BusinessReviewStatus.pending,
        BusinessReviewStatus.approved,
        ReviewActorRole.reviewer,
      ),
      'Aprobada',
    );
    expect(
      label(
        BusinessReviewStatus.pending,
        BusinessReviewStatus.rejected,
        ReviewActorRole.reviewer,
      ),
      'Rechazada',
    );
    expect(
      label(
        BusinessReviewStatus.approved,
        BusinessReviewStatus.withdrawn,
        ReviewActorRole.reviewer,
      ),
      'Retirada del mapa',
    );
    expect(
      label(
        BusinessReviewStatus.approved,
        BusinessReviewStatus.withdrawn,
        ReviewActorRole.owner,
      ),
      'Retirada por la dueña',
    );
  });
}
