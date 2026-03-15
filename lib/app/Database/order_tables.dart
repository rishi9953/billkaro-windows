import 'package:drift/drift.dart';

class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();
  TextColumn get billNumber => text()();
  TextColumn get userId => text()();

  /// 🔹 IMPORTANT: outletId column
  TextColumn get outletId => text()();
  TextColumn get tableNumber => text().nullable()();
  TextColumn get customerName => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();
  RealColumn get subtotal => real()();
  RealColumn get totalTax => real()();
  RealColumn get discount => real()();
  RealColumn get serviceCharge => real()();
  RealColumn get totalAmount => real()();
  TextColumn get paymentReceivedIn => text().nullable()();
  TextColumn get splitPayments => text().nullable()(); // JSON string of split payments
  TextColumn get status => text()();
  TextColumn get orderFrom => text()();
  TextColumn get isSync => text()();
  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('OrderItemEntity')
class OrderItems extends Table {
  IntColumn get autoId => integer().autoIncrement()();
  TextColumn get orderId =>
      text().references(Orders, #id, onDelete: KeyAction.cascade)();
  TextColumn get itemId => text()();
  TextColumn get itemName => text()();
  TextColumn get category => text()();
  IntColumn get quantity => integer()();
  RealColumn get salePrice => real()();
  RealColumn get gst => real()();
}
