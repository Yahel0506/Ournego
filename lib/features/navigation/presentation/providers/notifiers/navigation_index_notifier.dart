import 'package:flutter_riverpod/flutter_riverpod.dart';

class NavigationIndexNotifier extends Notifier<int> {
  @override
  int build() {
    return 1;
  }

  void setIndex(int index) {
    state = index;
  }
}
