import 'package:flutter/material.dart';
import 'package:ournego/core/ournego_text_styles.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_semantic_tokens.dart';
import 'package:ournego/features/map/domain/entities/business_hours.dart';
import 'package:ournego/features/map/presentation/mappers/business_hours_ui_mapper.dart';
import 'package:ournego/features/map/presentation/models/map_search_models.dart';

class BusinessHoursCompactCard extends StatelessWidget {
  const BusinessHoursCompactCard({super.key, required this.hours, this.now});

  final List<BusinessHours> hours;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hoursUi = mapBusinessHoursToUi(
      hours: hours,
      now: now ?? DateTime.now(),
    );
    final badge = _statusBadge(context: context, state: hoursUi.openState);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.xl),
        border: Border.all(
          color: OurnegoSemanticTokens.borderSubtle(colorScheme),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(OurnegoRadiusTokens.full),
                ),
                child: Icon(Icons.schedule_rounded, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Horario',
                  style: OurnegoTextStyles.body.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              badge,
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: Text(
              hoursUi.openState == BusinessOpenState.unknown
                  ? 'Horario no disponible'
                  : 'Hoy: ${hoursUi.todayLabel}',
              style: OurnegoTextStyles.body.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          if (hoursUi.openState != BusinessOpenState.unknown) ...[
            const SizedBox(height: 10),
            ...hoursUi.rows.map((row) => _DayRow(row: row)),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge({
    required BuildContext context,
    required BusinessOpenState state,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (state) {
      BusinessOpenState.open => OurnegoSemanticTokens.success(
        colorScheme,
      ).withValues(alpha: 0.16),
      BusinessOpenState.closed => colorScheme.inverseSurface.withValues(
        alpha: 0.08,
      ),
      BusinessOpenState.unknown => colorScheme.surface.withValues(alpha: 0.55),
    };
    final foregroundColor = switch (state) {
      BusinessOpenState.open => OurnegoSemanticTokens.success(colorScheme),
      BusinessOpenState.closed => colorScheme.onSurface.withValues(alpha: 0.82),
      BusinessOpenState.unknown => colorScheme.onSurface.withValues(
        alpha: 0.72,
      ),
    };
    final label = switch (state) {
      BusinessOpenState.open => 'Abierto',
      BusinessOpenState.closed => 'Cerrado',
      BusinessOpenState.unknown => 'Sin horario',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(OurnegoRadiusTokens.pill),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: OurnegoTextStyles.badge.copyWith(color: foregroundColor),
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.row});

  final BusinessHoursDayRow row;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final highlightColor = row.isToday
        ? colorScheme.primary.withValues(alpha: 0.12)
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: highlightColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: row.isToday
              ? colorScheme.outline.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              row.shortLabel,
              style: OurnegoTextStyles.body.copyWith(
                fontSize: 12,
                fontWeight: row.isToday ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              row.scheduleLabel,
              style: OurnegoTextStyles.body.copyWith(
                fontSize: 12,
                color: row.isIncomplete
                    ? colorScheme.onSurface.withValues(alpha: 0.72)
                    : colorScheme.onSurface.withValues(
                        alpha: row.isClosed ? 0.66 : 0.86,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
