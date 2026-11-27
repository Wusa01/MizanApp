import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../providers/dashboard_providers.dart';

import 'widgets/account_balance_card.dart';
import 'widgets/financial_summary_card.dart';
import 'widgets/monthly_overview_chart.dart';
import 'widgets/recent_transaction_item.dart';
import 'widgets/total_balance_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totalBalance = ref.watch(totalBalanceProvider);
    final income = ref.watch(incomeTotalProvider);
    final expenses = ref.watch(expenseTotalProvider);
    final netResult = ref.watch(netResultProvider);
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(recentTransactionsProvider);
    final monthlySummary = ref.watch(monthlySummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('ميزان'), centerTitle: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(totalBalanceProvider);
          ref.invalidate(incomeTotalProvider);
          ref.invalidate(expenseTotalProvider);
          ref.invalidate(netResultProvider);
          ref.invalidate(accountsProvider);
          ref.invalidate(recentTransactionsProvider);
          ref.invalidate(monthlySummaryProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle(context, 'إجمالي الأرصدة'),
              const SizedBox(height: 12),

              _asyncValue<int>(
                totalBalance,
                (value) => TotalBalanceCard(balance: value),
              ),

              const SizedBox(height: 28),

              _sectionTitle(context, 'حساباتك'),
              const SizedBox(height: 12),

              accounts.when(
                data: (accountList) {
                  final activeAccounts = accountList
                      .where((account) => account.isActive)
                      .toList();

                  if (activeAccounts.isEmpty) {
                    return const _EmptyMessage(
                      message: 'لا توجد حسابات حتى الآن',
                    );
                  }

                  return Column(
                    children: activeAccounts.map((account) {
                      final isPersonal = account.type == 'personal';

                      final balance = ref.watch(
                        accountBalanceProvider(account.id),
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: balance.when(
                          data: (value) => AccountBalanceCard(
                            title: account.name,
                            balance: value,
                            icon: isPersonal
                                ? Icons.person_outline
                                : Icons.store_outlined,
                            color: isPersonal ? Colors.blue : Colors.orange,
                          ),
                          loading: () => AccountBalanceCard(
                            title: account.name,
                            balance: 0,
                            icon: isPersonal
                                ? Icons.person_outline
                                : Icons.store_outlined,
                            color: isPersonal ? Colors.blue : Colors.orange,
                          ),
                          error: (error, stack) => _ErrorMessage(
                            message: 'تعذر تحميل رصيد ${account.name}',
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const _LoadingMessage(),
                error: (error, stack) =>
                    const _ErrorMessage(message: 'تعذر تحميل الحسابات'),
              ),

              const SizedBox(height: 28),

              _sectionTitle(context, 'ملخص الأداء المالي'),
              const SizedBox(height: 12),

              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.35,
                children: [
                  _asyncValue<int>(
                    income,
                    (value) => FinancialSummaryCard(
                      title: 'إجمالي الدخل',
                      amount: value,
                      icon: Icons.trending_up,
                      color: Colors.green,
                    ),
                  ),
                  _asyncValue<int>(
                    expenses,
                    (value) => FinancialSummaryCard(
                      title: 'إجمالي المصروفات',
                      amount: value,
                      icon: Icons.trending_down,
                      color: Colors.red,
                    ),
                  ),
                  _asyncValue<int>(
                    netResult,
                    (value) => FinancialSummaryCard(
                      title: 'صافي النتيجة',
                      amount: value,
                      icon: Icons.account_balance_wallet_outlined,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              _sectionTitle(context, 'الأداء الشهري'),
              const SizedBox(height: 12),

              monthlySummary.when(
                data: (data) => MonthlyOverviewChart(data: data),
                loading: () => const _LoadingMessage(),
                error: (error, stack) =>
                    const _ErrorMessage(message: 'تعذر تحميل الرسم البياني'),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionTitle(context, 'آخر العمليات'),
                  TextButton(
                    onPressed: () => context.go('/transactions'),
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),

              transactions.when(
                data: (items) {
                  if (items.isEmpty) {
                    return const _EmptyMessage(
                      message: 'لا توجد عمليات مالية حتى الآن',
                    );
                  }

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Column(
                        children: items.map((transaction) {
                          final isIncome = transaction.type == 'income';
                          final isTransfer = transaction.type == 'transfer';

                          final title =
                              transaction.description?.trim().isNotEmpty == true
                              ? transaction.description!
                              : _transactionTitle(transaction.type);

                          final category = isTransfer
                              ? '${transaction.accountName} ← ${transaction.destinationAccountName ?? ''}'
                              : transaction.categoryName ?? 'بدون تصنيف';

                          return RecentTransactionItem(
                            title: title,
                            category: category,
                            date: _formatDate(transaction.transactionDate),
                            amount: transaction.amount,
                            isIncome: isIncome,
                            isTransfer: isTransfer,
                          );
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => const _LoadingMessage(),
                error: (error, stack) =>
                    const _ErrorMessage(message: 'تعذر تحميل العمليات الأخيرة'),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium
          ?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _asyncValue<T>(AsyncValue<T> value, Widget Function(T data) builder) {
    return value.when(
      data: builder,
      loading: () => const _LoadingMessage(),
      error: (error, stack) =>
          const _ErrorMessage(message: 'تعذر تحميل البيانات'),
    );
  }

  String _transactionTitle(String type) {
    switch (type) {
      case 'income':
        return 'إيراد';
      case 'expense':
        return 'مصروف';
      case 'transfer':
        return 'تحويل مالي';
      default:
        return 'عملية مالية';
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}

class _LoadingMessage extends StatelessWidget {
  const _LoadingMessage();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyMessage extends StatelessWidget {
  final String message;

  const _EmptyMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(child: Text(message)),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  final String message;

  const _ErrorMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: const TextStyle(color: Colors.red)),
      ),
    );
  }
}
