import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../data/models/summary_model.dart';
import '../../data/models/transaction_model.dart';
import '../utils/currency_formatter.dart';

class PdfService {
  Future<Uint8List> build({
    required List<TransactionModel> items,
    required SummaryModel summary,
    required DateTime from,
    required DateTime to,
  }) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('dd MMM yyyy');
    final code = CurrencyFormatter.currencyCode;

    final rows = items
        .map((t) => [
              dateFmt.format(t.date),
              t.title,
              t.category,
              t.isIncome ? 'Income' : 'Expense',
              '${t.isIncome ? '+' : '-'}${CurrencyFormatter.plain(t.amount)}',
            ])
        .toList();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        footer: (ctx) => pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Text(
            'Page ${ctx.pageNumber} / ${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
        ),
        build: (ctx) => [
          pw.Text(
            'Expense Report',
            style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${dateFmt.format(from)} - ${dateFmt.format(to)}',
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700),
          ),
          pw.Text(
            'Generated: ${DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            children: [
              _box('Income', CurrencyFormatter.plain(summary.income), code,
                  PdfColors.green700),
              pw.SizedBox(width: 8),
              _box('Expense', CurrencyFormatter.plain(summary.expense), code,
                  PdfColors.red700),
              pw.SizedBox(width: 8),
              _box('Balance', CurrencyFormatter.plain(summary.balance), code,
                  PdfColors.blue700),
            ],
          ),
          pw.SizedBox(height: 18),
          if (rows.isEmpty)
            pw.Text('No transactions in this period.')
          else
            pw.TableHelper.fromTextArray(
              headers: ['Date', 'Title', 'Category', 'Type', 'Amount ($code)'],
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellAlignments: {
                0: pw.Alignment.centerLeft,
                1: pw.Alignment.centerLeft,
                2: pw.Alignment.centerLeft,
                3: pw.Alignment.center,
                4: pw.Alignment.centerRight,
              },
              oddRowDecoration:
                  const pw.BoxDecoration(color: PdfColors.grey100),
              cellPadding:
                  const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            ),
        ],
      ),
    );

    return doc.save();
  }

  pw.Widget _box(String label, String value, String code, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: color, width: 1),
          borderRadius: pw.BorderRadius.circular(6),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label,
                style:
                    const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.SizedBox(height: 3),
            pw.Text(
              '$code $value',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
