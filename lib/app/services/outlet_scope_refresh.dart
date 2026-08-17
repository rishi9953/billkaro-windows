import 'package:billkaro/app/modules/AddOrder/AddCategory/add_category_controller.dart';
import 'package:billkaro/app/modules/AddOrder/OrderDetails/order_details_controller.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/BusinessDetails/business_details_controller.dart';
import 'package:billkaro/app/modules/BusinessOverview/business_overview_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Home/payment_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/modules/Invoice/KOT/kot_preview_controller.dart';
import 'package:billkaro/app/modules/Invoice/invoice_controller.dart';
import 'package:billkaro/app/modules/Items/add_menu_items_controller.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_controller.dart';
import 'package:billkaro/app/modules/KOTHistory/kot_history_controller.dart';
import 'package:billkaro/app/modules/KitchenDisplay/kitchen_display_controller.dart';
import 'package:billkaro/app/modules/Menu/menu_controller.dart';
import 'package:billkaro/app/modules/Order/ClosedOrders/closed_orders_controller.dart';
import 'package:billkaro/app/modules/Order/DeletedOrders/deleted_orders_controller.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/hold_orders_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/addregular_customer_controller.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerDetails/customer_details_controller.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerList/cutomer_list_controller.dart';
import 'package:billkaro/app/modules/Reports/ItemReports/item_reports_controller.dart';
import 'package:billkaro/app/modules/Reports/OrderReports/order_reports_controller.dart';
import 'package:billkaro/app/modules/Reports/reports_controller.dart';
import 'package:billkaro/app/modules/Staff/Staff%20Activity/staff_activity_controller.dart';
import 'package:billkaro/app/modules/Staff/add_staff_controller.dart';
import 'package:billkaro/app/modules/Staff/staff_details_controller.dart';
import 'package:billkaro/app/modules/StoreSession/store_session_controller.dart';
import 'package:billkaro/app/modules/StoreSession/store_session_history_controller.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/app_shell_sidebar_controller.dart';
import 'package:billkaro/app/modules/Wallet/wallet_controller.dart';
import 'package:billkaro/app/modules/Whatsapp%20Marketing/bulk_message_controller.dart';
import 'package:billkaro/app/modules/Whatsapp%20Marketing/whatsapp_marketing_controller.dart';
import 'package:billkaro/app/modules/subscription/Form/subscription_form_controller.dart';
import 'package:billkaro/app/modules/subscription/review/subscription_review_controller.dart';
import 'package:billkaro/app/modules/subscription/subscription_controller.dart';
import 'package:billkaro/app/services/kds/kds_realtime_service.dart';
import 'package:billkaro/app/services/notification/kitchen_bump_monitor.dart';
import 'package:billkaro/app/services/notification/kitchen_new_order_monitor.dart';
import 'package:billkaro/app/services/wallet/wallet_realtime_service.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart' as modular;

Future<void> _safeRefresh(Future<void> Function() action) async {
  try {
    await action();
  } catch (e, st) {
    debugPrint('⚠️ Outlet scope refresh failed: $e\n$st');
  }
}

Future<void> _safeDelete<T>() async {
  try {
    if (Get.isRegistered<T>()) {
      await Get.delete<T>(force: true);
    }
  } catch (e) {
    debugPrint('⚠️ Failed to delete ${T.toString()} after outlet change: $e');
  }
}

