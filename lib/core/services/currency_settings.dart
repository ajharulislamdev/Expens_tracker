import 'package:get/get.dart';
import 'package:hive/hive.dart';

class CurrencyOption {
  const CurrencyOption({
    required this.code,
    required this.symbol,
    this.isCustom = false,
  });

  final String code;
  final String symbol;
  final bool isCustom;

  String get label => '$code ($symbol)';

  Map<String, String> toMap() => {'code': code, 'symbol': symbol};

  static CurrencyOption? fromMap(dynamic value) {
    if (value is! Map) return null;
    final code = value['code'];
    final symbol = value['symbol'];
    if (code is! String || symbol is! String) return null;
    final normalizedCode = code.trim().toUpperCase();
    final normalizedSymbol = symbol.trim();
    if (normalizedCode.isEmpty || normalizedSymbol.isEmpty) return null;
    return CurrencyOption(
      code: normalizedCode,
      symbol: normalizedSymbol,
      isCustom: true,
    );
  }
}

class CurrencySettings extends GetxService {
  CurrencySettings(this._box);

  final Box<dynamic> _box;

  static const defaultCurrency = CurrencyOption(code: 'BDT', symbol: '৳');
  static final Rx<CurrencyOption> current = defaultCurrency.obs;

  static const supportedCurrencies = [
    defaultCurrency,
    CurrencyOption(code: 'USD', symbol: r'$'),
    CurrencyOption(code: 'EUR', symbol: '€'),
    CurrencyOption(code: 'GBP', symbol: '£'),
    CurrencyOption(code: 'INR', symbol: '₹'),
    CurrencyOption(code: 'JPY', symbol: '¥'),
    CurrencyOption(code: 'CAD', symbol: 'CA\$'),
    CurrencyOption(code: 'AUD', symbol: 'A\$'),
    CurrencyOption(code: 'PKR', symbol: '₨'),
    CurrencyOption(code: 'AED', symbol: 'د.إ'),
    CurrencyOption(code: 'SAR', symbol: '﷼'),
    CurrencyOption(code: 'CHF', symbol: 'CHF'),
  ];

  final RxList<CurrencyOption> customCurrencies = <CurrencyOption>[].obs;

  List<CurrencyOption> get options => [
        ...supportedCurrencies,
        ...customCurrencies,
      ];

  @override
  void onInit() {
    super.onInit();
    final storedCustom = _box.get('customCurrencies');
    if (storedCustom is List) {
      customCurrencies.assignAll(
        storedCustom.map(CurrencyOption.fromMap).whereType<CurrencyOption>(),
      );
    }

    final storedCode = _box.get('currencyCode');
    final storedSymbol = _box.get('currencySymbol');
    final match = options.firstWhereOrNull(
      (option) => option.code == storedCode && option.symbol == storedSymbol,
    );
    current.value = match ?? defaultCurrency;
  }

  Future<void> select(CurrencyOption option) async {
    if (!options.any(
      (item) => item.code == option.code && item.symbol == option.symbol,
    )) {
      throw ArgumentError.value(option, 'option', 'Unsupported currency');
    }
    await _box.putAll({
      'currencyCode': option.code,
      'currencySymbol': option.symbol,
    });
    current.value = option;
  }

  Future<void> addCustom({
    required String code,
    required String symbol,
  }) async {
    final normalizedCode = code.trim().toUpperCase();
    final normalizedSymbol = symbol.trim();
    if (normalizedCode.isEmpty || normalizedSymbol.isEmpty) {
      throw ArgumentError('Currency code and symbol are required.');
    }
    if (options.any((option) => option.code == normalizedCode)) {
      throw ArgumentError.value(
        normalizedCode,
        'code',
        'This currency code already exists.',
      );
    }

    final option = CurrencyOption(
      code: normalizedCode,
      symbol: normalizedSymbol,
      isCustom: true,
    );
    final updated = [...customCurrencies, option];
    await _box.put(
      'customCurrencies',
      updated.map((currency) => currency.toMap()).toList(),
    );
    customCurrencies.assignAll(updated);
    await select(option);
  }

  Future<void> removeCustom(CurrencyOption option) async {
    if (!option.isCustom) {
      throw ArgumentError.value(
          option, 'option', 'Built-in currencies cannot be removed.');
    }

    final updated =
        customCurrencies.where((item) => item.code != option.code).toList();
    await _box.put(
      'customCurrencies',
      updated.map((currency) => currency.toMap()).toList(),
    );
    customCurrencies.assignAll(updated);
    if (current.value.code == option.code) {
      await select(defaultCurrency);
    }
  }
}
