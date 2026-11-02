import 'package:expense_tracker/core/utils/mobile_number.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MobileNumber', () {
    test('accepts international numbers with common formatting', () {
      expect(MobileNumber.validate('+880 1712-345678'), isNull);
    });

    test('rejects numbers outside the supported length', () {
      expect(MobileNumber.validate('12345'), isNotNull);
      expect(MobileNumber.validate('1234567890123456'), isNotNull);
    });

    test('normalizes a formatted number for matching', () {
      expect(MobileNumber.digitsOnly('+880 (1712) 345-678'), '8801712345678');
    });
  });
}
