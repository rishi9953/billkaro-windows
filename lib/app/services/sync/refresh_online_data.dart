import 'package:billkaro/app/modules/BusinessOverview/business_overview_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Home/payment_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/modules/Order/ClosedOrders/closed_orders_controller.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/hold_orders_controller.dart';
import 'package:billkaro/app/modules/Reports/ItemReports/item_reports_controller.dart';
import 'package:billkaro/app/modules/Reports/OrderReports/order_reports_controller.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/foundation.dart';

/// Refreshes all outlet-scoped controllers after a successful online sync.
/// Safe to call when internet is available; no-ops missing controllers.
Future<void> refreshControllersAfterOnlineSync() async {
  debugPrint('🔄 [ONLINE RESTORE] Refreshing UI controllers...');

  final futures = <Future<void>>[];

  if (Get.isRegistered<HomeScreenController>()) {
    futures.add(
      Get.find<HomeScreenController>().getOrderList(forceApiRefresh: true),
    );
  }
  if (Get.isRegistered<HoldOrdersController>()) {
    futures.add(
      Get.find<HoldOrdersController>().getOrderList(forceApiRefresh: true),
    );
  }
  if (Get.isRegistered<ClosedOrdersController>()) {
    futures.add(Get.find<ClosedOrdersController>().refreshOrders());
  }
  if (Get.isRegistered<TableController>()) {
    futures.add(Get.find<TableController>().refresh());
  }
  if (Get.isRegistered<BusinessOverviewController>()) {
    futures.add(
      Get.find<BusinessOverviewController>().getOrderList(forceApiRefresh: true),
    );
  }
  if (Get.isRegistered<OrderReportsController>()) {
    futures.add(Get.find<OrderReportsController>().getOrderList());
  }
  if (Get.isRegistered<ItemReportsController>()) {
    futures.add(
      Get.find<ItemReportsController>().getItemsList(forceApiRefresh: true),
    );
  }
  if (Get.isRegistered<MenuItemController>()) {
    final c = Get.find<MenuItemController>();
    futures.add(() async {
      await c.getCategories();
      await c.getItems(showLoader: false, forceApiRefresh: true);
    }());
  }
  if (Get.isRegistered<PaymentController>()) {
    futures.add(Get.find<PaymentController>().loadPaymentStatistics());
  }

  await Future.wait(futures);
  debugPrint('✅ [ONLINE RESTORE] UI controllers refreshed');
}
