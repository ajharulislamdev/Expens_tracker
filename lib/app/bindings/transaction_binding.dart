import 'package:get/get.dart';
import '../../modules/transactions/controllers/transaction_form_controller.dart';

class TransactionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TransactionFormController>(() => TransactionFormController());
  }
}
