import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../database/repositories/finance_repository.dart';
import '../utils/currency_formatter.dart';

class PdfReportBuilder {
  PdfReportBuilder._();

  // الخط لا يحتوي المسافة الضيقة التي يضعها intl بين الآلاف.
  static String _money(int amount) {
    return CurrencyFormatter.format(
      amount,
    ).replaceAll(RegExp('[\u00A0\u202F]'), ' ');
  }

  static Future<Uint8List> monthlyReport({
    required String monthLabel,
    required PeriodSummary summary,
    required List<CategoryTotal> expenses,
    required List<CategoryTotal> incomes,
  }) async {
    final regular = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'),
    );
    final bold = pw.Font.ttf(
      await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'),
    );

    final document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          textDirection: pw.TextDirection.rtl,
          theme: pw.ThemeData.withFont(base: regular, bold: bold),
        ),
        build: (context) => [
          pw.Text(
            'ميزان - التقرير الشهري',
            style: pw.TextStyle(font: bold, fontSize: 22),
          ),
          pw.SizedBox(height: 4),
          pw.Text(monthLabel, style: const pw.TextStyle(fontSize: 14)),
          pw.SizedBox(height: 20),

          _line('إجمالي الدخل', _money(summary.income), bold: true),
          _line('إجمالي المصروفات', _money(summary.expense), bold: true),
          _line('صافي النتيجة', _money(summary.net), bold: true),

          pw.SizedBox(height: 24),
          _section('المصروفات حسب التصنيف', expenses, bold),
          pw.SizedBox(height: 24),
          _section('الدخل حسب التصنيف', incomes, bold),
        ],
      ),
    );

    return document.save();
  }

  static pw.Widget _line(String label, String value, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(
            value,
            style: bold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null,
          ),
        ],
      ),
    );
  }

  static pw.Widget _section(
    String title,
    List<CategoryTotal> items,
    pw.Font bold,
  ) {
    final total = items.fold<int>(0, (sum, i) => sum + i.total);

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(title, style: pw.TextStyle(font: bold, fontSize: 16)),
        pw.SizedBox(height: 8),
        pw.Divider(),
        if (items.isEmpty)
          pw.Text('لا توجد بيانات لهذا الشهر')
        else
          for (final item in items)
            _line(
              item.categoryName,
              '${_money(item.total)}  (${(item.total * 100 / total).round()}%)',
            ),
      ],
    );
  }
}
