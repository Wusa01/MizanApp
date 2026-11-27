import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/currency_formatter.dart';

class RecentTransactionItem extends StatelessWidget {
  final String title;
  final String category;
  final String date;
  final int amount;
  final bool isIncome;
  final bool isTransfer;

  const RecentTransactionItem({
    super.key,
    required this.title,
    required this.category,
    required this.date,
    required this.amount,
    required this.isIncome,
    this.isTransfer = false,
  });

  @override
  Widget build(BuildContext context) {
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

    final prefix = isTransfer
        ? ''
        : isIncome
        ? '+ '
        : '- ';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.12),
        child: Icon(icon, color: color),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '$category • $date',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        '$prefix${CurrencyFormatter.format(amount)}',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
