class MobileNumber {
  MobileNumber._();

  static String digitsOnly(String value) => value.replaceAll(RegExp(r'\D'), '');

  static String? validate(String? value) {
    final number = digitsOnly(value ?? '');
    if (number.isEmpty) return 'Enter your mobile number';
    if (number.length < 7 || number.length > 15) {
      return 'Enter a valid mobile number with country code';
    }
    return null;
  }
}
