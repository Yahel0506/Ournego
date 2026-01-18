class AuthScreenText {
  final String title;
  final String primaryButton;
  final String primaryInstruction;
  final String primaryHint;
  String? secondaryInstruction;
  String? secondaryHint;
  String? forgotPassword;
  String? signUp;
  List<String>? passwordRules;

  AuthScreenText({
    required this.title,
    required this.primaryButton,
    required this.primaryInstruction,
    required this.primaryHint,
    this.secondaryInstruction,
    this.secondaryHint,
    this.forgotPassword,
    this.signUp,
    this.passwordRules,
  });
}
