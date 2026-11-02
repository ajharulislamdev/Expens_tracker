import 'package:expense_tracker/core/services/password_hasher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('derives a PBKDF2-HMAC-SHA256 hash', () async {
    final hash = await PasswordHasher.hash('password', 'c2FsdA==');

    expect(hash, 'Zpz-UkghFv2hqiy-QJsvVsjkVjdSt6KPbqq2FO4AUXg=');
  });

  test('compares derived hashes without accepting a different value', () {
    const storedHash = 'Zpz-UkghFv2hqiy-QJsvVsjkVjdSt6KPbqq2FO4AUXg=';

    expect(PasswordHasher.matches(storedHash, storedHash), isTrue);
    expect(PasswordHasher.matches(storedHash, 'incorrect-hash'), isFalse);
  });
}
