import 'package:drift/drift.dart';

// Items Table
class Items extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get outletId => text()();
  TextColumn get itemName => text()();
  RealColumn get salePrice => real()();
  BoolColumn get withTax => boolean()();
  IntColumn get gst => integer()();
  TextColumn get category => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  TextColumn get itemImage => text().withDefault(const Constant(''))();
  TextColumn get orderFrom => text().nullable()();
  TextColumn get variantsJson => text().withDefault(const Constant('[]'))();
  TextColumn get barcode => text().withDefault(const Constant(''))();
  TextColumn get sku => text().withDefault(const Constant(''))();
  BoolColumn get showItem => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get isSync => text().withDefault(const Constant('synced'))();
  TextColumn get itemJson => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
