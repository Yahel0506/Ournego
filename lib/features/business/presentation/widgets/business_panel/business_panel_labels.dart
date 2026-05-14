import 'package:flutter/material.dart';
import 'package:ournego/features/business/domain/entities/app_schedule.dart';

Map<int, AppSchedule?> buildScheduleMap(List<AppSchedule> schedules) {
  final map = <int, AppSchedule?>{};
  for (var day = 0; day < 7; day++) {
    map[day] = null;
  }
  for (final schedule in schedules) {
    map[schedule.dayOfWeek] = schedule;
  }
  return map;
}

const List<DropdownMenuItem<int>> categoryOptions = [
  DropdownMenuItem(value: 0, child: Text('Bebida y Comida')),
  DropdownMenuItem(value: 1, child: Text('Tienda')),
  DropdownMenuItem(value: 2, child: Text('Servicio Personal')),
  DropdownMenuItem(value: 3, child: Text('Servicio Profesional')),
  DropdownMenuItem(value: 4, child: Text('Salud y Bienestar')),
  DropdownMenuItem(value: 5, child: Text('Educacion')),
  DropdownMenuItem(value: 6, child: Text('Construccion y Hogar')),
  DropdownMenuItem(value: 7, child: Text('Transporte')),
  DropdownMenuItem(value: 8, child: Text('Entretenimiento')),
  DropdownMenuItem(value: 9, child: Text('Tecnologia')),
  DropdownMenuItem(value: 10, child: Text('Negocio Informal')),
  DropdownMenuItem(value: 11, child: Text('Mezcla de categorias')),
  DropdownMenuItem(value: 12, child: Text('Otro')),
];

String businessTypeLabel(int category) {
  switch (category) {
    case 0:
      return 'Bebida y comida';
    case 1:
      return 'Tienda';
    case 2:
      return 'Servicio personal';
    case 3:
      return 'Servicio profesional';
    case 4:
      return 'Salud y bienestar';
    case 5:
      return 'Educacion';
    case 6:
      return 'Construccion y hogar';
    case 7:
      return 'Transporte';
    case 8:
      return 'Entretenimiento';
    case 9:
      return 'Tecnologia';
    case 10:
      return 'Negocio informal';
    case 11:
      return 'Mezcla de categorias';
    default:
      return 'Otro';
  }
}
