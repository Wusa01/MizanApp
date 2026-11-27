import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/services/file_saver.dart';
import '../../../core/services/pdf_report_builder.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../providers/reports_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  late DateTime _month;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  bool get _isCurrentMonth {
    final now = DateTime.now();

    return _month.year == now.year && _month.month == now.month;
  }

  void _changeMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  Future<void> _exportPdf() async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      final summary = await ref.read(periodSummaryProvider(_month).future);
      final expenses = await ref.read(
        categoryTotalsProvider(CategoryTotalsQuery(_month, 'expense')).future,
      );
      final incomes = await ref.read(
        categoryTotalsProvider(CategoryTotalsQuery(_month, 'income')).future,
      );

      final bytes = await PdfReportBuilder.monthlyReport(
        monthLabel: DateFormatter.monthYear(_month),
        summary: summary,
        expenses: expenses,
        incomes: incomes,
      );

      final month = _month.month.toString().padLeft(2, '0');

      final saved = await FileSaver.save(
        fileName: 'mizan-report-${_month.year}-$month.pdf',
        bytes: bytes,
        dialogTitle: 'حفظ التقرير',
      );

      if (saved) {
        messenger.showSnackBar(const SnackBar(content: Text('تم حفظ التقرير')));
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('تعذر إنشاء ملف PDF')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(periodSummaryProvider(_month));

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير'),
        actions: [
          IconButton(
            tooltip: 'تصدير PDF',
            onPressed: _exportPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // اختيار الشهر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                tooltip: 'الشهر السابق',
                onPressed: () => _changeMonth(-1),
                icon: const Icon(Icons.chevron_right),
              ),
              Text(
                DateFormatter.monthYear(_month),
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                tooltip: 'الشهر التالي',
                onPressed: _isCurrentMonth ? null : () => _changeMonth(1),
                icon: const Icon(Icons.chevron_left),
              ),
            ],
          ),
          const SizedBox(height: 12),

          summary.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) =>
                const Center(child: Text('تعذر تحميل التقرير')),
            data: (data) => Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        title: 'الدخل',
                        amount: data.income,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SummaryTile(
                        title: 'المصروفات',
                        amount: data.expense,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _SummaryTile(
                  title: 'صافي النتيجة',
                  amount: data.net,
                  color: data.net >= 0 ? Colors.blue : Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          _CategoryBreakdown(
            title: 'المصروفات حسب التصنيف',
            query: CategoryTotalsQuery(_month, 'expense'),
            color: Colors.red,
          ),

          const SizedBox(height: 28),

          _CategoryBreakdown(
            title: 'الدخل حسب التصنيف',
            query: CategoryTotalsQuery(_month, 'income'),
            color: Colors.green,
          ),
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String title;
  final int amount;
  final Color color;

  const _SummaryTile({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(color: color)),
            const SizedBox(height: 6),
            Text(
              CurrencyFormatter.format(amount),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends ConsumerWidget {
  final String title;
  final CategoryTotalsQuery query;
  final Color color;

  const _CategoryBreakdown({
    required this.title,
    required this.query,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(categoryTotalsProvider(query));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        totals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const Text('تعذر تحميل البيانات'),
          data: (items) {
            if (items.isEmpty) {
              return const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('لا توجد بيانات لهذا الشهر')),
                ),
              );
            }

            final grandTotal = items.fold<int>(0, (sum, i) => sum + i.total);

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.categoryName),
                                Text(
                                  '${CurrencyFormatter.format(item.total)}'
                                  '  (${(item.total * 100 / grandTotal).round()}%)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.total / grandTotal,
                                minHeight: 6,
                                color: color,
                                backgroundColor: color.withValues(alpha: 0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
