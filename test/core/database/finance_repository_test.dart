import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';

import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/repositories/finance_repository.dart';

void main() {
  late AppDatabase database;
  late FinanceRepository repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = FinanceRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('FinanceRepository', () {
    // ==========================================
    // إنشاء الحسابات والعمليات
    // ==========================================

    test('creates personal and business accounts', () async {
      final personalId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
        openingBalance: 10000,
      );

      final businessId = await repository.createAccount(
        name: 'حساب المتجر',
        type: 'business',
        openingBalance: 50000,
      );

      expect(personalId, greaterThan(0));
      expect(businessId, greaterThan(0));

      expect(await repository.getAccountBalance(personalId), 10000);
      expect(await repository.getAccountBalance(businessId), 50000);
      expect(await repository.getTotalBalance(), 60000);
    });

    test('calculates income and expense correctly', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
        openingBalance: 10000,
      );

      final incomeCategoryId = await repository.createCategory(
        name: 'الراتب',
        type: 'income',
      );

      final expenseCategoryId = await repository.createCategory(
        name: 'الطعام',
        type: 'expense',
      );

      await repository.addIncome(
        accountId: accountId,
        amount: 5000,
        categoryId: incomeCategoryId,
        description: 'دخل تجريبي',
      );

      await repository.addExpense(
        accountId: accountId,
        amount: 2000,
        categoryId: expenseCategoryId,
        description: 'مصروف تجريبي',
      );

      expect(await repository.getAccountBalance(accountId), 13000);
      expect(await repository.getNetResult(), 3000);
    });

    test('transfers money without counting it as income or expense', () async {
      final sourceId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
        openingBalance: 10000,
      );

      final destinationId = await repository.createAccount(
        name: 'حساب المتجر',
        type: 'business',
        openingBalance: 3000,
      );

      await repository.transfer(
        sourceAccountId: sourceId,
        destinationAccountId: destinationId,
        amount: 2000,
      );

      expect(await repository.getAccountBalance(sourceId), 8000);
      expect(await repository.getAccountBalance(destinationId), 5000);

      expect(await repository.getTotalBalance(), 13000);
      expect(await repository.getNetResult(), 0);
    });

    // ==========================================
    // التحقق من صحة البيانات
    // ==========================================

    test('rejects zero or negative amounts', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
      );

      final incomeCategoryId = await repository.createCategory(
        name: 'الراتب',
        type: 'income',
      );

      final expenseCategoryId = await repository.createCategory(
        name: 'الطعام',
        type: 'expense',
      );

      expect(
        () => repository.addIncome(
          accountId: accountId,
          amount: 0,
          categoryId: incomeCategoryId,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repository.addExpense(
          accountId: accountId,
          amount: -100,
          categoryId: expenseCategoryId,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects transfer to the same account', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
      );

      expect(
        () => repository.transfer(
          sourceAccountId: accountId,
          destinationAccountId: accountId,
          amount: 1000,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects category with incorrect transaction type', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
      );

      final expenseCategoryId = await repository.createCategory(
        name: 'الطعام',
        type: 'expense',
      );

      expect(
        () => repository.addIncome(
          accountId: accountId,
          amount: 5000,
          categoryId: expenseCategoryId,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    // ==========================================
    // تعديل الدخل والمصروفات
    // ==========================================

    test('updates income and recalculates balance and net result', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
        openingBalance: 10000,
      );

      final categoryId = await repository.createCategory(
        name: 'الراتب',
        type: 'income',
      );

      final transactionId = await repository.addIncome(
        accountId: accountId,
        amount: 5000,
        categoryId: categoryId,
      );

      expect(await repository.getAccountBalance(accountId), 15000);
      expect(await repository.getNetResult(), 5000);

      await repository.updateIncome(
        transactionId: transactionId,
        accountId: accountId,
        amount: 7000,
        categoryId: categoryId,
        description: 'راتب معدل',
      );

      expect(await repository.getAccountBalance(accountId), 17000);
      expect(await repository.getNetResult(), 7000);
    });

    test('updates expense and recalculates balance and net result', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
        openingBalance: 10000,
      );

      final categoryId = await repository.createCategory(
        name: 'الطعام',
        type: 'expense',
      );

      final transactionId = await repository.addExpense(
        accountId: accountId,
        amount: 4000,
        categoryId: categoryId,
      );

      expect(await repository.getAccountBalance(accountId), 6000);
      expect(await repository.getNetResult(), -4000);

      await repository.updateExpense(
        transactionId: transactionId,
        accountId: accountId,
        amount: 2500,
        categoryId: categoryId,
        description: 'مصروف معدل',
      );

      expect(await repository.getAccountBalance(accountId), 7500);
      expect(await repository.getNetResult(), -2500);
    });

    // ==========================================
    // تعديل التحويلات
    // ==========================================

    test('updates transfer and recalculates all account balances', () async {
      final sourceId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
        openingBalance: 10000,
      );

      final destinationId = await repository.createAccount(
        name: 'حساب المتجر',
        type: 'business',
        openingBalance: 3000,
      );

      final newDestinationId = await repository.createAccount(
        name: 'حساب التوفير',
        type: 'personal',
        openingBalance: 1000,
      );

      final transactionId = await repository.transfer(
        sourceAccountId: sourceId,
        destinationAccountId: destinationId,
        amount: 2000,
      );

      expect(await repository.getAccountBalance(sourceId), 8000);
      expect(await repository.getAccountBalance(destinationId), 5000);

      await repository.updateTransfer(
        transactionId: transactionId,
        sourceAccountId: sourceId,
        destinationAccountId: newDestinationId,
        amount: 4500,
        description: 'تحويل معدل',
      );

      expect(await repository.getAccountBalance(sourceId), 5500);
      expect(await repository.getAccountBalance(destinationId), 3000);
      expect(await repository.getAccountBalance(newDestinationId), 5500);

      expect(await repository.getTotalBalance(), 14000);
      expect(await repository.getNetResult(), 0);
    });

    // ==========================================
    // حذف العمليات
    // ==========================================

    test('deletes income and expense correctly', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
        openingBalance: 10000,
      );

      final incomeCategoryId = await repository.createCategory(
        name: 'الراتب',
        type: 'income',
      );

      final expenseCategoryId = await repository.createCategory(
        name: 'الطعام',
        type: 'expense',
      );

      final incomeId = await repository.addIncome(
        accountId: accountId,
        amount: 5000,
        categoryId: incomeCategoryId,
      );

      final expenseId = await repository.addExpense(
        accountId: accountId,
        amount: 2000,
        categoryId: expenseCategoryId,
      );

      expect(await repository.getAccountBalance(accountId), 13000);
      expect(await repository.getNetResult(), 3000);

      await repository.deleteTransaction(incomeId);

      expect(await repository.getAccountBalance(accountId), 8000);
      expect(await repository.getNetResult(), -2000);

      await repository.deleteTransaction(expenseId);

      expect(await repository.getAccountBalance(accountId), 10000);
      expect(await repository.getNetResult(), 0);
    });

    test('deletes transfer and restores both account balances', () async {
      final sourceId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
        openingBalance: 10000,
      );

      final destinationId = await repository.createAccount(
        name: 'حساب المتجر',
        type: 'business',
        openingBalance: 3000,
      );

      final transactionId = await repository.transfer(
        sourceAccountId: sourceId,
        destinationAccountId: destinationId,
        amount: 2000,
      );

      expect(await repository.getAccountBalance(sourceId), 8000);
      expect(await repository.getAccountBalance(destinationId), 5000);

      await repository.deleteTransaction(transactionId);

      expect(await repository.getAccountBalance(sourceId), 10000);
      expect(await repository.getAccountBalance(destinationId), 3000);

      expect(await repository.getTotalBalance(), 13000);
      expect(await repository.getNetResult(), 0);
    });

    // ==========================================
    // رفض العمليات غير الصحيحة
    // ==========================================

    test('rejects updating transaction with incorrect type', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب الشخصي',
        type: 'personal',
      );

      final expenseCategoryId = await repository.createCategory(
        name: 'الطعام',
        type: 'expense',
      );

      final transactionId = await repository.addExpense(
        accountId: accountId,
        amount: 2000,
        categoryId: expenseCategoryId,
      );

      expect(
        () => repository.updateIncome(
          transactionId: transactionId,
          accountId: accountId,
          amount: 5000,
          categoryId: expenseCategoryId,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(await repository.getAccountBalance(accountId), -2000);
      expect(await repository.getNetResult(), -2000);
    });

    test('rejects deleting a nonexistent transaction', () async {
      expect(
        () => repository.deleteTransaction(999),
        throwsA(isA<ArgumentError>()),
      );
    });

    // ==========================================
    // التصنيفات الافتراضية والتقارير
    // ==========================================

    test('seeds default income and expense categories on first open', () async {
      final categories = await repository.watchCategories().first;

      expect(categories.where((c) => c.type == 'income'), isNotEmpty);
      expect(categories.where((c) => c.type == 'expense'), isNotEmpty);
      expect(categories.every((c) => c.isDefault), isTrue);
    });

    test('period summary only counts the requested month', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب',
        type: 'personal',
      );
      final otherAccountId = await repository.createAccount(
        name: 'حساب آخر',
        type: 'business',
      );

      final incomeId = await repository.createCategory(
        name: 'دخل اختبار',
        type: 'income',
      );
      final expenseId = await repository.createCategory(
        name: 'مصروف اختبار',
        type: 'expense',
      );

      await repository.addIncome(
        accountId: accountId,
        amount: 10000,
        categoryId: incomeId,
        transactionDate: DateTime(2026, 11, 5),
      );
      await repository.addExpense(
        accountId: accountId,
        amount: 3000,
        categoryId: expenseId,
        transactionDate: DateTime(2026, 11, 20),
      );
      // خارج الشهر.
      await repository.addExpense(
        accountId: accountId,
        amount: 999,
        categoryId: expenseId,
        transactionDate: DateTime(2026, 10, 31),
      );
      // التحويل لا يدخل في التقرير.
      await repository.transfer(
        sourceAccountId: accountId,
        destinationAccountId: otherAccountId,
        amount: 500,
        transactionDate: DateTime(2026, 11, 10),
      );

      final summary = await repository
          .watchPeriodSummary(
            from: DateTime(2026, 11),
            to: DateTime(2026, 12),
          )
          .first;

      expect(summary.income, 10000);
      expect(summary.expense, 3000);
      expect(summary.net, 7000);
    });

    test('category totals are grouped and sorted descending', () async {
      final accountId = await repository.createAccount(
        name: 'الحساب',
        type: 'personal',
      );
      final foodId = await repository.createCategory(
        name: 'طعام اختبار',
        type: 'expense',
      );
      final fuelId = await repository.createCategory(
        name: 'وقود اختبار',
        type: 'expense',
      );

      final date = DateTime(2026, 11, 8);

      await repository.addExpense(
        accountId: accountId,
        amount: 1000,
        categoryId: foodId,
        transactionDate: date,
      );
      await repository.addExpense(
        accountId: accountId,
        amount: 2000,
        categoryId: foodId,
        transactionDate: date,
      );
      await repository.addExpense(
        accountId: accountId,
        amount: 5000,
        categoryId: fuelId,
        transactionDate: date,
      );

      final totals = await repository
          .watchCategoryTotals(
            type: 'expense',
            from: DateTime(2026, 11),
            to: DateTime(2026, 12),
          )
          .first;

      expect(totals.map((t) => t.categoryName), ['وقود اختبار', 'طعام اختبار']);
      expect(totals.map((t) => t.total), [5000, 3000]);
    });

    // ==========================================
    // تعديل الحسابات وتعطيلها
    // ==========================================

    test('updates and deactivates an account', () async {
      final id = await repository.createAccount(
        name: 'قديم',
        type: 'personal',
        openingBalance: 1000,
      );

      await repository.updateAccount(
        accountId: id,
        name: 'جديد',
        type: 'business',
        openingBalance: 5000,
      );

      expect(await repository.getAccountBalance(id), 5000);

      await repository.setAccountActive(id, false);

      final accounts = await repository.watchAccounts().first;
      expect(accounts.single.name, 'جديد');
      expect(accounts.single.type, 'business');
      expect(accounts.single.isActive, isFalse);

      expect(
        () => repository.updateAccount(
          accountId: 999,
          name: 'x',
          type: 'personal',
          openingBalance: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('updates and deactivates a category', () async {
      final id = await repository.createCategory(
        name: 'قديم',
        type: 'expense',
      );

      await repository.updateCategory(categoryId: id, name: 'جديد');
      await repository.setCategoryActive(id, false);

      final categories = await repository.watchCategories().first;
      final category = categories.firstWhere((c) => c.id == id);

      expect(category.name, 'جديد');
      expect(category.type, 'expense');
      expect(category.isActive, isFalse);

      // تصنيف معطل لا يقبل عمليات جديدة.
      final accountId = await repository.createAccount(
        name: 'حساب',
        type: 'personal',
      );

      expect(
        () => repository.addExpense(
          accountId: accountId,
          amount: 100,
          categoryId: id,
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => repository.updateCategory(categoryId: 99999, name: 'x'),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
