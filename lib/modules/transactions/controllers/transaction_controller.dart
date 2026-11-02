import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/summary_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/repositories/transaction_repository.dart';

enum SortOption { dateDesc, dateAsc, amountDesc, amountAsc }

extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.dateDesc:
        return 'Newest first';
      case SortOption.dateAsc:
        return 'Oldest first';
      case SortOption.amountDesc:
        return 'Highest amount';
      case SortOption.amountAsc:
        return 'Lowest amount';
    }
  }
}

class TransactionController extends GetxController {
  TransactionController(this._repo);

  final TransactionRepository _repo;

  /// Every transaction, newest first.
  final RxList<TransactionModel> all = <TransactionModel>[].obs;

  // Filters
  final Rxn<TransactionType> filterType = Rxn<TransactionType>();
  final RxnString filterCategory = RxnString();
  final Rxn<DateTimeRange> filterRange = Rxn<DateTimeRange>();
  final RxString searchQuery = ''.obs;
  final Rx<SortOption> sortOption = SortOption.dateDesc.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  void load() {
    final list = _repo.getAll()..sort((a, b) => b.date.compareTo(a.date));
    all.assignAll(list);
  }

  // ------------------------------------------------------------------ CRUD
  Future<void> add(TransactionModel t) async {
    await _repo.add(t);
    load();
  }

  Future<void> updateTransaction(TransactionModel t) async {
    await _repo.update(t);
    load();
  }

  Future<void> delete(TransactionModel t) async {
    await _repo.delete(t.id);
    load();
    Get.closeAllSnackbars();
    Get.snackbar(
      'Deleted',
      '"${t.title}" was removed',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
      duration: const Duration(seconds: 4),
      mainButton: TextButton(
        onPressed: () async {
          await add(t);
          Get.closeAllSnackbars();
          SnackbarHelper.info('Restored');
        },
        child: const Text('UNDO'),
      ),
    );
  }

  // --------------------------------------------------------------- Filtering
  List<TransactionModel> get filtered {
    final type = filterType.value;
    final category = filterCategory.value;
    final range = filterRange.value;
    final query = searchQuery.value.trim().toLowerCase();
    final sort = sortOption.value;

    final list = all.where((t) {
      if (type != null && t.type != type) return false;
      if (category != null && t.category != category) return false;
      if (range != null &&
          !DateHelper.isInRange(
            t.date,
            DateHelper.startOfDay(range.start),
            DateHelper.endOfDay(range.end),
          )) {
        return false;
      }
      if (query.isNotEmpty &&
          !t.title.toLowerCase().contains(query) &&
          !t.category.toLowerCase().contains(query)) {
        return false;
      }
      return true;
    }).toList();

    switch (sort) {
      case SortOption.dateDesc:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case SortOption.dateAsc:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case SortOption.amountDesc:
        list.sort((a, b) => b.amount.compareTo(a.amount));
        break;
      case SortOption.amountAsc:
        list.sort((a, b) => a.amount.compareTo(b.amount));
        break;
    }
    return list;
  }

  bool get hasActiveFilters =>
      filterType.value != null ||
      filterCategory.value != null ||
      filterRange.value != null ||
      searchQuery.value.trim().isNotEmpty;

  void clearFilters() {
    filterType.value = null;
    filterCategory.value = null;
    filterRange.value = null;
    searchQuery.value = '';
  }

  Future<void> pickFilterRange() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final picked = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: filterRange.value,
    );
    if (picked != null) filterRange.value = picked;
  }

  /// All categories that appear in stored data (for the filter dropdown).
  List<String> get usedCategories {
    final set = all.map((t) => t.category).toSet().toList()..sort();
    return set;
  }

  // ---------------------------------------------------------------- Summary
  List<TransactionModel> inRange(DateTime from, DateTime to) =>
      all.where((t) => DateHelper.isInRange(t.date, from, to)).toList();

  SummaryModel summaryFor(SummaryPeriod period, [DateTime? ref]) {
    final items = inRange(
      DateHelper.startOf(period, ref),
      DateHelper.endOf(period, ref),
    );
    return TransactionRepository.summarize(items);
  }

  SummaryModel get overall => TransactionRepository.summarize(all);

  /// Expense totals per category for [period], largest first.
  Map<String, double> expenseByCategory(SummaryPeriod period, [DateTime? ref]) {
    final items = inRange(
      DateHelper.startOf(period, ref),
      DateHelper.endOf(period, ref),
    ).where((t) => t.isExpense);

    final map = <String, double>{};
    for (final t in items) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return {for (final e in entries) e.key: e.value};
  }
}
