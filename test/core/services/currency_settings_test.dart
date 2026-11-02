import 'dart:io';

import 'package:expense_tracker/core/services/currency_settings.dart';
import 'package:expense_tracker/core/utils/currency_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  late Directory tempDirectory;
  late Box<dynamic> settingsBox;

  setUpAll(() async {
    tempDirectory =
        await Directory.systemTemp.createTemp('currency_settings_test_');
    Hive.init(tempDirectory.path);
    settingsBox = await Hive.openBox<dynamic>('settings');
  });

  setUp(() async {
    await settingsBox.clear();
    CurrencySettings.current.value = CurrencySettings.defaultCurrency;
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDirectory.delete(recursive: true);
  });

  test('selecting a currency updates formatted amounts', () async {
    final settings = CurrencySettings(settingsBox)..onInit();
    await settings.select(
      CurrencySettings.supportedCurrencies
          .firstWhere((currency) => currency.code == 'USD'),
    );

    expect(CurrencyFormatter.format(1250), contains(r'$'));
  });

  test('custom currencies are saved and restored from settings', () async {
    final settings = CurrencySettings(settingsBox)..onInit();
    await settings.addCustom(code: 'sek', symbol: 'kr');

    final restored = CurrencySettings(settingsBox)..onInit();

    expect(restored.customCurrencies.single.code, 'SEK');
    expect(CurrencySettings.current.value.symbol, 'kr');
    expect(CurrencyFormatter.format(1250), contains('kr'));
  });
}
