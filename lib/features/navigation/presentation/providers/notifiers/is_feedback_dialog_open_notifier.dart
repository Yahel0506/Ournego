import 'package:flutter_riverpod/flutter_riverpod.dart';

class IsFeedbackDialogOpenNotifier extends Notifier<bool> {
  @override
  bool build() {
    return false;
  }

  void setIsOpen() {
    state = true;
  }

  void setIsClosed() {
    state = false;
  }
}
