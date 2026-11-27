import 'dart:convert';

import 'package:drift/drift.dart';

import '../app_database.dart';

/// نسخة احتياطية كاملة بصيغة JSON، مستقلة عن ملف SQLite نفسه.
class BackupRepository {
  final AppDatabase database;

  BackupRepository(this.database);

  static const _format = 'mizan-backup';
  static const _version = 1;

  Future<String> exportJson() async {
    final accounts = await database.select(database.accounts).get();
    final categories = await database.select(database.categories).get();
    final transactions = await database
        .select(database.financialTransactions)
        .get();

    final data = <String, dynamic>{
      'format': _format,
      'version': _version,
      'exportedAt': DateTime.now().toIso8601String(),
      'accounts': [
        for (final a in accounts)
          {
            'id': a.id,
            'name': a.name,
            'type': a.type,
            'openingBalance': a.openingBalance,
            'currency': a.currency,
            'isActive': a.isActive,
            'createdAt': a.createdAt.toIso8601String(),
          },
      ],
      'categories': [
        for (final c in categories)
          {
            'id': c.id,
            'name': c.name,
            'type': c.type,
            'icon': c.icon,
            'isDefault': c.isDefault,
            'isActive': c.isActive,
            'createdAt': c.createdAt.toIso8601String(),
          },
      ],
      'transactions': [
        for (final t in transactions)
          {
            'id': t.id,
            'accountId': t.accountId,
            'categoryId': t.categoryId,
            'type': t.type,
            'amount': t.amount,
            'transactionDate': t.transactionDate.toIso8601String(),
            'description': t.description,
            'destinationAccountId': t.destinationAccountId,
            'createdAt': t.createdAt.toIso8601String(),
          },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// يستبدل كل البيانات الحالية ببيانات النسخة الاحتياطية.
  /// العملية كلها في معاملة واحدة: إما أن تنجح كاملة أو لا يتغير شيء.
  Future<void> importJson(String source) async {
    late final List<AccountsCompanion> accounts;
    late final List<CategoriesCompanion> categories;
    late final List<FinancialTransactionsCompanion> transactions;

    try {
      final decoded = jsonDecode(source);

      if (decoded is! Map<String, dynamic> ||
          decoded['format'] != _format ||
          decoded['version'] != _version) {
        throw const FormatException('unknown format');
      }

      List<Map<String, dynamic>> list(String key) =>
          (decoded[key] as List).cast<Map<String, dynamic>>();

      accounts = [
        for (final m in list('accounts'))
          AccountsCompanion.insert(
            id: Value(m['id'] as int),
            name: m['name'] as String,
            type: m['type'] as String,
            openingBalance: Value(m['openingBalance'] as int),
            currency: Value(m['currency'] as String),
            isActive: Value(m['isActive'] as bool),
            createdAt: Value(DateTime.parse(m['createdAt'] as String)),
          ),
      ];

      categories = [
        for (final m in list('categories'))
          CategoriesCompanion.insert(
            id: Value(m['id'] as int),
            name: m['name'] as String,
            type: m['type'] as String,
            icon: Value(m['icon'] as String?),
            isDefault: Value(m['isDefault'] as bool),
            isActive: Value(m['isActive'] as bool),
            createdAt: Value(DateTime.parse(m['createdAt'] as String)),
          ),
      ];

      transactions = [
        for (final m in list('transactions'))
          FinancialTransactionsCompanion.insert(
            id: Value(m['id'] as int),
            accountId: m['accountId'] as int,
            categoryId: Value(m['categoryId'] as int?),
            type: m['type'] as String,
            amount: m['amount'] as int,
            transactionDate: DateTime.parse(m['transactionDate'] as String),
            description: Value(m['description'] as String?),
            destinationAccountId: Value(m['destinationAccountId'] as int?),
            createdAt: Value(DateTime.parse(m['createdAt'] as String)),
          ),
      ];
    } catch (_) {
      throw ArgumentError('ملف النسخة الاحتياطية غير صالح');
    }

    await database.transaction(() async {
      await database.delete(database.financialTransactions).go();
      await database.delete(database.accounts).go();
      await database.delete(database.categories).go();

      await database.batch((batch) {
        batch.insertAll(database.categories, categories);
        batch.insertAll(database.accounts, accounts);
        batch.insertAll(database.financialTransactions, transactions);
      });
    });
  }
}
