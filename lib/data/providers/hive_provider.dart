import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/hive_boxes.dart';
import '../models/account_model.dart';
import '../models/plan_model.dart';
import '../models/transaction_model.dart';

/// Raw access to Hive boxes. Only repositories should use this.
class HiveProvider {
  Box<TransactionModel> get transactionBox =>
      Hive.box<TransactionModel>(HiveBoxes.transactions);

  Box<PlanModel> get planBox => Hive.box<PlanModel>(HiveBoxes.plans);

  Box<AccountModel> get accountBox => Hive.box<AccountModel>(HiveBoxes.account);

  Box<dynamic> get settingsBox => Hive.box<dynamic>(HiveBoxes.settings);
}
