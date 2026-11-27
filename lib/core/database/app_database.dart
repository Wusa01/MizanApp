import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'default_categories.dart';
import 'tables/accounts.dart';
import 'tables/categories.dart';
import 'tables/financial_transactions.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Accounts, Categories, FinancialTransactions])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(executor ?? driftDatabase(name: 'mizan'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      await _seedDefaultCategoriesIfEmpty();
    },
  );

  // تصنيفات جاهزة عند أول تشغيل، حتى يستطيع المستخدم تسجيل
  // أول عملية دون إنشاء تصنيفات يدوياً.
  Future<void> _seedDefaultCategoriesIfEmpty() async {
    final existing = await (select(categories)..limit(1)).get();

    if (existing.isNotEmpty) return;

    await batch((batch) {
      batch.insertAll(categories, [
        for (final category in defaultCategories)
          CategoriesCompanion.insert(
            name: category.name,
            type: category.type,
            isDefault: const Value(true),
          ),
      ]);
    });
  }
}
