import 'dart:convert';
import 'dart:io';
import 'package:billkaro/app/Database/categoreis_table.dart';
import 'package:billkaro/app/Database/menu_item_table.dart';
import 'package:billkaro/app/Database/order_tables.dart';
import 'package:billkaro/app/services/Modals/Categories/categories_response.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/Modals/orders/split_payment.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Orders, OrderItems, Items, CategoriesTable])
class AppDatabase extends _$AppDatabase {
  AppDatabase._internal() : super(_openConnection());
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;

  /// 🔹 SCHEMA VERSION
  @override
  int get schemaVersion => 5;

  /// 🔹 MIGRATION STRATEGY (CRITICAL FIX)
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll();
    },
    onUpgrade: (Migrator m, int from, int to) async {
      if (from < 5) {
        // Add splitPayments column for version 5
        await m.addColumn(orders, orders.splitPayments);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Helper: Serialize split payments to JSON string
  String? _serializeSplitPayments(List<SplitPayment>? splitPayments) {
    if (splitPayments == null || splitPayments.isEmpty) return null;
    return jsonEncode(splitPayments.map((sp) => sp.toJson()).toList());
  }

  /// Helper: Deserialize JSON string to split payments
  List<SplitPayment>? _deserializeSplitPayments(String? jsonString) {
    if (jsonString == null || jsonString.isEmpty) return null;
    try {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList.map((json) => SplitPayment.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error deserializing split payments: $e');
      return null;
    }
  }

  // ===================== ORDERS ===================== //

  /// 🔹 INSERT / UPDATE ORDERS (OFFLINE SAFE)
  Future<void> insertOrders(
    List<OrderModel> ordersList,
    String outletId, {
    required bool isSyncedFromApi,
  }) async {
    await batch((batch) {
      for (final order in ordersList) {
        batch.insert(
          orders,
          OrdersCompanion(
            id: Value(order.id),
            outletId: Value(order.outletId),
            createdAt: Value(order.createdAt),
            updatedAt: Value(order.updatedAt),
            billNumber: Value(order.billNumber),
            userId: Value(order.userId),
            tableNumber: Value(order.tableNumber),
            customerName: Value(order.customerName),
            phoneNumber: Value(order.phoneNumber),
            subtotal: Value(order.subtotal),
            totalTax: Value(order.totalTax),
            discount: Value(order.discount),
            serviceCharge: Value(order.serviceCharge),
            totalAmount: Value(order.totalAmount),
            paymentReceivedIn: Value(order.paymentReceivedIn),
            splitPayments: Value(_serializeSplitPayments(order.splitPayments)),
            status: Value(order.status),
            orderFrom: Value(order.orderFrom),

            /// 🔥 HERE
            isSync: Value(isSyncedFromApi ? 'synced' : 'pending'),
          ),
          mode: InsertMode.insertOrReplace,
        );

        /// Delete old items
        batch.deleteWhere(orderItems, (tbl) => tbl.orderId.equals(order.id));

        /// Insert new items
        for (final item in order.items) {
          batch.insert(
            orderItems,
            OrderItemsCompanion(
              orderId: Value(order.id),
              itemId: Value(item.itemId),
              itemName: Value(item.itemName),
              category: Value(item.category),
              quantity: Value(item.quantity),
              salePrice: Value(item.salePrice),
              gst: Value(item.gst),
            ),
          );
        }
      }
    });
  }

  /// 🔹 GET ALL ORDERS (FILTER BY OUTLET)
  Future<List<OrderModel>> getAllOrders({String? outletId}) async {
    final query = select(orders);

    /// ✅ FIXED FILTER
    if (outletId != null) {
      query.where((tbl) => tbl.outletId.equals(outletId));
    }

    final orderRows = await query.get();
    final List<OrderModel> result = [];

    for (final order in orderRows) {
      final itemRows =
          await (select(orderItems)..where((tbl) {
                debugPrint('📦 Order Status:${order.id} ${order.isSync}');
                return tbl.orderId.equals(order.id);
              }))
              .get();

      result.add(
        OrderModel(
          id: order.id,
          outletId: order.outletId,
          createdAt: order.createdAt,
          updatedAt: order.updatedAt,
          billNumber: order.billNumber,
          userId: order.userId,
          tableNumber: order.tableNumber,
          customerName: order.customerName,
          phoneNumber: order.phoneNumber,
          subtotal: order.subtotal,
          totalTax: order.totalTax,
          discount: order.discount,
          serviceCharge: order.serviceCharge,
          totalAmount: order.totalAmount,
          paymentReceivedIn: order.paymentReceivedIn,
          splitPayments: _deserializeSplitPayments(order.splitPayments),
          status: order.status,
          orderFrom: order.orderFrom,
          items: itemRows
              .map(
                (e) => OrderItem(
                  itemId: e.itemId,
                  itemName: e.itemName,
                  category: e.category,
                  quantity: e.quantity,
                  salePrice: e.salePrice,
                  gst: e.gst,
                ),
              )
              .toList(),
        ),
      );
    }

    debugPrint('✅ Orders loaded: ${result.length}');
    return result;
  }

  Future<List<OrderModel>> getPendingOrders() async {
    final orderRows = await (select(
      orders,
    )..where((tbl) => tbl.isSync.equals('pending'))).get();

    final List<OrderModel> result = [];

    for (final order in orderRows) {
      final itemRows = await (select(
        orderItems,
      )..where((tbl) => tbl.orderId.equals(order.id))).get();

      result.add(
        OrderModel(
          id: order.id,
          outletId: order.outletId,
          createdAt: order.createdAt,
          updatedAt: order.updatedAt,
          billNumber: order.billNumber,
          userId: order.userId,
          tableNumber: order.tableNumber,
          customerName: order.customerName,
          phoneNumber: order.phoneNumber,
          subtotal: order.subtotal,
          totalTax: order.totalTax,
          discount: order.discount,
          serviceCharge: order.serviceCharge,
          totalAmount: order.totalAmount,
          paymentReceivedIn: order.paymentReceivedIn,
          splitPayments: _deserializeSplitPayments(order.splitPayments),
          status: order.status,
          orderFrom: order.orderFrom,
          items: itemRows
              .map(
                (e) => OrderItem(
                  itemId: e.itemId,
                  itemName: e.itemName,
                  category: e.category,
                  quantity: e.quantity,
                  salePrice: e.salePrice,
                  gst: e.gst,
                ),
              )
              .toList(),
        ),
      );
    }

    return result;
  }

  Future<void> markOrderAsSynced(String orderId) async {
    await (update(orders)..where((tbl) => tbl.id.equals(orderId))).write(
      OrdersCompanion(isSync: const Value('synced')),
    );
  }

  /// 🔹 CLEAR ORDERS
  Future<void> clearOrders({String? outletId}) async {
    if (outletId != null) {
      final orderRows = await (select(
        orders,
      )..where((tbl) => tbl.outletId.equals(outletId))).get();

      final ids = orderRows.map((e) => e.id).toList();

      if (ids.isNotEmpty) {
        await (delete(orderItems)..where((tbl) => tbl.orderId.isIn(ids))).go();
      }

      await (delete(
        orders,
      )..where((tbl) => tbl.outletId.equals(outletId))).go();
    } else {
      await delete(orderItems).go();
      await delete(orders).go();
    }
  }

  // ===================== ITEMS ===================== //

  Future<void> saveItems(List<ItemData> itemsData, String outletId) async {
    await batch((batch) {
      for (final item in itemsData) {
        batch.insert(
          items,
          ItemsCompanion(
            id: Value(item.id),
            category: Value(item.category),
            createdAt: Value(item.createdAt),
            gst: Value(item.gst),
            itemImage: Value(item.itemImage),
            itemName: Value(item.itemName),
            orderFrom: Value(item.orderFrom),
            salePrice: Value(item.salePrice),
            outletId: Value(outletId),
            userId: Value(item.userId),
            withTax: Value(item.withTax),
            updatedAt: Value(item.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<ItemData>> getItems({String? outletId}) async {
    final query = select(items);

    if (outletId != null) {
      query.where((tbl) => tbl.outletId.equals(outletId));
    }

    final rows = await query.get();

    return rows
        .map(
          (item) => ItemData(
            id: item.id,
            category: item.category,
            createdAt: item.createdAt,
            gst: item.gst,
            itemImage: item.itemImage,
            itemName: item.itemName,
            orderFrom: item.orderFrom,
            salePrice: item.salePrice,
            outletId: item.outletId,
            userId: item.userId,
            withTax: item.withTax,
            updatedAt: item.updatedAt,
            showItem: true, // DB may not have column; default visible
          ),
        )
        .toList();
  }

  Future<void> saveCategories(List<CategoryData> list) async {
    await batch((batch) {
      for (final c in list) {
        batch.insert(
          categoriesTable,
          CategoriesTableCompanion(
            id: Value(c.id),
            userId: Value(c.userId),
            categoryName: Value(c.categoryName),
            createdAt: Value(c.createdAt),
            updatedAt: Value(c.updatedAt),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<List<CategoryData>> getCategories({String? outletId}) async {
    final query = select(categoriesTable);

    if (outletId != null) {
      query.where((tbl) => tbl.outletId.equals(outletId));
    }

    final rows = await query.get();

    return rows
        .map(
          (item) => CategoryData(
            id: item.id,
            userId: item.userId,
            categoryName: item.categoryName,
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            outletId: item.outletId,
          ),
        )
        .toList();
  }

  /// 🔹 CLEAR ALL DATA FOR OUTLET
  Future<void> clearOutletData(String outletId) async {
    await clearOrders(outletId: outletId);
    await (delete(items)..where((tbl) => tbl.outletId.equals(outletId))).go();
  }

  /// 🔹 CLEAR ALL DATA FROM DATABASE (for logout)
  Future<void> clearAllData() async {
    await delete(orderItems).go();
    await delete(orders).go();
    await delete(items).go();
    await delete(categoriesTable).go();
    debugPrint('🗑️ All database data cleared');
  }
}

/// 🔹 DATABASE CONNECTION
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'billkaro.db'));
    return NativeDatabase(file);
  });
}
