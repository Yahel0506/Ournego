import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/core/theme/tokens/ournego_radius_tokens.dart';
import 'package:ournego/core/theme/tokens/ournego_spacing_tokens.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';

import '../../../../../core/ournego_text_styles.dart';

class BusinessHoursPicker extends ConsumerStatefulWidget {
  final int day;

  final AppSchedule? initialSchedule;
  final ValueChanged<AppSchedule?>? onChanged;

  const BusinessHoursPicker({
    super.key,
    required this.day,
    this.initialSchedule,
    this.onChanged,
  });

  static const int defaultOpenMinutes = 9 * 60;
  static const int defaultCloseMinutes = 18 * 60;

  @override
  ConsumerState<BusinessHoursPicker> createState() =>
      _BusinessHoursPickerState();
}

class _BusinessHoursPickerState extends ConsumerState<BusinessHoursPicker> {
  bool _isOpen = true;
  int _openMinutes = BusinessHoursPicker.defaultOpenMinutes;
  int _closeMinutes = BusinessHoursPicker.defaultCloseMinutes;

  @override
  void initState() {
    super.initState();

    final schedule = widget.initialSchedule;
    if (schedule != null) {
      _openMinutes = schedule.openMinutes;
      _closeMinutes = schedule.closeMinutes;
      _isOpen = true;
    }
  }

  AppSchedule? getSchedule() {
    if (!_isOpen) return null;

    return AppSchedule(
      dayOfWeek: widget.day,
      openMinutes: _openMinutes,
      closeMinutes: _closeMinutes,
    );
  }

  void setDefaults(AppSchedule? schedule) {
    if (schedule == null) return;

    setState(() {
      _openMinutes = schedule.openMinutes;
      _closeMinutes = schedule.closeMinutes;
      _isOpen = true;
    });
  }

  TimeOfDay get _openTime {
    return TimeOfDay(hour: _openMinutes ~/ 60, minute: _openMinutes % 60);
  }

  TimeOfDay get _closeTime {
    return TimeOfDay(hour: _closeMinutes ~/ 60, minute: _closeMinutes % 60);
  }

  void _emitChange() {
    final callback = widget.onChanged;
    if (callback == null) return;
    callback(getSchedule());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 28),
                AnimatedCrossFade(
                  firstChild: Container(),
                  secondChild: Container(
                    width: double.maxFinite,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        bottomRight: Radius.circular(OurnegoRadiusTokens.xl),
                        bottomLeft: Radius.circular(OurnegoRadiusTokens.xl),
                      ),
                      color: Theme.of(context).colorScheme.surface,
                      border: Border.all(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: 56),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Inicio:'),
                            const SizedBox(width: OurnegoSpacingTokens.xs),
                            GestureDetector(
                              onTap: () {
                                showTimePicker(
                                  context: context,
                                  initialTime: _openTime,
                                ).then((selectedTime) {
                                  if (selectedTime != null) {
                                    setState(() {
                                      _openMinutes =
                                          (selectedTime.hour * 60) +
                                          selectedTime.minute;
                                    });
                                    _emitChange();
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    OurnegoSpacingTokens.xs,
                                  ),
                                  child: Text(_openTime.format(context)),
                                ),
                              ),
                            ),
                            const SizedBox(width: OurnegoSpacingTokens.md),
                            Text('Cierre:'),
                            const SizedBox(width: OurnegoSpacingTokens.xs),
                            GestureDetector(
                              onTap: () {
                                showTimePicker(
                                  context: context,
                                  initialTime: _closeTime,
                                ).then((selectedTime) {
                                  if (selectedTime != null) {
                                    setState(() {
                                      _closeMinutes =
                                          (selectedTime.hour * 60) +
                                          selectedTime.minute;
                                    });
                                    _emitChange();
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    OurnegoSpacingTokens.xs,
                                  ),
                                  child: Text(_closeTime.format(context)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: OurnegoSpacingTokens.md),
                      ],
                    ),
                  ),
                  crossFadeState: _isOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 200),
                ),
              ],
            ),
            Container(
              width: double.maxFinite,
              height: 56,
              decoration: BoxDecoration(
                border: BoxBorder.all(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                borderRadius: BorderRadius.circular(OurnegoRadiusTokens.xl),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                children: [
                  const SizedBox(width: OurnegoSpacingTokens.md),
                  Expanded(
                    child: Text(switch (widget.day) {
                      0 => 'Lunes',
                      1 => 'Martes',
                      2 => 'Miércoles',
                      3 => 'Jueves',
                      4 => 'Viernes',
                      5 => 'Sábado',
                      6 => 'Domingo',
                      _ => 'Día inválido',
                    }, style: OurnegoTextStyles.body),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OurnegoSpacingTokens.md,
                    ),
                    child: Switch(
                      value: _isOpen,
                      onChanged: (value) {
                        setState(() {
                          _isOpen = value;
                        });
                        _emitChange();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: OurnegoSpacingTokens.md),
      ],
    );
  }
}
