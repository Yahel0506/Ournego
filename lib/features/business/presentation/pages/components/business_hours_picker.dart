import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/business/domain/entitites/app_schedule.dart';

import '../../../../../core/ournego_text_styles.dart';

class BusinessHoursPicker extends ConsumerStatefulWidget {
  final int day;

  BusinessHoursPicker({super.key, required this.day});

  bool _isOpen = true;
  TimeOfDay _openingTime = TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _closingTime = TimeOfDay(hour: 18, minute: 0);

  AppSchedule? getSchedule() {
    if (!_isOpen) {
      return null;
    } else {
      return AppSchedule(
        dayOfWeek: day,
        openTime: _openingTime,
        closeTime: _closingTime,
      );
    }
  }

  void setDefaults(AppSchedule? schedule) {
    if (schedule == null) {
      return;
    } else {
      _openingTime = schedule.openTime;
      _closingTime = schedule.closeTime;
    }
  }

  @override
  ConsumerState<BusinessHoursPicker> createState() =>
      _BusinessHoursPickerState();
}

class _BusinessHoursPickerState extends ConsumerState<BusinessHoursPicker> {
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
                                  initialTime: TimeOfDay.now(),
                                ).then((selectedTime) {
                                  if (selectedTime != null) {
                                    setState(() {
                                      widget._openingTime = selectedTime;
                                    });
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
                                  child: Text(
                                    widget._openingTime.format(context),
                                  ),
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
                                  initialTime: TimeOfDay.now(),
                                ).then((selectedTime) {
                                  if (selectedTime != null) {
                                    setState(() {
                                      widget._closingTime = selectedTime;
                                    });
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
                                  child: Text(
                                    widget._closingTime.format(context),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                  crossFadeState: widget._isOpen
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
                      value: widget._isOpen,
                      onChanged: (value) {
                        setState(() {
                          widget._isOpen = value;
                        });
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
