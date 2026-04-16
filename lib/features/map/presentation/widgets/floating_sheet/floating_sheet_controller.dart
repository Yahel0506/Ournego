import 'package:flutter/foundation.dart';

import 'package:ournego/features/map/presentation/widgets/floating_sheet/floating_sheet_state.dart';
import 'package:ournego/features/map/presentation/widgets/floating_sheet/models/sheet_business_data.dart';

class FloatingSheetController extends ChangeNotifier {
  FloatingSheetState _state = FloatingSheetState.collapsed;
  SheetBusinessData? _activeBusiness;
  final List<SheetBusinessData> _minimizedBusinesses = [];
  bool _pendingClearActive = false;
  bool _pendingMinimizeToStack = false;

  FloatingSheetState get state => _state;
  SheetBusinessData? get activeBusiness => _activeBusiness;
  List<SheetBusinessData> get minimizedBusinesses =>
      List<SheetBusinessData>.unmodifiable(_minimizedBusinesses);

  bool get hasActiveBusiness => _activeBusiness != null;
  bool get pendingClearActive => _pendingClearActive;
  bool get pendingMinimizeToStack => _pendingMinimizeToStack;

  void openBusiness(SheetBusinessData business) {
    final current = _activeBusiness;
    if (current != null && current.id != business.id) {
      _pushToMinimized(current);
    }

    _activeBusiness = business;
    _pendingClearActive = false;
    _pendingMinimizeToStack = false;
    _state = FloatingSheetState.minimized;
    notifyListeners();

    Future<void>.delayed(const Duration(milliseconds: 40), () {
      if (_activeBusiness?.id != business.id) {
        return;
      }

      _state = FloatingSheetState.collapsed;
      notifyListeners();
    });
  }

  void closeActiveBusiness() {
    if (_activeBusiness == null) {
      return;
    }

    _pendingClearActive = true;
    _pendingMinimizeToStack = false;
    _state = FloatingSheetState.minimized;
    notifyListeners();
  }

  void finalizeTransitionOut() {
    if (!_pendingClearActive) {
      return;
    }

    _activeBusiness = null;
    _pendingClearActive = false;
    _pendingMinimizeToStack = false;
    notifyListeners();
  }

  void closeIfCollapsed() {
    if (_state != FloatingSheetState.collapsed) {
      return;
    }

    closeActiveBusiness();
  }

  void minimizeActiveBusiness() {
    final current = _activeBusiness;
    if (current == null) return;

    _pushToMinimized(current);
    _pendingClearActive = true;
    _pendingMinimizeToStack = true;
    _state = FloatingSheetState.minimized;
    notifyListeners();
  }

  void restoreFromMinimized(String businessId) {
    final index = _minimizedBusinesses.indexWhere((b) => b.id == businessId);
    if (index < 0) {
      return;
    }

    final selected = _minimizedBusinesses.removeAt(index);
    final current = _activeBusiness;
    if (current != null && current.id != selected.id) {
      _pushToMinimized(current);
    }

    _activeBusiness = selected;
    _pendingClearActive = false;
    _pendingMinimizeToStack = false;
    _state = FloatingSheetState.collapsed;
    notifyListeners();
  }

  void removeFromMinimized(String businessId) {
    _minimizedBusinesses.removeWhere((b) => b.id == businessId);
    notifyListeners();
  }

  void transitionTo(FloatingSheetState nextState) {
    if (_activeBusiness == null && nextState != FloatingSheetState.minimized) {
      return;
    }

    if (_state == nextState) {
      return;
    }

    _state = nextState;
    notifyListeners();
  }

  void toggleExpandedCollapsed() {
    if (_state == FloatingSheetState.expanded) {
      transitionTo(FloatingSheetState.collapsed);
      return;
    }

    transitionTo(FloatingSheetState.expanded);
  }

  void handleVerticalDragEnd({
    required double velocity,
    required double currentHeight,
    required double collapsedHeight,
    required double expandedHeight,
  }) {
    if (velocity < -500) {
      transitionTo(FloatingSheetState.expanded);
      return;
    }

    if (velocity > 500) {
      if (_state == FloatingSheetState.collapsed) {
        closeActiveBusiness();
      } else {
        transitionTo(FloatingSheetState.collapsed);
      }
      return;
    }

    final collapsedDistance = (currentHeight - collapsedHeight).abs();
    final expandedDistance = (expandedHeight - currentHeight).abs();

    if (expandedDistance < collapsedDistance) {
      transitionTo(FloatingSheetState.expanded);
      return;
    }

    transitionTo(FloatingSheetState.collapsed);
  }

  bool toggleFavorite() {
    final current = _activeBusiness;
    if (current == null) {
      return false;
    }

    final updated = current.copyWith(isFavorite: !current.isFavorite);
    _activeBusiness = updated;
    notifyListeners();
    return updated.isFavorite;
  }

  void _pushToMinimized(SheetBusinessData business) {
    _minimizedBusinesses.removeWhere((b) => b.id == business.id);
    _minimizedBusinesses.insert(0, business);

    if (_minimizedBusinesses.length > 4) {
      _minimizedBusinesses.removeLast();
    }
  }
}
