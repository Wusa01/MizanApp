import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/core/database/repositories/finance_repository.dart';
import 'package:mizan/core/utils/csv_builder.dart';

void main() {
  test('escapes commas, quotes and new lines', () {
    final csv = CsvBuilder.build([
      ['a,b', 'say "hi"', 'line1\nline2', 'plain'],
    ]);

    expect(csv, '\uFEFF"a,b","say ""hi""","line1\nline2",plain\r\n');
  });

  test('builds transactions csv with header and rows', () {
    final csv = CsvBuilder.transactions([
      DashboardTransaction(
        id: 1,
        type: 'expense',
        amount: 2500,
        transactionDate: DateTime(2026, 11, 5),
        description: 'غداء, مع أصدقاء',
        accountName: 'الحساب الشخصي',
        categoryName: 'الطعام',
        destinationAccountName: null,
      ),
      DashboardTransaction(
        id: 2,
        type: 'transfer',
        amount: 1000,
        transactionDate: DateTime(2026, 11, 6),
        description: null,
        accountName: 'الحساب الشخصي',
        categoryName: null,
        destinationAccountName: 'المتجر',
      ),
    ]);

    final lines = csv.trim().split('\r\n');

    expect(lines.length, 3);
    expect(lines[1], '2026-11-05,مصروف,2500,الحساب الشخصي,الطعام,,"غداء, مع أصدقاء"');
    expect(lines[2], '2026-11-06,تحويل,1000,الحساب الشخصي,,المتجر,');
  });
}
