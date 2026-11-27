import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/database/app_database.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../dashboard/providers/dashboard_providers.dart';
import '../providers/transactions_providers.dart';
import 'widgets/transaction_form_sheet.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  // null = الكل
  String? _filter;

  Future<void> _openForm({FinancialTransaction? existing}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => TransactionFormSheet(existing: existing),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final accounts = ref.watch(accountsProvider).value ?? const <Account>[];
    final categories =
        ref.watch(categoriesProvider).value ?? const <Category>[];

    final accountNames = {for (final a in accounts) a.id: a.name};
    final categoryNames = {for (final c in categories) c.id: c.name};

    return Scaffold(
      appBar: AppBar(title: const Text('العمليات المالية')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _filterChip('الكل', null),
                const SizedBox(width: 8),
                _filterChip('الإيرادات', 'income'),
                const SizedBox(width: 8),
                _filterChip('المصروفات', 'expense'),
                const SizedBox(width: 8),
                _filterChip('التحويلات', 'transfer'),
              ],
            ),
          ),
          Expanded(
            child: transactionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('تعذر تحميل العمليات'),
                    TextButton(
                      onPressed: () => ref.invalidate(transactionsProvider),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              ),
              data: (all) {
                final items = _filter == null
                    ? all
                    : all.where((t) => t.type == _filter).toList();

                if (items.isEmpty) {
                  return Center(
                    child: Text(
                      all.isEmpty
                          ? 'لا توجد عمليات مالية حتى الآن'
                          : 'لا توجد عمليات من هذا النوع',
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 88),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final transaction = items[index];

                    return _TransactionTile(
                      transaction: transaction,
                      accountName:
                          accountNames[transaction.accountId] ?? 'حساب محذوف',
                      destinationName:
                          accountNames[transaction.destinationAccountId],
                      categoryName: categoryNames[transaction.categoryId],
                      onTap: () => _openForm(existing: transaction),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('عملية جديدة'),
      ),
    );
  }

  Widget _filterChip(String label, String? value) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == value,
      onSelected: (_) => setState(() => _filter = value),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final FinancialTransaction transaction;
  final String accountName;
  final String? destinationName;
  final String? categoryName;
  final VoidCallback onTap;

  const _TransactionTile({
    required this.transaction,
    required this.accountName,
    required this.destinationName,
    required this.categoryName,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';

    final color = isTransfer
        ? Colors.blueGrey
        : isIncome
        ? Colors.green
        : Colors.red;

    final icon = isTransfer
        ? Icons.swap_horiz
        : isIncome
        ? Icons.arrow_downward
        : Icons.arrow_upward;

    final sign = isTransfer
        ? ''
        : isIncome
        ? '+ '
        : '- ';

    final note = transaction.description?.trim();

    final title = (note != null && note.isNotEmpty)
        ? note
        : isTransfer
        ? 'تحويل مالي'
        : categoryName ?? (isIncome ? 'إيراد' : 'مصروف');

    final subtitle = isTransfer
        ? '$accountName ← ${destinationName ?? 'حساب محذوف'}'
        : '${categoryName ?? 'بدون تصنيف'} • $accountName';

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '$subtitle\n${DateFormatter.format(transaction.transactionDate)}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Text(
          '$sign${CurrencyFormatter.format(transaction.amount)}',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
