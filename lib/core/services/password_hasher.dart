import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

class PasswordHasher {
  PasswordHasher._();

  static const _iterations = 600000;

  static String generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(24, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static Future<String> hash(String password, String salt) {
    return compute(_deriveHash, [password, salt]);
  }

  static bool matches(String expected, String actual) {
    if (expected.length != actual.length) return false;
    var difference = 0;
    for (var index = 0; index < expected.length; index++) {
      difference |= expected.codeUnitAt(index) ^ actual.codeUnitAt(index);
    }
    return difference == 0;
  }

  static String _deriveHash(List<String> input) {
    final password = utf8.encode(input[0]);
    final salt = base64Url.decode(input[1]);
    final hmac = Hmac(sha256, password);
    final block = Uint8List(salt.length + 4)..setRange(0, salt.length, salt);
    block[block.length - 1] = 1;

    var digest = hmac.convert(block).bytes;
    final result = Uint8List.fromList(digest);
    for (var iteration = 1; iteration < _iterations; iteration++) {
      digest = hmac.convert(digest).bytes;
      for (var index = 0; index < result.length; index++) {
        result[index] ^= digest[index];
      }
    }
    return base64UrlEncode(result);
  }
}
