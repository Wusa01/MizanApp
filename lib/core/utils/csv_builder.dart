import '../database/repositories/finance_repository.dart';

class CsvBuilder {
  CsvBuilder._();

  static String _escape(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');

    if (!needsQuotes) return value;

    return '"${value.replaceAll('"', '""')}"';
  }

  /// BOM في البداية ليفتح Excel النص العربي بشكل صحيح.
  static String build(List<List<String>> rows) {
    final body = rows.map((row) => row.map(_escape).join(',')).join('\r\n');

    return '\uFEFF$body\r\n';
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'income':
        return 'إيراد';
      case 'expense':
        return 'مصروف';
      case 'transfer':
        return 'تحويل';
      default:
        return type;
    }
  }

  static String _date(DateTime d) {
    final month = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');

    return '${d.year}-$month-$day';
  }

  static String transactions(List<DashboardTransaction> items) {
    return build([
      ['التاريخ', 'النوع', 'المبلغ', 'الحساب', 'التصنيف', 'إلى حساب', 'ملاحظة'],
      for (final t in items)
        [
          _date(t.transactionDate),
          _typeLabel(t.type),
          t.amount.toString(),
          t.accountName,
          t.categoryName ?? '',
          t.destinationAccountName ?? '',
          t.description ?? '',
        ],
    ]);
  }
}
