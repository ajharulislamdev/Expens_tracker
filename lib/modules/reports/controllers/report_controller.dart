import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import '../../../core/services/excel_service.dart';
import '../../../core/services/pdf_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/date_helper.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../data/models/summary_model.dart';
import '../../../data/models/transaction_model.dart';
import '../../../data/models/transaction_type.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../transactions/controllers/transaction_controller.dart';

enum ReportPreset { thisWeek, thisMonth, lastMonth, thisYear, custom }

class ReportController extends GetxController {
  final TransactionController _tx = Get.find<TransactionController>();
  final StorageService _storage = Get.find<StorageService>();
  final PdfService _pdf = Get.find<PdfService>();
  final ExcelService _excel = Get.find<ExcelService>();

  final Rx<DateTime> from = DateHelper.startOfMonth(DateTime.now()).obs;
  final Rx<DateTime> to = DateHelper.endOfMonth(DateTime.now()).obs;
  final Rx<ReportPreset> preset = ReportPreset.thisMonth.obs;
  final Rxn<TransactionType> typeFilter =
      Rxn<TransactionType>(TransactionType.expense);
  final RxBool isExporting = false.obs;

  /// Transactions in range, oldest first (reads best in a report).
  List<TransactionModel> get items {
    final type = typeFilter.value;
    final list = _tx
        .inRange(from.value, to.value)
        .where((t) => type == null || t.type == type)
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  SummaryModel get summary => TransactionRepository.summarize(items);

  Map<String, double> get categoryTotals => _categoryTotals(items);

  String get comparisonLabel {
    switch (preset.value) {
      case ReportPreset.thisWeek:
        return 'vs last week';
      case ReportPreset.thisMonth:
        return 'vs last month';
      case ReportPreset.lastMonth:
        return 'vs month before';
      case ReportPreset.thisYear:
        return 'vs last year';
      case ReportPreset.custom:
        return 'vs previous period';
    }
  }

  Map<String, double> get comparisonCategoryTotals {
    late final DateTime comparisonFrom;
    late final DateTime comparisonTo;

    switch (preset.value) {
      case ReportPreset.thisWeek:
        comparisonFrom = from.value.subtract(const Duration(days: 7));
        comparisonTo = to.value.subtract(const Duration(days: 7));
      case ReportPreset.thisMonth:
      case ReportPreset.lastMonth:
        final monthOffset = preset.value == ReportPreset.thisMonth ? 1 : 2;
        final previousMonth =
            DateTime(from.value.year, from.value.month - monthOffset, 1);
        comparisonFrom = DateHelper.startOfMonth(previousMonth);
        comparisonTo = DateHelper.endOfMonth(previousMonth);
      case ReportPreset.thisYear:
        final previousYear = from.value.year - 1;
        comparisonFrom = DateTime(previousYear, 1, 1);
        comparisonTo = DateHelper.endOfDay(DateTime(previousYear, 12, 31));
      case ReportPreset.custom:
        final periodDays = to.value.difference(from.value).inDays + 1;
        comparisonTo = DateHelper.endOfDay(
          from.value.subtract(const Duration(days: 1)),
        );
        comparisonFrom = DateHelper.startOfDay(
          comparisonTo.subtract(Duration(days: periodDays - 1)),
        );
    }

    final previousItems = _tx
        .inRange(comparisonFrom, comparisonTo)
        .where((t) => typeFilter.value == null || t.type == typeFilter.value);
    return _categoryTotals(previousItems);
  }

  Map<String, double> _categoryTotals(Iterable<TransactionModel> transactions) {
    final totals = <String, double>{};
    for (final transaction in transactions) {
      totals.update(
        transaction.category,
        (value) => value + transaction.amount,
        ifAbsent: () => transaction.amount,
      );
    }
    return totals;
  }

  void applyPreset(ReportPreset p) {
    final now = DateTime.now();
    preset.value = p;
    switch (p) {
      case ReportPreset.thisWeek:
        from.value = DateHelper.startOfWeek(now);
        to.value = DateHelper.endOfWeek(now);
        break;
      case ReportPreset.thisMonth:
        from.value = DateHelper.startOfMonth(now);
        to.value = DateHelper.endOfMonth(now);
        break;
      case ReportPreset.lastMonth:
        final last = DateTime(now.year, now.month - 1, 1);
        from.value = DateHelper.startOfMonth(last);
        to.value = DateHelper.endOfMonth(last);
        break;
      case ReportPreset.thisYear:
        from.value = DateTime(now.year, 1, 1);
        to.value = DateHelper.endOfDay(DateTime(now.year, 12, 31));
        break;
      case ReportPreset.custom:
        pickCustomRange();
        break;
    }
  }

  Future<void> pickCustomRange() async {
    final ctx = Get.context;
    if (ctx == null) return;
    final picked = await showDateRangePicker(
      context: ctx,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: from.value, end: to.value),
    );
    if (picked != null) {
      preset.value = ReportPreset.custom;
      from.value = DateHelper.startOfDay(picked.start);
      to.value = DateHelper.endOfDay(picked.end);
    }
  }

  // ----------------------------------------------------------------- Export
  Future<void> exportPdf() => _export('pdf', () async {
        final Uint8List bytes = await _pdf.build(
          items: items,
          summary: summary,
          from: from.value,
          to: to.value,
        );
        return bytes;
      });

  Future<void> exportExcel() => _export('xlsx', () async {
        return _excel.build(
          items: items,
          summary: summary,
          from: from.value,
          to: to.value,
        );
      });

  Future<void> _export(String ext, Future<List<int>> Function() build) async {
    if (isExporting.value) return;
    if (items.isEmpty) {
      SnackbarHelper.info('No transactions in the selected period');
      return;
    }
    isExporting.value = true;
    try {
      final bytes = await build();
      final f = DateFormat('yyyyMMdd');
      final stamp = DateFormat('HHmmss').format(DateTime.now());
      final name =
          'ExpenseReport_${f.format(from.value)}_to_${f.format(to.value)}_$stamp.$ext';
      final result = await _storage.saveBytes(name, bytes);
      await _showResult(result);
    } catch (e) {
      SnackbarHelper.error('Export failed: $e');
    } finally {
      isExporting.value = false;
    }
  }

  Future<void> _showResult(ExportResult r) {
    return Get.dialog(
      AlertDialog(
        title: const Text('Report saved'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(r.path),
            if (r.usedFallback) ...[
              const SizedBox(height: 12),
              const Text(
                'The public Download folder was not accessible, so the file '
                'was saved in the app\'s own storage folder instead.',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Close')),
          FilledButton(
            onPressed: () async {
              Get.back();
              final res = await OpenFilex.open(r.path);
              if (res.type != ResultType.done) {
                SnackbarHelper.error('Could not open file: ${res.message}');
              }
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }
}
