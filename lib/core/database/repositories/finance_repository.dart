import 'package:drift/drift.dart';

import '../app_database.dart';

class DashboardTransaction {
  final int id;
  final String type;
  final int amount;
  final DateTime transactionDate;
  final String? description;
  final String accountName;
  final String? categoryName;
  final String? destinationAccountName;

  const DashboardTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.transactionDate,
    required this.description,
    required this.accountName,
    required this.categoryName,
    required this.destinationAccountName,
  });
}

class CategoryTotal {
  final int categoryId;
  final String categoryName;
  final int total;

  const CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.total,
  });
}

class PeriodSummary {
  final int income;
  final int expense;

  const PeriodSummary({required this.income, required this.expense});

  int get net => income - expense;
}

class FinanceRepository {
  final AppDatabase database;

  FinanceRepository(this.database);

  // ==========================================
  // إنشاء الحسابات والتصنيفات
  // ==========================================

  Future<int> createAccount({
    required String name,
    required String type,
    int openingBalance = 0,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('اسم الحساب مطلوب');
    }

    if (type != 'personal' && type != 'business') {
      throw ArgumentError('نوع الحساب غير صحيح');
    }

    return database
        .into(database.accounts)
        .insert(
          AccountsCompanion.insert(
            name: name.trim(),
            type: type,
            openingBalance: Value(openingBalance),
          ),
        );
  }

  Future<int> createCategory({
    required String name,
    required String type,
    String? icon,
    bool isDefault = false,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('اسم التصنيف مطلوب');
    }

    if (type != 'income' && type != 'expense') {
      throw ArgumentError('نوع التصنيف غير صحيح');
    }

    return database
        .into(database.categories)
        .insert(
          CategoriesCompanion.insert(
            name: name.trim(),
            type: type,
            icon: Value(icon),
            isDefault: Value(isDefault),
          ),
        );
  }

  Future<void> updateAccount({
    required int accountId,
    required String name,
    required String type,
    required int openingBalance,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('اسم الحساب مطلوب');
    }

    if (type != 'personal' && type != 'business') {
      throw ArgumentError('نوع الحساب غير صحيح');
    }

    final updated =
        await (database.update(
          database.accounts,
        )..where((a) => a.id.equals(accountId))).write(
          AccountsCompanion(
            name: Value(name.trim()),
            type: Value(type),
            openingBalance: Value(openingBalance),
          ),
        );

    if (updated == 0) {
      throw ArgumentError('الحساب غير موجود');
    }
  }

  // التعطيل يخفي الحساب من الاختيار في العمليات الجديدة،
  // ولا يحذف أي عملية سابقة.
  Future<void> setAccountActive(int accountId, bool isActive) async {
    final updated =
        await (database.update(database.accounts)
              ..where((a) => a.id.equals(accountId)))
            .write(AccountsCompanion(isActive: Value(isActive)));

    if (updated == 0) {
      throw ArgumentError('الحساب غير موجود');
    }
  }

  // نوع التصنيف لا يتغير بعد إنشائه حتى لا تتعارض العمليات القديمة معه.
  Future<void> updateCategory({
    required int categoryId,
    required String name,
  }) async {
    if (name.trim().isEmpty) {
      throw ArgumentError('اسم التصنيف مطلوب');
    }

    final updated =
        await (database.update(database.categories)
              ..where((c) => c.id.equals(categoryId)))
            .write(CategoriesCompanion(name: Value(name.trim())));

    if (updated == 0) {
      throw ArgumentError('التصنيف غير موجود');
    }
  }

  Future<void> setCategoryActive(int categoryId, bool isActive) async {
    final updated =
        await (database.update(database.categories)
              ..where((c) => c.id.equals(categoryId)))
            .write(CategoriesCompanion(isActive: Value(isActive)));

    if (updated == 0) {
      throw ArgumentError('التصنيف غير موجود');
    }
  }

  // ==========================================
  // التحقق من الحسابات والتصنيفات والعمليات
  // ==========================================

