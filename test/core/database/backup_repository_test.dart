import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mizan/core/database/app_database.dart';
import 'package:mizan/core/database/repositories/backup_repository.dart';
import 'package:mizan/core/database/repositories/finance_repository.dart';

void main() {
  // الاختبار ينشئ قاعدتين عمداً، فنوقف التحذير.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('backup export then import restores balances and transactions', () async {
    final sourceDb = AppDatabase(NativeDatabase.memory());
    final targetDb = AppDatabase(NativeDatabase.memory());

    addTearDown(sourceDb.close);
    addTearDown(targetDb.close);

    final source = FinanceRepository(sourceDb);
    final target = FinanceRepository(targetDb);

    final personal = await source.createAccount(
      name: 'شخصي',
      type: 'personal',
      openingBalance: 10000,
    );
    final business = await source.createAccount(
      name: 'متجر',
      type: 'business',
      openingBalance: 3000,
    );
    final category = await source.createCategory(
      name: 'مبيعات اختبار',
      type: 'income',
    );

    await source.addIncome(
      accountId: personal,
      amount: 5000,
      categoryId: category,
      description: 'بيع',
      transactionDate: DateTime(2026, 11, 3),
    );
    await source.transfer(
      sourceAccountId: personal,
      destinationAccountId: business,
      amount: 2000,
    );

    final json = await BackupRepository(sourceDb).exportJson();

    // بيانات موجودة سلفاً في الهدف يجب أن تُستبدل.
    await target.createAccount(name: 'سيحذف', type: 'personal');

    await BackupRepository(targetDb).importJson(json);

    final accounts = await target.watchAccounts().first;

    expect(accounts.map((a) => a.name), ['شخصي', 'متجر']);
    expect(await target.getAccountBalance(personal), 13000);
    expect(await target.getAccountBalance(business), 5000);
    expect(await target.getTotalBalance(), 18000);
    expect(await target.getNetResult(), 5000);

    final transactions = await target.watchTransactions().first;
    expect(transactions.length, 2);
  });

  test('import rejects invalid files and keeps existing data', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final repository = FinanceRepository(db);
    await repository.createAccount(
      name: 'يبقى',
      type: 'personal',
      openingBalance: 100,
    );

    final backup = BackupRepository(db);

    expect(() => backup.importJson('not json'), throwsA(isA<ArgumentError>()));
    expect(
      () => backup.importJson('{"format":"other","version":1}'),
      throwsA(isA<ArgumentError>()),
    );

    final accounts = await repository.watchAccounts().first;
    expect(accounts.single.name, 'يبقى');
  });
}
