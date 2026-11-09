import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../utils/date_time_utils.dart';

enum ExportFormat { pdf, xlsx }

extension ExportFormatInfo on ExportFormat {
  String get label => this == ExportFormat.pdf ? 'PDF' : 'Excel (XLSX)';

  String get extension => this == ExportFormat.pdf ? 'pdf' : 'xlsx';

  String get mimeType => this == ExportFormat.pdf
      ? 'application/pdf'
      : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
}

/// A single exported row. Dates are rendered in the device's local time.
class ExportEntry {
  const ExportEntry({
    required this.date,
    required this.type,
    required this.category,
    required this.account,
    required this.description,
    required this.amount,
    required this.currency,
    this.note,
  });

  final DateTime date;
  final String type;
  final String category;
  final String account;
  final String description;
  final double amount;
  final String currency;
  final String? note;
}

class ExportTotals {
  const ExportTotals({
    required this.incomeCount,
    required this.expenseCount,
    required this.transferCount,
    required this.income,
    required this.expense,
    required this.transfer,
  });

  final int incomeCount;
  final int expenseCount;
  final int transferCount;
  final double income;
  final double expense;
  final double transfer;

  int get totalCount => incomeCount + expenseCount + transferCount;

  double get net => income - expense;
}

class ExportResult {
  const ExportResult({
    required this.filePath,
    required this.fileName,
    required this.rowCount,
    required this.totals,
  });

  final String? filePath;
  final String fileName;
  final int rowCount;
  final ExportTotals totals;
}

/// Builds a PDF/XLSX export of the currently filtered transactions and hands
/// it to the platform share sheet. Files are also kept in `<documents>/exports`.
class TransactionExportService {
  const TransactionExportService._();

  static Future<ExportResult> export({
    required ExportFormat format,
    required List<ExportEntry> entries,
    required String filterSummary,
    Rect? sharePositionOrigin,
  }) async {
    final totals = _computeTotals(entries);
    final generatedAt = DateTime.now();
    final baseName = 'ortho_transactions_${_stamp(generatedAt)}';

    final Uint8List bytes;
    if (format == ExportFormat.pdf) {
      bytes = await _buildPdf(
        entries: entries,
        totals: totals,
        filterSummary: filterSummary,
        generatedAt: generatedAt,
      );
    } else {
      bytes = _buildXlsx(
        entries: entries,
        totals: totals,
        filterSummary: filterSummary,
        generatedAt: generatedAt,
      );
    }

    final fileName = '$baseName.${format.extension}';
    final savedFile = await _saveFile(fileName, bytes);

    await SharePlus.instance.share(
      ShareParams(
        files: [
          savedFile != null
              ? XFile(savedFile.path, mimeType: format.mimeType, name: fileName)
              : XFile.fromData(
                  bytes,
                  mimeType: format.mimeType,
                  name: fileName,
                ),
        ],
        subject: 'Ortho transaction export',
        text: 'Ortho : Intelligent Finances - $fileName',
        sharePositionOrigin: sharePositionOrigin,
      ),
    );

    return ExportResult(
      filePath: savedFile?.path,
      fileName: fileName,
      rowCount: entries.length,
      totals: totals,
    );
  }

  static ExportTotals _computeTotals(List<ExportEntry> entries) {
    var incomeCount = 0;
    var expenseCount = 0;
    var transferCount = 0;
    var income = 0.0;
    var expense = 0.0;
    var transfer = 0.0;

    for (final entry in entries) {
      switch (entry.type) {
        case 'Income':
          incomeCount++;
          income += entry.amount;
          break;
        case 'Expense':
          expenseCount++;
          expense += entry.amount;
          break;
        default:
          transferCount++;
          transfer += entry.amount;
          break;
      }
    }

    return ExportTotals(
      incomeCount: incomeCount,
      expenseCount: expenseCount,
      transferCount: transferCount,
      income: income,
      expense: expense,
      transfer: transfer,
    );
  }

