import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/providers/database_provider.dart';

final categoriesProvider = StreamProvider<List<Category>>((ref) {
  return ref.watch(financeRepositoryProvider).watchCategories();
});

final transactionsProvider = StreamProvider<List<FinancialTransaction>>((ref) {
  return ref.watch(financeRepositoryProvider).watchTransactions();
});
