import 'package:billkaro/app/Database/app_database.dart';
import 'package:billkaro/app/services/Modals/orders/createOrders/createOrder_request.dart'
    as create_req;
import 'package:billkaro/app/services/Modals/orders/orders/orderResponse.dart';
import 'package:billkaro/app/services/printerService.dart/thermal_printer/thermal_printer_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class KotHistoryController extends BaseController {
  final isLoading = false.obs;
  final search = ''.obs;

  final RxList<OrderModel> all = <OrderModel>[].obs;

  List<OrderModel> get filtered {
    final q = search.value.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((o) {
      return o.billNumber.toLowerCase().contains(q) ||
          (o.tableNumber ?? '').toLowerCase().contains(q) ||
          (o.customerName ?? '').toLowerCase().contains(q) ||
          (o.phoneNumber ?? '').toLowerCase().contains(q) ||
          o.orderFrom.toLowerCase().contains(q);
    }).toList(growable: false);
  }

  Future<void> load() async {
    try {
      isLoading.value = true;
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) {
        all.clear();
        return;
      }
      final db = AppDatabase();
      final orders = await db.getAllOrders(outletId: outletId);

      // Treat each order as a printable KOT history entry.
      // Show newest first.
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      all.value = orders;
    } catch (e) {
      debugPrint('❌ KOT history load failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  create_req.CreateorderRequest toKOTRequest(OrderModel o) {
    return create_req.CreateorderRequest(
      billNumber: o.billNumber,
      userId: o.userId,
      outletId: o.outletId,
      tableNumber: o.tableNumber ?? '',
      customerName: o.customerName ?? '',
      phoneNumber: o.phoneNumber ?? '',
      subtotal: o.subtotal,
      totalTax: o.totalTax,
      discount: o.discount,
      serviceCharge: o.serviceCharge,
      totalAmount: o.totalAmount,
      paymentReceivedIn: o.paymentReceivedIn ?? '',
      status: o.status,
      orderFrom: o.orderFrom,
      items: o.items
          .map(
            (i) => create_req.OrderItem(
              itemId: i.itemId,
              itemName: i.itemName,
              category: i.category,
              quantity: i.quantity,
              salePrice: i.salePrice,
              gst: i.gst,
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> reprintThermal(OrderModel o) async {
    try {
      final printerService = ThermalPrinterService.instance;
      final connected = await printerService.ensureConnected();
      if (!connected) return;

      final now = DateTime.now().toString();
      final dateStr = formatDate(now);
      final timeStr = formatTime(now);

      final items = o.items.where((i) => i.quantity > 0).toList(growable: false);
      final totalQty = items.fold<int>(0, (sum, i) => sum + i.quantity);

      await printerService.printKOT(
        kotNumber: o.billNumber,
        brandName: appPref.user?.brandName ?? '',
        businessName: appPref.user?.outletData?.first.businessName ?? '',
        address: appPref.user?.address ?? '',
        city: appPref.user?.city ?? '',
        zipcode: appPref.user?.zipcode ?? '',
        state: appPref.user?.state ?? '',
        orderFrom: o.orderFrom,
        tableNumber: o.tableNumber ?? '',
        customerName: o.customerName ?? '',
        waiterName: appPref.user?.brandName ?? 'Staff',
        date: dateStr,
        time: timeStr,
        items: items
            .map(
              (i) => create_req.OrderItem(
                itemId: i.itemId,
                itemName: i.itemName,
                category: i.category,
                quantity: i.quantity,
                salePrice: i.salePrice,
                gst: i.gst,
              ),
            )
            .toList(growable: false),
        specialInstructions: '',
        totalQuantity: totalQty,
      );
    } catch (e) {
      debugPrint('⚠️ KOT reprint failed: $e');
    }
  }

  @override
  void onReady() {
    load();
    super.onReady();
  }
}










