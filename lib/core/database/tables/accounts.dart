import 'package:drift/drift.dart';

class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text()();

  TextColumn get type => text().customConstraint(
    "NOT NULL CHECK (type IN ('personal', 'business'))",
  )();

  IntColumn get openingBalance => integer().withDefault(const Constant(0))();

  TextColumn get currency => text().withDefault(const Constant('XAF'))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().clientDefault(DateTime.now)();
}
