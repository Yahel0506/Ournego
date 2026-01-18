import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ournego/features/map/domain/entities/business.dart';

class SelectedBusinessNotifier extends Notifier<Business?> {
  @override
  Business? build() {
    return null;
  }

  void selectedBusiness(Business business) {
    state = business;
  }
}