  Future<Account> _requireActiveAccount(int accountId) async {
    final account = await (database.select(
      database.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();

    if (account == null || !account.isActive) {
      throw ArgumentError('الحساب غير موجود أو غير نشط');
    }

    return account;
  }

  Future<void> _validateCategory({
    required int categoryId,
    required String expectedType,
  }) async {
    final category = await (database.select(
      database.categories,
    )..where((c) => c.id.equals(categoryId))).getSingleOrNull();

    if (category == null ||
        !category.isActive ||
        category.type != expectedType) {
      throw ArgumentError('التصنيف غير صالح لهذه العملية');
    }
  }

  Future<FinancialTransaction> _requireTransaction(
    int transactionId, {
    String? expectedType,
  }) async {
    final transaction = await (database.select(
      database.financialTransactions,
    )..where((t) => t.id.equals(transactionId))).getSingleOrNull();

    if (transaction == null) {
      throw ArgumentError('العملية المالية غير موجودة');
    }

    if (expectedType != null && transaction.type != expectedType) {
      throw ArgumentError('نوع العملية غير صحيح');
    }

    return transaction;
  }

  // ==========================================
  // إنشاء الدخل والمصروفات
  // ==========================================

  Future<int> _createRegularTransaction({
    required int accountId,
    required int amount,
    required String type,
    required int categoryId,
    String? description,
    DateTime? transactionDate,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('يجب أن يكون المبلغ أكبر من صفر');
    }

    await _requireActiveAccount(accountId);

    await _validateCategory(categoryId: categoryId, expectedType: type);

    return database
        .into(database.financialTransactions)
        .insert(
          FinancialTransactionsCompanion.insert(
            accountId: accountId,
            categoryId: Value(categoryId),
            type: type,
            amount: amount,
            transactionDate: transactionDate ?? DateTime.now(),
            description: Value(description),
          ),
        );
  }

  Future<int> addIncome({
    required int accountId,
    required int amount,
    required int categoryId,
    String? description,
    DateTime? transactionDate,
  }) {
    return _createRegularTransaction(
      accountId: accountId,
      amount: amount,
      type: 'income',
      categoryId: categoryId,
      description: description,
      transactionDate: transactionDate,
    );
  }

  Future<int> addExpense({
    required int accountId,
    required int amount,
    required int categoryId,
    String? description,
    DateTime? transactionDate,
  }) {
    return _createRegularTransaction(
      accountId: accountId,
      amount: amount,
      type: 'expense',
      categoryId: categoryId,
      description: description,
      transactionDate: transactionDate,
    );
  }

  // ==========================================
  // التحويلات
  // ==========================================

  Future<int> transfer({
    required int sourceAccountId,
    required int destinationAccountId,
    required int amount,
    String? description,
    DateTime? transactionDate,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('يجب أن يكون مبلغ التحويل أكبر من صفر');
    }

    if (sourceAccountId == destinationAccountId) {
      throw ArgumentError('لا يمكن التحويل إلى الحساب نفسه');
    }

    return database.transaction(() async {
      await _requireActiveAccount(sourceAccountId);
      await _requireActiveAccount(destinationAccountId);

      return database
          .into(database.financialTransactions)
          .insert(
            FinancialTransactionsCompanion.insert(
              accountId: sourceAccountId,
              destinationAccountId: Value(destinationAccountId),
              categoryId: const Value(null),
              type: 'transfer',
              amount: amount,
              transactionDate: transactionDate ?? DateTime.now(),
              description: Value(description),
            ),
          );
    });
  }

  // ==========================================
  // تعديل الدخل والمصروفات
  // ==========================================

  Future<void> _updateRegularTransaction({
    required int transactionId,
    required int accountId,
    required int amount,
    required int categoryId,
    required String type,
    required String? description,
    DateTime? transactionDate,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('يجب أن يكون المبلغ أكبر من صفر');
    }

    await database.transaction(() async {
      final existing = await _requireTransaction(
        transactionId,
        expectedType: type,
      );

      await _requireActiveAccount(accountId);

      await _validateCategory(categoryId: categoryId, expectedType: type);

      await (database.update(
        database.financialTransactions,
      )..where((t) => t.id.equals(transactionId))).write(
        FinancialTransactionsCompanion(
          accountId: Value(accountId),
          categoryId: Value(categoryId),
          type: Value(type),
          amount: Value(amount),
          transactionDate: Value(transactionDate ?? existing.transactionDate),
          description: Value(description),
          destinationAccountId: const Value(null),
        ),
      );
    });
  }

  Future<void> updateIncome({
    required int transactionId,
    required int accountId,
    required int amount,
    required int categoryId,
    String? description,
    DateTime? transactionDate,
  }) {
    return _updateRegularTransaction(
      transactionId: transactionId,
      accountId: accountId,
      amount: amount,
      categoryId: categoryId,
      type: 'income',
      description: description,
      transactionDate: transactionDate,
    );
  }

  Future<void> updateExpense({
    required int transactionId,
    required int accountId,
    required int amount,
    required int categoryId,
    String? description,
    DateTime? transactionDate,
  }) {
    return _updateRegularTransaction(
      transactionId: transactionId,
      accountId: accountId,
      amount: amount,
      categoryId: categoryId,
      type: 'expense',
      description: description,
      transactionDate: transactionDate,
    );
  }

  // ==========================================
  // تعديل التحويلات
  // ==========================================

  Future<void> updateTransfer({
    required int transactionId,
    required int sourceAccountId,
    required int destinationAccountId,
    required int amount,
    String? description,
    DateTime? transactionDate,
  }) async {
    if (amount <= 0) {
      throw ArgumentError('يجب أن يكون مبلغ التحويل أكبر من صفر');
    }

    if (sourceAccountId == destinationAccountId) {
      throw ArgumentError('لا يمكن التحويل إلى الحساب نفسه');
    }

    await database.transaction(() async {
      final existing = await _requireTransaction(
        transactionId,
        expectedType: 'transfer',
      );

      await _requireActiveAccount(sourceAccountId);
      await _requireActiveAccount(destinationAccountId);

      await (database.update(
        database.financialTransactions,
      )..where((t) => t.id.equals(transactionId))).write(
        FinancialTransactionsCompanion(
          accountId: Value(sourceAccountId),
          destinationAccountId: Value(destinationAccountId),
          categoryId: const Value(null),
          type: const Value('transfer'),
          amount: Value(amount),
          transactionDate: Value(transactionDate ?? existing.transactionDate),
          description: Value(description),
        ),
      );
    });
  }

  // ==========================================
  // حذف عملية مالية
  // ==========================================

  Future<void> deleteTransaction(int transactionId) async {
    await database.transaction(() async {
      await _requireTransaction(transactionId);

      await (database.delete(
        database.financialTransactions,
      )..where((t) => t.id.equals(transactionId))).go();
    });
  }

  // ==========================================
  // Reactive Queries - القراءة التفاعلية
  // ==========================================

  Stream<List<Account>> watchAccounts() {
    return (database.select(
      database.accounts,
    )..orderBy([(a) => OrderingTerm.asc(a.id)])).watch();
  }

  Stream<List<Category>> watchCategories() {
    return (database.select(
      database.categories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  Stream<List<FinancialTransaction>> watchTransactions() {
    return (database.select(database.financialTransactions)..orderBy([
          (t) => OrderingTerm.desc(t.transactionDate),
          (t) => OrderingTerm.desc(t.id),
        ]))
        .watch();
  }

  // مراقبة رصيد حساب معين.
  Stream<int> watchAccountBalance(int accountId) {
    return database
        .customSelect(
          '''
          SELECT
            a.opening_balance
            + COALESCE((
                SELECT SUM(t.amount)
                FROM financial_transactions t
                WHERE t.account_id = a.id
                  AND t.type = 'income'
              ), 0)
            - COALESCE((
                SELECT SUM(t.amount)
                FROM financial_transactions t
                WHERE t.account_id = a.id
                  AND t.type = 'expense'
              ), 0)
            - COALESCE((
                SELECT SUM(t.amount)
                FROM financial_transactions t
                WHERE t.account_id = a.id
                  AND t.type = 'transfer'
              ), 0)
            + COALESCE((
                SELECT SUM(t.amount)
                FROM financial_transactions t
                WHERE t.destination_account_id = a.id
                  AND t.type = 'transfer'
              ), 0)
            AS balance
          FROM accounts a
          WHERE a.id = ?
          ''',
          variables: [Variable<int>(accountId)],
          readsFrom: {database.accounts, database.financialTransactions},
        )
        .watch()
        .map((rows) {
          if (rows.isEmpty) {
            throw ArgumentError('الحساب غير موجود');
          }

          return rows.single.read<int>('balance');
        });
  }

  // مراقبة إجمالي أرصدة جميع الحسابات.
  // التحويلات الداخلية لا تغير الإجمالي.
  Stream<int> watchTotalBalance() {
    return database
        .customSelect(
          '''
          SELECT
            COALESCE((
              SELECT SUM(opening_balance)
              FROM accounts
            ), 0)
            + COALESCE((
              SELECT SUM(amount)
              FROM financial_transactions
              WHERE type = 'income'
            ), 0)
            - COALESCE((
              SELECT SUM(amount)
              FROM financial_transactions
              WHERE type = 'expense'
            ), 0)
            AS total_balance
          ''',
          readsFrom: {database.accounts, database.financialTransactions},
        )
        .watch()
        .map((rows) => rows.single.read<int>('total_balance'));
  }

  // صافي النتيجة: الدخل - المصروفات.
  Stream<int> watchNetResult() {
    return database
        .customSelect(
          '''
          SELECT
            COALESCE(SUM(
              CASE
                WHEN type = 'income' THEN amount
                WHEN type = 'expense' THEN -amount
                ELSE 0
              END
            ), 0) AS net_result
          FROM financial_transactions
          ''',
          readsFrom: {database.financialTransactions},
        )
        .watch()
        .map((rows) => rows.single.read<int>('net_result'));
  }
  // ==========================================
  // Dashboard Queries
  // ==========================================

  Stream<int> watchIncomeTotal() {
    return database
        .customSelect(
          '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM financial_transactions
        WHERE type = 'income'
        ''',
          readsFrom: {database.financialTransactions},
        )
        .watch()
        .map((rows) => rows.single.read<int>('total'));
  }

  Stream<int> watchExpenseTotal() {
    return database
        .customSelect(
          '''
        SELECT COALESCE(SUM(amount), 0) AS total
        FROM financial_transactions
        WHERE type = 'expense'
        ''',
          readsFrom: {database.financialTransactions},
        )
        .watch()
        .map((rows) => rows.single.read<int>('total'));
  }

  Stream<List<DashboardTransaction>> watchRecentTransactions({int limit = 5}) {
    return database
        .customSelect(
          '''
        SELECT
          t.id,
          t.type,
          t.amount,
          t.transaction_date,
          t.description,
          source.name AS account_name,
          category.name AS category_name,
          destination.name AS destination_account_name
        FROM financial_transactions t
        INNER JOIN accounts source
          ON source.id = t.account_id
        LEFT JOIN categories category
          ON category.id = t.category_id
        LEFT JOIN accounts destination
          ON destination.id = t.destination_account_id
        ORDER BY t.transaction_date DESC, t.id DESC
        LIMIT ?
        ''',
          variables: [Variable.withInt(limit)],
          readsFrom: {
            database.financialTransactions,
            database.accounts,
            database.categories,
          },
        )
        .watch()
        .map(
          (rows) => rows.map((row) {
            return DashboardTransaction(
              id: row.read<int>('id'),
              type: row.read<String>('type'),
              amount: row.read<int>('amount'),
              transactionDate: row.read<DateTime>('transaction_date'),
              description: row.readNullable<String>('description'),
              accountName: row.read<String>('account_name'),
              categoryName: row.readNullable<String>('category_name'),
              destinationAccountName: row.readNullable<String>(
                'destination_account_name',
              ),
            );
          }).toList(),
        );
  }
  // ==========================================
  // التقارير
  // ==========================================

  // إجمالي الدخل والمصروفات في الفترة [from, to).
  // التحويلات لا تدخل في الحساب.
  Stream<PeriodSummary> watchPeriodSummary({
    required DateTime from,
    required DateTime to,
  }) {
    return database
        .customSelect(
          '''
        SELECT
          COALESCE(SUM(CASE WHEN type = 'income' THEN amount END), 0)
            AS income,
          COALESCE(SUM(CASE WHEN type = 'expense' THEN amount END), 0)
            AS expense
        FROM financial_transactions
        WHERE transaction_date >= ?
          AND transaction_date < ?
        ''',
          variables: [Variable<DateTime>(from), Variable<DateTime>(to)],
          readsFrom: {database.financialTransactions},
        )
        .watch()
        .map((rows) {
          final row = rows.single;

          return PeriodSummary(
            income: row.read<int>('income'),
            expense: row.read<int>('expense'),
          );
        });
  }

  // إجمالي كل تصنيف (دخل أو مصروف) في الفترة [from, to)، من الأكبر للأصغر.
  Stream<List<CategoryTotal>> watchCategoryTotals({
    required String type,
    required DateTime from,
    required DateTime to,
  }) {
    return database
        .customSelect(
          '''
        SELECT
          c.id AS category_id,
          c.name AS category_name,
          SUM(t.amount) AS total
        FROM financial_transactions t
        INNER JOIN categories c
          ON c.id = t.category_id
        WHERE t.type = ?
          AND t.transaction_date >= ?
          AND t.transaction_date < ?
        GROUP BY c.id, c.name
        ORDER BY total DESC
        ''',
          variables: [
            Variable<String>(type),
            Variable<DateTime>(from),
            Variable<DateTime>(to),
          ],
          readsFrom: {database.financialTransactions, database.categories},
        )
        .watch()
        .map(
          (rows) => rows
              .map(
                (row) => CategoryTotal(
                  categoryId: row.read<int>('category_id'),
                  categoryName: row.read<String>('category_name'),
                  total: row.read<int>('total'),
                ),
              )
              .toList(),
        );
  }

  // كل العمليات مع أسماء الحسابات والتصنيفات (للتصدير).
  Future<List<DashboardTransaction>> getAllTransactionsDetailed() async {
    final rows = await database.customSelect('''
        SELECT
          t.id,
          t.type,
          t.amount,
          t.transaction_date,
          t.description,
          source.name AS account_name,
          category.name AS category_name,
          destination.name AS destination_account_name
        FROM financial_transactions t
        INNER JOIN accounts source
          ON source.id = t.account_id
        LEFT JOIN categories category
          ON category.id = t.category_id
        LEFT JOIN accounts destination
          ON destination.id = t.destination_account_id
        ORDER BY t.transaction_date DESC, t.id DESC
        ''').get();

    return rows.map((row) {
      return DashboardTransaction(
        id: row.read<int>('id'),
        type: row.read<String>('type'),
        amount: row.read<int>('amount'),
        transactionDate: row.read<DateTime>('transaction_date'),
        description: row.readNullable<String>('description'),
        accountName: row.read<String>('account_name'),
        categoryName: row.readNullable<String>('category_name'),
        destinationAccountName: row.readNullable<String>(
          'destination_account_name',
        ),
      );
    }).toList();
  }

  // ==========================================
  // الحسابات المباشرة
  // ==========================================

  Future<int> getAccountBalance(int accountId) async {
    final account = await (database.select(
      database.accounts,
    )..where((a) => a.id.equals(accountId))).getSingleOrNull();

    if (account == null) {
      throw ArgumentError('الحساب غير موجود');
    }

    final transactions =
        await (database.select(database.financialTransactions)..where(
              (t) =>
                  t.accountId.equals(accountId) |
                  t.destinationAccountId.equals(accountId),
            ))
            .get();

    var balance = account.openingBalance;

    for (final transaction in transactions) {
      switch (transaction.type) {
        case 'income':
          if (transaction.accountId == accountId) {
            balance += transaction.amount;
          }

        case 'expense':
          if (transaction.accountId == accountId) {
            balance -= transaction.amount;
          }

        case 'transfer':
          if (transaction.accountId == accountId) {
            balance -= transaction.amount;
          }

          if (transaction.destinationAccountId == accountId) {
            balance += transaction.amount;
          }
      }
    }

    return balance;
  }

  Future<int> getTotalBalance() async {
    final accounts = await database.select(database.accounts).get();

    var total = 0;

    for (final account in accounts) {
      total += await getAccountBalance(account.id);
    }

    return total;
  }

  Future<int> getNetResult() async {
    final transactions = await database
        .select(database.financialTransactions)
        .get();

    var result = 0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        result += transaction.amount;
      } else if (transaction.type == 'expense') {
        result -= transaction.amount;
      }
    }

    return result;
  }
}
