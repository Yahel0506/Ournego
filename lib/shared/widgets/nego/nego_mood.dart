enum NegoMood {
  idle,
  excited,
  winking,
  looking,

  /// Internal-only, temporary mood triggered by tap/click.
  ///
  /// Note: This should not be used as a persistent external `mood` in product
  /// code. The intended flow is `temporaryMood = happy` and then reset to null.
  happy,
}

enum NegoLookVertical { up, down }
