import 'package:drift/drift.dart';

class CategoriesTable extends Table {
  /// 🔹 UUID from API
  TextColumn get id => text()();

  /// 🔹 User who created the category
  TextColumn get userId => text()();
  TextColumn get outletId => text()();

  /// 🔹 Category name
  TextColumn get categoryName => text()();
  TextColumn get imageURL => text()();


  /// 🔹 Timestamps (stored as ISO string)
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
