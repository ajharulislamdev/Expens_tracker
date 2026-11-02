import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_helper.dart';
import '../../../data/models/summary_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../transactions/controllers/transaction_controller.dart';

class HomeController extends GetxController {
  final TransactionController _tx = Get.find<TransactionController>();

  /// Bottom navigation index (0 home, 1 reports, 2 plans, 3 settings, 4 transactions).
  final RxInt tabIndex = 0.obs;

  final Rx<SummaryPeriod> period = SummaryPeriod.monthly.obs;
  final Rx<DateTime> selectedMonth =
      DateHelper.startOfMonth(DateTime.now()).obs;

  SummaryModel get summary => _tx.summaryFor(
        period.value,
        period.value == SummaryPeriod.monthly ? selectedMonth.value : null,
      );
  SummaryModel get overall => _tx.overall;
  List<TransactionModel> get allTransactions => _tx.all;
  List<TransactionModel> get recent => _tx.all.take(5).toList();
  double get weeklyBalanceChange {
    final now = DateTime.now();
    final thisWeek = _tx.summaryFor(SummaryPeriod.weekly, now).balance;
    final lastWeek = _tx
        .summaryFor(
          SummaryPeriod.weekly,
          now.subtract(const Duration(days: 7)),
        )
        .balance;
    return thisWeek - lastWeek;
  }

  String get periodLabel {
    final now = DateTime.now();
    switch (period.value) {
      case SummaryPeriod.daily:
        return DateFormat('EEEE, d MMM y').format(now);
      case SummaryPeriod.weekly:
        final s = DateHelper.startOfWeek(now);
        final e = DateHelper.endOfWeek(now);
        return '${DateFormat('d MMM').format(s)} - ${DateFormat('d MMM y').format(e)}';
      case SummaryPeriod.monthly:
        return DateFormat('MMMM y').format(selectedMonth.value);
    }
  }
}