  static Future<Uint8List> _buildPdf({
    required List<ExportEntry> entries,
    required ExportTotals totals,
    required String filterSummary,
    required DateTime generatedAt,
  }) async {
    final document = pw.Document(
      title: 'Ortho : Intelligent Finances - Transaction export',
      author: 'Ortho : Intelligent Finances',
    );

    final rows = entries
        .map(
          (entry) => [
            AppDateTime.formatLocalDate(entry.date),
            AppDateTime.formatLocalTime(entry.date),
            entry.type,
            entry.category,
            entry.account,
            entry.description,
            entry.amount.toStringAsFixed(2),
            entry.currency,
          ],
        )
        .toList();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.6),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Ortho : Intelligent Finances',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
              pw.Text(
                'Transaction export',
                style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
              ),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ),
        build: (context) => [
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated ${AppDateTime.formatLocalDateTime(generatedAt)}',
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          if (filterSummary.isNotEmpty)
            pw.Text(
              'Filters: $filterSummary',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
          pw.SizedBox(height: 10),
          _pdfSummaryBlock(totals),
          pw.SizedBox(height: 14),
          if (rows.isEmpty)
            pw.Text(
              'No transactions match the selected filters.',
              style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const [
                'Date',
                'Time',
                'Type',
                'Category',
                'Account',
                'Details',
                'Amount',
                'Currency',
              ],
              data: rows,
              headerStyle: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
              cellStyle: const pw.TextStyle(fontSize: 8.5),
              cellPadding: const pw.EdgeInsets.all(4),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              cellAlignments: {
                6: pw.Alignment.centerRight,
              },
              columnWidths: {
                0: const pw.FixedColumnWidth(60),
                1: const pw.FixedColumnWidth(32),
                2: const pw.FixedColumnWidth(48),
                3: const pw.FixedColumnWidth(64),
                4: const pw.FixedColumnWidth(64),
                5: const pw.FlexColumnWidth(2),
                6: const pw.FixedColumnWidth(58),
                7: const pw.FixedColumnWidth(42),
              },
            ),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _pdfSummaryBlock(ExportTotals totals) {
    pw.Widget cell(String label, String value) {
      return pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          margin: const pw.EdgeInsets.only(right: 6),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style: pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey900,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Row(
      children: [
        cell('Entries', '${totals.totalCount}'),
        cell('Income', totals.income.toStringAsFixed(2)),
        cell('Expense', totals.expense.toStringAsFixed(2)),
        cell('Transfers', totals.transfer.toStringAsFixed(2)),
        cell('Net', totals.net.toStringAsFixed(2)),
      ],
    );
  }

  static Uint8List _buildXlsx({
    required List<ExportEntry> entries,
    required ExportTotals totals,
    required String filterSummary,
    required DateTime generatedAt,
  }) {
    final excel = Excel.createExcel();

    // The workbook starts with an empty "Sheet1"; reuse it so the file opens
    // on the transactions sheet instead of an empty one.
    if (excel.sheets.containsKey('Sheet1') &&
        !excel.sheets.containsKey('Transactions')) {
      excel.rename('Sheet1', 'Transactions');
    }

    final sheet = excel['Transactions'];
    sheet.appendRow([
      TextCellValue('Date'),
      TextCellValue('Time'),
      TextCellValue('Type'),
      TextCellValue('Category'),
      TextCellValue('Account'),
      TextCellValue('Details'),
      TextCellValue('Amount'),
      TextCellValue('Currency'),
      TextCellValue('Note'),
    ]);

    for (final entry in entries) {
      sheet.appendRow([
        TextCellValue(AppDateTime.formatLocalDate(entry.date)),
        TextCellValue(AppDateTime.formatLocalTime(entry.date)),
        TextCellValue(entry.type),
        TextCellValue(entry.category),
        TextCellValue(entry.account),
        TextCellValue(entry.description),
        DoubleCellValue(entry.amount),
        TextCellValue(entry.currency),
        TextCellValue(entry.note ?? ''),
      ]);
    }

    sheet.setColumnWidth(0, 14);
    sheet.setColumnWidth(1, 9);
    sheet.setColumnWidth(2, 11);
    sheet.setColumnWidth(3, 20);
    sheet.setColumnWidth(4, 20);
    sheet.setColumnWidth(5, 32);
    sheet.setColumnWidth(6, 14);
    sheet.setColumnWidth(7, 11);
    sheet.setColumnWidth(8, 30);

    final summary = excel['Summary'];
    summary.appendRow([TextCellValue('Metric'), TextCellValue('Value')]);
    summary.appendRow([
      TextCellValue('Generated at'),
      TextCellValue(AppDateTime.formatLocalDateTime(generatedAt)),
    ]);
    summary.appendRow([
      TextCellValue('Filters'),
      TextCellValue(filterSummary.isEmpty ? 'None' : filterSummary),
    ]);
    summary.appendRow([
      TextCellValue('Total entries'),
      IntCellValue(totals.totalCount),
    ]);
    summary.appendRow([
      TextCellValue('Income entries'),
      IntCellValue(totals.incomeCount),
    ]);
    summary.appendRow([
      TextCellValue('Income total'),
      DoubleCellValue(totals.income),
    ]);
    summary.appendRow([
      TextCellValue('Expense entries'),
      IntCellValue(totals.expenseCount),
    ]);
    summary.appendRow([
      TextCellValue('Expense total'),
      DoubleCellValue(totals.expense),
    ]);
    summary.appendRow([
      TextCellValue('Transfer entries'),
      IntCellValue(totals.transferCount),
    ]);
    summary.appendRow([
      TextCellValue('Transfer total'),
      DoubleCellValue(totals.transfer),
    ]);
    summary.appendRow([
      TextCellValue('Net'),
      DoubleCellValue(totals.net),
    ]);
    summary.setColumnWidth(0, 22);
    summary.setColumnWidth(1, 40);

    final bytes = excel.save();
    if (bytes == null) {
      throw StateError('Could not generate the Excel file.');
    }
    return Uint8List.fromList(bytes);
  }

  static Future<File?> _saveFile(String fileName, Uint8List bytes) async {
    try {
      final documents = await getApplicationDocumentsDirectory();
      final exportDirectory = Directory('${documents.path}/exports');
      if (!exportDirectory.existsSync()) {
        await exportDirectory.create(recursive: true);
      }
      final file = File('${exportDirectory.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (_) {
      return null;
    }
  }

  static String _stamp(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');
    return '${local.year}${two(local.month)}${two(local.day)}_'
        '${two(local.hour)}${two(local.minute)}';
  }
}
