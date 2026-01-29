import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/navigation/data/datasources/local_app_navigation_bar_datasource.dart';
import 'package:ournego/features/navigation/presentation/providers/notifiers/navigation_index_notifier.dart';

import 'notifiers/is_feedback_dialog_open_notifier.dart';

final appNavigationBarProvider = Provider<LocalAppNavigationBarDatasource>((
  ref,
) {
  final datasource = LocalAppNavigationBarDatasource();
  return datasource;
});

final pageControllerProvider = Provider<PageController>((ref) {
  final controller = PageController(initialPage: 1);

  ref.onDispose(() {
    controller.dispose();
  });

  return controller;
});

final navigationIndexProvider = NotifierProvider<NavigationIndexNotifier, int>(
  NavigationIndexNotifier.new,
);

final isFeedbackDialogOpenProvider =
    NotifierProvider<IsFeedbackDialogOpenNotifier, bool>(
      IsFeedbackDialogOpenNotifier.new,
    );
