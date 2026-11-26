/// A user's answer to "¿Conoces este negocio?".
///
/// Mirrors `business_confirmations.answer`. Whether the answer counts toward
/// verification is decided by the server and is never exposed to the client.
enum BusinessConfirmationAnswer {
  yes('yes'),
  noExists('no_exists'),
  unsure('unsure');

  const BusinessConfirmationAnswer(this.wire);

  /// The database value.
  final String wire;

  /// Parses the database value, or returns `null` for unknown values.
  static BusinessConfirmationAnswer? tryFromWire(String? value) {
    for (final answer in values) {
      if (answer.wire == value) return answer;
    }
    return null;
  }
}
