class HiveBoxes {
  HiveBoxes._();

  static const String transactions = 'transactions_box';
  static const String plans = 'plans_box';
  static const String account = 'account_box';
  static const String settings = 'settings_box';

  // Keep typeIds unique and never change them once data is saved.
  static const int transactionTypeId = 0;
  static const int transactionTypeEnumId = 1;
  static const int planTypeEnumId = 2;
  static const int planModelId = 3;
  static const int accountModelId = 4;
}
