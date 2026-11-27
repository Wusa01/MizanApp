import 'package:material_ui/material_ui.dart';

import '../../../../core/utils/currency_formatter.dart';

class AccountBalanceCard extends StatelessWidget {
  final String title;
  final int balance;
  final IconData icon;
  final Color color;

  const AccountBalanceCard({
    super.key,
    required this.title,
    required this.balance,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(
                    CurrencyFormatter.format(balance),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
