import 'package:flutter_riverpod/flutter_riverpod.dart';

class ModalStateNotifier extends Notifier<int> {
  @override
  int build() {
    return 0;
  }

  void changeStateTo(int newState) {
    state = newState;
  }
}
