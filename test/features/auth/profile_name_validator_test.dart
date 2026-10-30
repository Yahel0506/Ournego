import 'package:flutter_test/flutter_test.dart';
import 'package:ournego/features/auth/domain/profile_name_validator.dart';

void main() {
  test('rejects empty and whitespace-only names', () {
    expect(ProfileNameValidator.validate(null), isNotNull);
    expect(ProfileNameValidator.validate(''), isNotNull);
    expect(ProfileNameValidator.validate('   '), isNotNull);
  });

  test('rejects names longer than the limit, ignoring surrounding spaces', () {
    expect(
      ProfileNameValidator.validate('a' * (ProfileNameValidator.maxLength + 1)),
      isNotNull,
    );
    expect(
      ProfileNameValidator.validate(
        '  ${'a' * ProfileNameValidator.maxLength}  ',
      ),
      isNull,
    );
  });

  test('accepts a normal name', () {
    expect(ProfileNameValidator.validate('Ana López'), isNull);
  });
}
