import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/bindings/initial_binding.dart';
import 'app/routes/app_pages.dart';
import 'app/routes/app_routes.dart';
import 'app/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/constants/hive_boxes.dart';
import 'data/models/account_model.dart';
import 'data/models/plan_model.dart';
import 'data/models/transaction_model.dart';
import 'data/models/transaction_type.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(TransactionTypeAdapter());
  Hive.registerAdapter(TransactionModelAdapter());
  Hive.registerAdapter(PlanTypeAdapter());
  Hive.registerAdapter(PlanModelAdapter());
  Hive.registerAdapter(AccountModelAdapter());
  await Hive.openBox<TransactionModel>(HiveBoxes.transactions);
  await Hive.openBox<PlanModel>(HiveBoxes.plans);
  await Hive.openBox<AccountModel>(HiveBoxes.account);
  await Hive.openBox<dynamic>(HiveBoxes.settings);

  runApp(const ExpenseTrackerApp());
}

class ExpenseTrackerApp extends StatelessWidget {
  const ExpenseTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.main,
      getPages: AppPages.pages,
    );
  }
}
