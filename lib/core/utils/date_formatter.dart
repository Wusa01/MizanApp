const arabicMonths = [
  'يناير',
  'فبراير',
  'مارس',
  'أبريل',
  'مايو',
  'يونيو',
  'يوليو',
  'أغسطس',
  'سبتمبر',
  'أكتوبر',
  'نوفمبر',
  'ديسمبر',
];

class DateFormatter {
  DateFormatter._();

  /// 05/03/2026
  static String format(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  /// مارس 2026
  static String monthYear(DateTime date) {
    return '${arabicMonths[date.month - 1]} ${date.year}';
  }
}
