import 'dart:io';
import 'dart:typed_data';
import 'package:expense_tracker/data/models/account_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory hiveDirectory;

  setUpAll(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('expense-account-');
    Hive.init(hiveDirectory.path);
    Hive.registerAdapter(AccountModelAdapter());
  });

  tearDownAll(() async {
    await Hive.close();
    await hiveDirectory.delete(recursive: true);
  });

  test('persists profile and photo bytes in Hive', () async {
    final account = AccountModel(
      name: 'Test User',
      phoneNumber: '+880 1712-345678',
      passwordSalt: 'salt',
      passwordHash: 'hash',
      photoBytes: Uint8List.fromList([1, 2, 3, 4]),
      isLoggedIn: true,
      usesPin: true,
    );

    final box = await Hive.openBox<AccountModel>('account_test');
    await box.put('profile', account);
    await box.close();

    final reopenedBox = await Hive.openBox<AccountModel>('account_test');
    final restored = reopenedBox.get('profile');

    expect(restored?.name, account.name);
    expect(restored?.phoneNumber, account.phoneNumber);
    expect(restored?.photoBytes, account.photoBytes);
    expect(restored?.isLoggedIn, isTrue);
    expect(restored?.usesPin, isTrue);
    await reopenedBox.close();
  });
}
