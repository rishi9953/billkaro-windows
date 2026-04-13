import 'dart:async';

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
  final isLoadingMore = false.obs;
  final hasMoreData = true.obs;
  final search = ''.obs;

  final RxList<OrderModel> orders = <OrderModel>[].obs;

  final int itemsPerPage = 20;

  Timer? _searchDebounce;

  Future<void> load() async {
    if (isLoading.value) return;
    isLoading.value = true;
    try {
      final outletId = appPref.selectedOutlet?.id;
      if (outletId == null) {
        orders.clear();
        hasMoreData.value = false;
        return;
      }
      final db = AppDatabase();
      final page = await db.getOrdersPage(
        outletId: outletId,
        offset: 0,
        limit: itemsPerPage,
        searchQuery: search.value.trim().isEmpty ? null : search.value.trim(),
      );
      orders.assignAll(page.items);
      hasMoreData.value = page.hasMore;
    } catch (e) {
      debugPrint('❌ KOT history load failed: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore.value || !hasMoreData.value || isLoading.value) return;
    final outletId = appPref.selectedOutlet?.id;
    if (outletId == null) return;

    isLoadingMore.value = true;
    try {
      final db = AppDatabase();
      final page = await db.getOrdersPage(
        outletId: outletId,
        offset: orders.length,
        limit: itemsPerPage,
        searchQuery: search.value.trim().isEmpty ? null : search.value.trim(),
      );
      orders.addAll(page.items);
      hasMoreData.value = page.hasMore;
    } catch (e) {
      debugPrint('❌ KOT history load more failed: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void onSearchChanged(String value) {
    search.value = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), load);
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

      final items = o.items
          .where((i) => i.quantity > 0)
          .toList(growable: false);
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

  @override
  void onClose() {
    _searchDebounce?.cancel();
    super.onClose();
  }
}
