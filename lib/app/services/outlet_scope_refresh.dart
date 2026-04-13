import 'package:billkaro/app/modules/BusinessDetails/business_details_controller.dart';
import 'package:billkaro/app/modules/BusinessOverview/business_overview_controller.dart';
import 'package:billkaro/app/modules/Home/payment_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_controller.dart';
import 'package:billkaro/app/modules/Invoice/invoice_controller.dart';
import 'package:billkaro/app/modules/Items/add_menu_items_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/modules/KOTHistory/kot_history_controller.dart';
import 'package:billkaro/app/modules/Menu/menu_controller.dart';
import 'package:billkaro/app/modules/Order/ClosedOrders/closed_orders_controller.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/hold_orders_controller.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerList/cutomer_list_controller.dart';
import 'package:billkaro/app/modules/Reports/ItemReports/item_reports_controller.dart';
import 'package:billkaro/app/modules/Reports/OrderReports/order_reports_controller.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/app/modules/subscription/subscription_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:get/get.dart';

/// Refreshes every registered GetX controller that caches data per outlet.
/// Call after [AppPref.selectedOutlet] changes (e.g. outlet bottom sheet).
Future<void> refreshOutletScopedControllers() async {
  final outlet = Get.find<AppPref>().selectedOutlet;

  if (Get.isRegistered<HomeMainController>()) {
    final c = Get.find<HomeMainController>();
    c.selectedOutlet.value = outlet;
    c.update();
  }

  if (Get.isRegistered<BusinessDetailsController>()) {
    Get.find<BusinessDetailsController>().syncOutletFromAppPref();
  }

  final futures = <Future<void>>[];

  if (Get.isRegistered<ClosedOrdersController>()) {
    futures.add(Get.find<ClosedOrdersController>().refreshOrders());
  }
  if (Get.isRegistered<HoldOrdersController>()) {
    futures.add(
      Get.find<HoldOrdersController>().getOrderList(forceApiRefresh: true),
    );
  }
  if (Get.isRegistered<MenuItemController>()) {
    final c = Get.find<MenuItemController>();
    futures.add(() async {
      await c.getCategories();
      await c.getItems(showLoader: false, forceApiRefresh: true);
    }());
  }
  if (Get.isRegistered<TableController>()) {
    futures.add(Get.find<TableController>().refresh());
  }
  if (Get.isRegistered<KotHistoryController>()) {
    futures.add(Get.find<KotHistoryController>().load());
  }
  if (Get.isRegistered<BusinessOverviewController>()) {
    futures.add(
      Get.find<BusinessOverviewController>().getOrderList(forceApiRefresh: true),
    );
  }
  if (Get.isRegistered<OrderReportsController>()) {
    futures.add(Get.find<OrderReportsController>().refreshOrders());
  }
  if (Get.isRegistered<ItemReportsController>()) {
    futures.add(
      Get.find<ItemReportsController>().getItemsList(forceApiRefresh: true),
    );
  }
  if (Get.isRegistered<MenusController>()) {
    Get.find<MenusController>().getUserDetails();
  }
  if (Get.isRegistered<CutomerListController>()) {
    futures.add(Get.find<CutomerListController>().getCustomerList());
  }
  if (Get.isRegistered<AddMenuItemController>()) {
    futures.add(Get.find<AddMenuItemController>().getCategories());
  }
  if (Get.isRegistered<PaymentController>()) {
    futures.add(Get.find<PaymentController>().loadPaymentStatistics());
  }
  if (Get.isRegistered<InvoicePreviewController>()) {
    Get.find<InvoicePreviewController>().getUserDetails();
  }
  if (Get.isRegistered<SubscriptionController>()) {
    futures.add(Get.find<SubscriptionController>().getSubscriptions());
  }

  await Future.wait(futures);
}
