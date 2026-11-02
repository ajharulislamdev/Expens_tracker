import 'package:expense_tracker/core/utils/security_pin.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SecurityPin', () {
    test('accepts a six-digit PIN', () {
      expect(SecurityPin.validate('482913'), isNull);
    });

    test('rejects short, long, or non-numeric PINs', () {
      expect(SecurityPin.validate('48291'), isNotNull);
      expect(SecurityPin.validate('4829137'), isNotNull);
      expect(SecurityPin.validate('12a456'), isNotNull);
    });
  });
}
