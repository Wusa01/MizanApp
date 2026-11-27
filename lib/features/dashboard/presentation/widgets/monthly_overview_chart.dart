import 'package:fl_chart/fl_chart.dart';
import 'package:material_ui/material_ui.dart';

import '../../providers/dashboard_providers.dart';

class MonthlyOverviewChart extends StatelessWidget {
  final List<MonthlyFinancialSummary> data;

  const MonthlyOverviewChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final maxValue = data.fold<int>(0, (maximum, month) {
      final current = month.income > month.expense
          ? month.income
          : month.expense;

      return current > maximum ? current : maximum;
    });

    final chartMaxY = maxValue == 0 ? 100.0 : maxValue * 1.2;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'الأداء المالي الشهري',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _LegendItem(color: Colors.green, label: 'الدخل'),
                const SizedBox(width: 20),
                _LegendItem(color: Colors.red, label: 'المصروفات'),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: chartMaxY,
                  alignment: BarChartAlignment.spaceAround,
                  gridData: const FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _shortAmount(value.toInt()),
                            style: const TextStyle(fontSize: 9),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= data.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              data[index].label,
                              style: const TextStyle(fontSize: 9),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(data.length, (index) {
                    final month = data[index];

                    return BarChartGroupData(
                      x: index,
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: month.income.toDouble(),
                          color: Colors.green,
                          width: 9,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: month.expense.toDouble(),
                          color: Colors.red,
                          width: 9,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            if (data.every((month) => month.income == 0 && month.expense == 0))
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Center(
                  child: Text('لا توجد معاملات مالية خلال هذه الفترة'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shortAmount(int amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    }

    if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }

    return amount.toString();
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
