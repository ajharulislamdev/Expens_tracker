import 'package:get/get.dart';
import '../../modules/home/views/main_view.dart';
import '../../modules/transactions/views/transaction_form_view.dart';
import '../bindings/transaction_binding.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    GetPage(name: AppRoutes.main, page: () => const MainView()),
    GetPage(
      name: AppRoutes.form,
      page: () => const TransactionFormView(),
      binding: TransactionBinding(),
      transition: Transition.cupertino,
    ),
  ];
}
