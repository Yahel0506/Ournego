enum FloatingSheetState { collapsed, expanded, minimized }

extension FloatingSheetStateCodec on FloatingSheetState {
  String get storageValue {
    switch (this) {
      case FloatingSheetState.collapsed:
        return 'collapsed';
      case FloatingSheetState.expanded:
        return 'expanded';
      case FloatingSheetState.minimized:
        return 'minimized';
    }
  }

  static FloatingSheetState fromStorageValue(String value) {
    switch (value) {
      case 'expanded':
        return FloatingSheetState.expanded;
      case 'minimized':
        return FloatingSheetState.minimized;
      case 'collapsed':
      default:
        return FloatingSheetState.collapsed;
    }
  }
}
