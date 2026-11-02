import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/daily_expense_reminder_service.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import 'transaction_controller.dart';

class TransactionFormController extends GetxController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController amountCtrl = TextEditingController();

  final Rx<TransactionType> type = TransactionType.expense.obs;
  final RxString category = AppConstants.expenseCategories.first.obs;
  final Rx<DateTime> date = DateTime.now().obs;

  TransactionModel? editing;
  bool get isEdit => editing != null;

  late final TransactionController _tx = Get.find<TransactionController>();

  @override
  void onInit() {
    super.onInit();
    final arg = Get.arguments;
    if (arg is TransactionModel) {
      editing = arg;
      titleCtrl.text = arg.title;
      amountCtrl.text = arg.amount.toString();
      type.value = arg.type;
      category.value = arg.category;
      date.value = arg.date;
    }
  }

  List<String> get categories => AppConstants.categoriesFor(type.value);

  void setType(TransactionType t) {
    type.value = t;
    final list = AppConstants.categoriesFor(t);
    if (!list.contains(category.value)) category.value = list.first;
  }

  Future<void> pickDate() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final picked = await showDatePicker(
      context: ctx,
      initialDate: date.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      final old = date.value;
      // Keep the time-of-day so ordering within a day stays stable.
      date.value = DateTime(
        picked.year,
        picked.month,
        picked.day,
        old.hour,
        old.minute,
        old.second,
      );
    }
  }

  String? validateTitle(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Please enter a title' : null;

  String? validateAmount(String? v) {
    final value = _parseAmount(v);
    if (value == null) return 'Enter a valid number';
    if (value <= 0) return 'Amount must be greater than 0';
    return null;
  }

  double? _parseAmount(String? v) =>
      double.tryParse((v ?? '').trim().replaceAll(',', ''));

  Future<void> save() async {
    if (!(formKey.currentState?.validate() ?? false)) return;

    final model = TransactionModel(
      id: editing?.id ?? TransactionModel.generateId(),
      title: titleCtrl.text.trim(),
      amount: _parseAmount(amountCtrl.text)!,
      date: date.value,
      category: category.value,
      type: type.value,
    );

    if (isEdit) {
      await _tx.updateTransaction(model);
    } else {
      await _tx.add(model);
    }
    Object? reminderError;
    final reminder = Get.find<DailyExpenseReminderService>();
    if (model.isExpense && reminder.isEnabled.value) {
      try {
        await reminder.acknowledgeActivity();
      } catch (error) {
        reminderError = error;
      }
    }
    Get.back();
    if (reminderError != null) {
      SnackbarHelper.error(
        'Expense saved, but reminder could not be refreshed: $reminderError',
      );
    } else {
      SnackbarHelper.success(
        isEdit ? 'Transaction updated' : 'Transaction added',
      );
    }
  }

  Future<void> deleteCurrent() async {
    final t = editing;
    if (t == null) return;
    final ok = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Delete transaction?'),
        content: Text('"${t.title}" will be removed.'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      Get.back(); // close form
      await _tx.delete(t);
    }
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    amountCtrl.dispose();
    super.onClose();
  }
}
