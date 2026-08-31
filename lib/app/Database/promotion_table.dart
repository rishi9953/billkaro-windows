import 'package:drift/drift.dart';

class PromotionRulesTable extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get outletId => text()();
  TextColumn get name => text()();
  TextColumn get type => text()();
  BoolColumn get active => boolean()();
  TextColumn get ruleJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
