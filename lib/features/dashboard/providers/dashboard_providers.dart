import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/database/repositories/finance_repository.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/utils/date_formatter.dart';

final accountsProvider = StreamProvider<List<Account>>((ref) {
  return ref.watch(financeRepositoryProvider).watchAccounts();
});

final totalBalanceProvider = StreamProvider<int>((ref) {
  return ref.watch(financeRepositoryProvider).watchTotalBalance();
});

final incomeTotalProvider = StreamProvider<int>((ref) {
  return ref.watch(financeRepositoryProvider).watchIncomeTotal();
});

final expenseTotalProvider = StreamProvider<int>((ref) {
  return ref.watch(financeRepositoryProvider).watchExpenseTotal();
});

final netResultProvider = StreamProvider<int>((ref) {
  return ref.watch(financeRepositoryProvider).watchNetResult();
});

final accountBalanceProvider = StreamProvider.family<int, int>((
  ref,
  accountId,
) {
  return ref.watch(financeRepositoryProvider).watchAccountBalance(accountId);
});

final recentTransactionsProvider = StreamProvider<List<DashboardTransaction>>((
  ref,
) {
  return ref.watch(financeRepositoryProvider).watchRecentTransactions();
});

class MonthlyFinancialSummary {
  final String label;
  final int income;
  final int expense;

  const MonthlyFinancialSummary({
    required this.label,
    required this.income,
    required this.expense,
  });
}

final monthlySummaryProvider = StreamProvider<List<MonthlyFinancialSummary>>((
  ref,
) {
  return ref.watch(financeRepositoryProvider).watchTransactions().map((
    transactions,
  ) {
    final now = DateTime.now();
    final firstMonth = DateTime(now.year, now.month - 5);

    final monthlyData = <DateTime, Map<String, int>>{};

    for (var i = 0; i < 6; i++) {
      final month = DateTime(firstMonth.year, firstMonth.month + i);

      monthlyData[month] = {'income': 0, 'expense': 0};
    }

    for (final transaction in transactions) {
      final date = transaction.transactionDate;

      final month = DateTime(date.year, date.month);

      final values = monthlyData[month];

      if (values == null) continue;

      if (transaction.type == 'income') {
        values['income'] = values['income']! + transaction.amount;
      } else if (transaction.type == 'expense') {
        values['expense'] = values['expense']! + transaction.amount;
      }
    }

    return monthlyData.entries.map((entry) {
      return MonthlyFinancialSummary(
        label: arabicMonths[entry.key.month - 1],
        income: entry.value['income']!,
        expense: entry.value['expense']!,
      );
    }).toList();
  });
});
