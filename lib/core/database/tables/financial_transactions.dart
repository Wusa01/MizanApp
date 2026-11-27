import 'package:drift/drift.dart';

import 'accounts.dart';
import 'categories.dart';

class FinancialTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();

  // الحساب الذي تمت عليه العملية.
  @ReferenceName('sourceTransactions')
  IntColumn get accountId =>
      integer().references(Accounts, #id, onDelete: KeyAction.restrict)();

  // التصنيف مطلوب للدخل والمصروف، وغير مطلوب للتحويل.
  IntColumn get categoryId => integer().nullable().references(
    Categories,
    #id,
    onDelete: KeyAction.restrict,
  )();

  // تحقق من نوع العملية وصحة العلاقات بين الحقول.
  TextColumn get type => text().customConstraint("""
        NOT NULL CHECK (
          type IN ('income', 'expense', 'transfer')
          AND (
            (
              type = 'transfer'
              AND category_id IS NULL
              AND destination_account_id IS NOT NULL
              AND destination_account_id != account_id
            )
            OR
            (
              type IN ('income', 'expense')
              AND category_id IS NOT NULL
              AND destination_account_id IS NULL
            )
          )
        )
        """)();

  // المبلغ دائماً عدد صحيح موجب.
  IntColumn get amount =>
      integer().customConstraint('NOT NULL CHECK (amount > 0)')();

  DateTimeColumn get transactionDate => dateTime()();

  TextColumn get description => text().nullable()();

  // حساب الوجهة في حالة التحويل فقط.
  @ReferenceName('destinationTransactions')
  IntColumn get destinationAccountId => integer().nullable().references(
    Accounts,
    #id,
    onDelete: KeyAction.restrict,
  )();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}
