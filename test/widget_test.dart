import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mizan/app/mizan_app.dart';
import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/repositories/finance_repository.dart';
import 'package:mizan/features/dashboard/providers/dashboard_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Mizan app launches successfully', (tester) async {
    SharedPreferences.setMockInitialValues({});

    // بيانات جاهزة بدل قاعدة بيانات حقيقية، لأن قاعدة SQLite
    // لا تعمل داخل الزمن الوهمي لاختبارات الواجهة.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          totalBalanceProvider.overrideWith((ref) => Stream.value(0)),
          incomeTotalProvider.overrideWith((ref) => Stream.value(0)),
          expenseTotalProvider.overrideWith((ref) => Stream.value(0)),
          netResultProvider.overrideWith((ref) => Stream.value(0)),
          accountsProvider.overrideWith((ref) => Stream.value(<Account>[])),
          recentTransactionsProvider.overrideWith(
            (ref) => Stream.value(<DashboardTransaction>[]),
          ),
          monthlySummaryProvider.overrideWith(
            (ref) => Stream.value([
              for (var i = 0; i < 6; i++)
                MonthlyFinancialSummary(label: 'm$i', income: 0, expense: 0),
            ]),
          ),
        ],
        child: const MizanApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('ميزان'), findsOneWidget);
    expect(find.text('حساباتك'), findsOneWidget);
    expect(find.text('الرئيسية'), findsOneWidget);
    expect(find.text('الحسابات'), findsOneWidget);
  });
}
