class SecurityPin {
  SecurityPin._();

  static const length = 6;

  static String? validate(String? value) {
    if (value == null || value.length != length) {
      return 'Enter all 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'PIN must contain 6 digits';
    }
    return null;
  }
}
