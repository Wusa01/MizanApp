import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/repositories/finance_repository.dart';
import '../../../core/providers/database_provider.dart';

/// المفتاح هو أول يوم في الشهر (DateTime(year, month)).
DateTime _nextMonth(DateTime month) => DateTime(month.year, month.month + 1);

final periodSummaryProvider = StreamProvider.family<PeriodSummary, DateTime>((
  ref,
  month,
) {
  return ref
      .watch(financeRepositoryProvider)
      .watchPeriodSummary(from: month, to: _nextMonth(month));
});

class CategoryTotalsQuery {
  final DateTime month;
  final String type;

  const CategoryTotalsQuery(this.month, this.type);

  @override
  bool operator ==(Object other) =>
      other is CategoryTotalsQuery &&
      other.month == month &&
      other.type == type;

  @override
  int get hashCode => Object.hash(month, type);
}

final categoryTotalsProvider =
    StreamProvider.family<List<CategoryTotal>, CategoryTotalsQuery>((
      ref,
      query,
    ) {
      return ref
          .watch(financeRepositoryProvider)
          .watchCategoryTotals(
            type: query.type,
            from: query.month,
            to: _nextMonth(query.month),
          );
    });
