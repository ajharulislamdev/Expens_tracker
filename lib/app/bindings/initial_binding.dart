import 'package:get/get.dart';
import '../../core/services/currency_settings.dart';
import '../../core/services/daily_expense_reminder_service.dart';
import '../../core/services/excel_service.dart';
import '../../core/services/pdf_service.dart';
import '../../core/services/storage_service.dart';
import '../../data/providers/hive_provider.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/plan_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../modules/auth/controllers/auth_controller.dart';
import '../../modules/home/controllers/home_controller.dart';
import '../../modules/home/controllers/plans_controller.dart';
import '../../modules/reports/controllers/report_controller.dart';
import '../../modules/transactions/controllers/transaction_controller.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(HiveProvider(), permanent: true);
    Get.put(
      CurrencySettings(Get.find<HiveProvider>().settingsBox),
      permanent: true,
    );
    Get.put(
      DailyExpenseReminderService(Get.find<HiveProvider>().settingsBox),
      permanent: true,
    );
    Get.put(AccountRepository(Get.find()), permanent: true);
    Get.put(AuthController(Get.find()), permanent: true);
    Get.put(TransactionRepository(Get.find()), permanent: true);
    Get.put(PlanRepository(Get.find()), permanent: true);

    Get.put(StorageService(), permanent: true);
    Get.put(PdfService(), permanent: true);
    Get.put(ExcelService(), permanent: true);

    // Order matters: Home/Report controllers depend on TransactionController.
    Get.put(TransactionController(Get.find()), permanent: true);
    Get.put(HomeController(), permanent: true);
    Get.put(PlansController(Get.find()), permanent: true);
    Get.put(ReportController(), permanent: true);
  }
}
