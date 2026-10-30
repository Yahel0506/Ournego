/// Rules for the display name a person can set on their profile.
class ProfileNameValidator {
  ProfileNameValidator._();

  static const int maxLength = 50;

  /// Returns the message to show when [value] is not acceptable, or `null`
  /// when it is. Surrounding whitespace is ignored.
  static String? validate(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Escribe tu nombre';
    if (name.length > maxLength) {
      return 'Usa máximo $maxLength caracteres';
    }
    return null;
  }
}
