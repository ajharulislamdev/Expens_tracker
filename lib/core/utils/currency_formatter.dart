import 'package:intl/intl.dart';
import '../services/currency_settings.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static final NumberFormat _plain = NumberFormat('#,##0.00');

  static String get currencyCode => CurrencySettings.current.value.code;
  static String get currencySymbol => CurrencySettings.current.value.symbol;

  static String format(double value) => NumberFormat.currency(
        symbol: currencySymbol,
        decimalDigits: 2,
      ).format(value);

  /// e.g. 1,250.00 (used in PDF where the default font lacks some symbols)
  static String plain(double value) => _plain.format(value);
}
