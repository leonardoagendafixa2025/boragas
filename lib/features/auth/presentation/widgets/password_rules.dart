class PasswordRules {
  const PasswordRules(this.password);

  final String password;

  bool get longEnough => password.length >= 8;
  bool get hasNumber => RegExp(r'[0-9]').hasMatch(password);
  bool get hasUpper => RegExp(r'[A-Z]').hasMatch(password);

  int get passed =>
      (longEnough ? 1 : 0) + (hasNumber ? 1 : 0) + (hasUpper ? 1 : 0);
}
