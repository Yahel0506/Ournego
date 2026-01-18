import 'package:flutter/material.dart';

class LocalAppNavigationBarDatasource {
  List<String> getNavigationBarItemsLabels() {
    return ['Inicio', 'Mapa', 'Mi Negocio'];
  }

  List<IconData> getNavigationBarItemsIcons() {
    return [Icons.home_rounded, Icons.location_on_rounded, Icons.store_rounded];
  }
}
