import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../data/models/summary_model.dart';
import '../../data/models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class ExcelService {
  List<int> build({
    required List<TransactionModel> items,
    required SummaryModel summary,
    required DateTime from,
    required DateTime to,
  }) {
    final excel = Excel.createExcel();
    final defaultName = excel.getDefaultSheet() ?? 'Sheet1';
    excel.rename(defaultName, 'Transactions');

    final headerStyle = CellStyle(
      bold: true,
      backgroundColorHex: ExcelColor.fromHexString('#DDE6F0'),
    );
    final dateFmt = DateFormat('yyyy-MM-dd');

    // ---- Transactions sheet ----
    final sheet = excel['Transactions'];
    final headers = [
      'Date',
      'Title',
      'Category',
      'Type',
      'Amount (${CurrencyFormatter.currencyCode})',
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());
    for (var i = 0; i < headers.length; i++) {
      sheet
          .cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0))
          .cellStyle = headerStyle;
    }
    for (final t in items) {
      sheet.appendRow([
        TextCellValue(dateFmt.format(t.date)),
        TextCellValue(t.title),
        TextCellValue(t.category),
        TextCellValue(t.isIncome ? 'Income' : 'Expense'),
        DoubleCellValue(t.amount),
      ]);
    }
    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 30);
    sheet.setColumnWidth(2, 18);
    sheet.setColumnWidth(3, 12);
    sheet.setColumnWidth(4, 18);

    // ---- Summary sheet ----
    final s = excel['Summary'];
    s.appendRow([
      TextCellValue('Period'),
      TextCellValue('${dateFmt.format(from)} to ${dateFmt.format(to)}')
    ]);
    s.appendRow(
        [TextCellValue('Total Income'), DoubleCellValue(summary.income)]);
    s.appendRow(
        [TextCellValue('Total Expense'), DoubleCellValue(summary.expense)]);
    s.appendRow([TextCellValue('Balance'), DoubleCellValue(summary.balance)]);
    s.appendRow([TextCellValue('Transactions'), IntCellValue(summary.count)]);
    for (var r = 0; r < 5; r++) {
      s
          .cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: r))
          .cellStyle = headerStyle;
    }
    s.setColumnWidth(0, 18);
    s.setColumnWidth(1, 28);

    excel.setDefaultSheet('Transactions');
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to encode Excel file');
    }
    return bytes;
  }
}
