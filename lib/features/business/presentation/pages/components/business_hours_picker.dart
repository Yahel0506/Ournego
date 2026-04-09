import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
                        bottomRight: Radius.circular(30),
                        bottomLeft: Radius.circular(30),
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
                            SizedBox(width: 8),
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
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(_openTime.format(context)),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Text('Cierre:'),
                            SizedBox(width: 8),
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
                                  padding: EdgeInsets.all(8.0),
                                  child: Text(_closeTime.format(context)),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                  crossFadeState: _isOpen
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: Duration(milliseconds: 200),
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
                borderRadius: BorderRadius.circular(30),
                color: Theme.of(context).colorScheme.surface,
              ),
              child: Row(
                children: [
                  SizedBox(width: 16),
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
                    padding: EdgeInsets.symmetric(horizontal: 16),
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
        SizedBox(height: 16),
      ],
    );
  }
}