/// Drops every GetX controller that caches per-outlet data.
///
/// Windows cannot mirror mobile's [Get.offAllNamed] shell restart (Modular
/// throws "Module already started"), so deleting these controllers is the
/// equivalent: the next visit to each screen runs a fresh [onInit]/[onReady].
Future<void> _deleteOutletScopedControllers() async {
  await Future.wait([
    _safeDelete<AddOrderController>(),
    _safeDelete<AddCategoryController>(),
    _safeDelete<OrderDetailsController>(),
    _safeDelete<ClosedOrdersController>(),
    _safeDelete<HoldOrdersController>(),
    _safeDelete<DeletedOrdersController>(),
    _safeDelete<MenuItemController>(),
    _safeDelete<AddMenuItemController>(),
    _safeDelete<TableController>(),
    _safeDelete<KotHistoryController>(),
    _safeDelete<KitchenDisplayController>(),
    _safeDelete<KOTPreviewController>(),
    _safeDelete<BusinessOverviewController>(),
    _safeDelete<BusinessDetailsController>(),
    _safeDelete<OrderReportsController>(),
    _safeDelete<ItemReportsController>(),
    _safeDelete<ReportsController>(),
    _safeDelete<MenusController>(),
    _safeDelete<CutomerListController>(),
    _safeDelete<AddCustomerController>(),
    _safeDelete<CustomerDetailsController>(),
    _safeDelete<InvoicePreviewController>(),
    _safeDelete<SubscriptionController>(),
    _safeDelete<SubscriptionFormController>(),
    _safeDelete<SubscriptionReviewController>(),
    _safeDelete<WalletController>(),
    _safeDelete<InventoryController>(),
    _safeDelete<PurchaseOrderController>(),
    _safeDelete<StaffDetailsController>(),
    _safeDelete<StaffActivityController>(),
    _safeDelete<AddStaffController>(),
    _safeDelete<StoreSessionHistoryController>(),
    _safeDelete<WhatsappMarketingController>(),
    _safeDelete<BulkWhatsappController>(),
  ]);
}

/// Refreshes shell state and resets every outlet-scoped GetX controller.
/// Call after [AppPref.selectedOutlet] changes (e.g. dashboard outlet switcher).
Future<void> refreshOutletScopedControllers() async {
  KitchenBumpMonitor.instance.onOutletChanged();
  KitchenNewOrderMonitor.instance.onOutletChanged();

  final outlet = Get.find<AppPref>().selectedOutlet;
  if (outlet?.id != null) {
    KdsRealtimeService.instance.connect(outlet!.id!);
    WalletRealtimeService.instance.connect(outlet.id!);
  }

  if (Get.isRegistered<HomeMainController>()) {
    final c = Get.find<HomeMainController>();
    c.selectedOutlet.value = outlet;
    c.update();
  }

  // Drop cached feature controllers first so nothing keeps the previous outlet.
  await _deleteOutletScopedControllers();

  // Shell controllers stay alive for the whole Modular session — refresh in place.
  final futures = <Future<void>>[];

  if (Get.isRegistered<StoreSessionController>()) {
    futures.add(
      _safeRefresh(
        () => Get.find<StoreSessionController>().refresh(silent: true),
      ),
    );
  }
  if (Get.isRegistered<PaymentController>()) {
    futures.add(
      _safeRefresh(() => Get.find<PaymentController>().loadPaymentStatistics()),
    );
  }
  if (Get.isRegistered<AppShellSidebarController>()) {
    futures.add(
      _safeRefresh(
        () => Get.find<AppShellSidebarController>().refreshWalletBalance(
          force: true,
        ),
      ),
    );
  }

  await Future.wait(futures);
}

/// Refreshes cached user/outlet subscription state and returns to the dashboard.
Future<void> completeSubscriptionPurchase() async {
  if (Get.isRegistered<HomeMainController>()) {
    await Get.find<HomeMainController>().getUserDetails();
  }
  if (Get.isRegistered<HomeScreenController>()) {
    await Get.find<HomeScreenController>().getUserDetails();
  }

  await refreshOutletScopedControllers();

  if (Get.isRegistered<HomeScreenController>()) {
    await Get.find<HomeScreenController>().getOrderList(forceApiRefresh: true);
  }

  try {
    while (Get.isDialogOpen == true) {
      Get.back();
    }
  } catch (e) {
    debugPrint('Error closing dialogs after subscription: $e');
  }

  try {
    for (var i = 0; i < 6; i++) {
      final path = modular.Modular.to.path;
      if (!path.contains(HomeMainRoutes.subscriptionForm) &&
          !path.contains(HomeMainRoutes.subscriptionReview) &&
          path != HomeMainRoutes.subscriptions) {
        break;
      }
      if (!modular.Modular.to.canPop()) break;
      modular.Modular.to.pop();
    }
  } catch (e) {
    debugPrint('Error popping subscription routes: $e');
  }

  try {
    modular.Modular.to.navigate(HomeMainRoutes.home);
  } catch (e) {
    debugPrint('Error navigating to dashboard after subscription: $e');
  }
}
