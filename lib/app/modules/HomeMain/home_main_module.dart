import 'package:billkaro/app/modules/AddOrder/AddCategory/add_category_screen.dart';
import 'package:billkaro/app/modules/AddOrder/OrderDetails/order_details_screen.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_screen.dart';
import 'package:billkaro/app/modules/AppSettings/app_settings_screen.dart';
import 'package:billkaro/app/modules/BusinessDetails/business_details_screen.dart';
import 'package:billkaro/app/modules/BusinessOverview/business_overview_screen.dart';
import 'package:billkaro/app/modules/Home/home_screen.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_shell.dart';
import 'package:billkaro/app/modules/Invoice/KOT/kot_preview_screen.dart';
import 'package:billkaro/app/modules/Invoice/invoice_screen.dart';
import 'package:billkaro/app/modules/Items/add_menu_items_screen.dart';
import 'package:billkaro/app/modules/Inventory/inventory_hub_screen.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_orders_screen.dart';
import 'package:billkaro/app/modules/Items/menuItem/menu_item_screen.dart';
import 'package:billkaro/app/modules/KOTHistory/kot_history_screen.dart';
import 'package:billkaro/app/modules/KitchenDisplay/kitchen_display_screen.dart';
import 'package:billkaro/app/modules/Language/language_screen.dart';
import 'package:billkaro/app/modules/Menu/menu_screen.dart';
import 'package:billkaro/app/modules/Notifications/app_notifications_screen.dart';
import 'package:billkaro/app/modules/Order/ClosedOrders/closed_orders_screen.dart';
import 'package:billkaro/app/modules/Order/DeletedOrders/deleted_orders_screen.dart';
import 'package:billkaro/app/modules/Order/StockSummary/stock_summary_screen.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/hold_orders_screen.dart';
import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/addregular_customer_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerDetails/customer_details_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerList/customer_list_Screen.dart';
import 'package:billkaro/app/modules/Reports/ItemReports/item_reports_screen.dart';
import 'package:billkaro/app/modules/Reports/OrderReports/order_reports_screen.dart';
import 'package:billkaro/app/modules/StoreSession/store_session_history_screen.dart';
import 'package:billkaro/app/modules/Reports/reports_screen.dart';
import 'package:billkaro/app/modules/Staff/Staff%20Activity/staff_activity_screen.dart';
import 'package:billkaro/app/modules/Staff/add_staff_screen.dart';
import 'package:billkaro/app/modules/Staff/staff_details_screen.dart';
import 'package:billkaro/app/modules/Tables/table_screen.dart';
import 'package:billkaro/app/modules/Whatsapp%20Marketing/whatsapp_marketing_screen.dart';
import 'package:billkaro/app/modules/Wallet/wallet_screen.dart';
import 'package:billkaro/app/modules/subscription/Form/subscription_form.dart';
import 'package:billkaro/app/modules/subscription/review/subscription_review_screen.dart';
import 'package:billkaro/app/modules/subscription/subscription_screen.dart';
import 'package:billkaro/app/services/PrinterService2/printer_screen2.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

Widget _staffGatedRoute({required bool allowed, required Widget child}) {
  return _StaffGatedRoute(allowed: allowed, child: child);
}

bool _isEditRouteArgs() {
  final args = Modular.args.data;
  return args is Map && args['isEdit'] == true;
}

class _StaffGatedRoute extends StatefulWidget {
  const _StaffGatedRoute({required this.allowed, required this.child});

  final bool allowed;
  final Widget child;

  @override
  State<_StaffGatedRoute> createState() => _StaffGatedRouteState();
}

class _StaffGatedRouteState extends State<_StaffGatedRoute> {
  @override
  void initState() {
    super.initState();
    if (!widget.allowed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showError(
          description: AppLocalizations.of(context)!.no_permission_section,
        );
        Modular.to.navigate(HomeMainRoutes.home);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.allowed) return const SizedBox.shrink();
    return widget.child;
  }
}

class HomeMainModule extends Module {
  @override
  void routes(r) {
    r.child(
      HomeMainRoutes.shell,
      child: (_) => const HomeMainShell(),
      children: [
        ChildRoute(HomeMainRoutes.home, child: (_) => HomeScreen()),
        ChildRoute(
          HomeMainRoutes.closedOrders,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canAccessSales,
            child: const ClosedOrdersScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.holdOrders,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canAccessSales,
            child: HoldOrdersScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.deletedOrders,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canAccessSales,
            child: const DeletedOrdersScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.stockSummary,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canAccessSales,
            child: const StockSummaryScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.items,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canAccessProducts,
            child: MenuItemScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.createOrder,
          child: (_) => _staffGatedRoute(
            allowed: _isEditRouteArgs()
                ? StaffAccess.canUpdateSales
                : StaffAccess.canCreateSales,
            child: AddOrderScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.reports,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canViewReports,
            child: ReportsScreen(),
          ),
        ),
        ChildRoute(HomeMainRoutes.tables, child: (_) => TableScreen()),
        ChildRoute(
          HomeMainRoutes.addItem,
          child: (_) => _staffGatedRoute(
            allowed: _isEditRouteArgs()
                ? StaffAccess.canUpdateProducts
                : StaffAccess.canCreateProducts,
            child: AddMenuItemScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.inventory,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canViewInventory,
            child: const InventoryHubScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.purchaseOrders,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canViewInventory,
            child: const PurchaseOrdersScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.businessOverview,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canViewDashboardInsights,
            child: BusinessOverviewScreen(),
          ),
        ),
        ChildRoute(HomeMainRoutes.kotHistory, child: (_) => KotHistoryScreen()),
        ChildRoute(
          HomeMainRoutes.kitchenDisplay,
          child: (_) => const KitchenDisplayScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.kotReceipt,
          child: (_) => ThermalKOTReceipt(),
        ),
        ChildRoute(
          HomeMainRoutes.orderReport,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canViewReports,
            child: OrderReportsScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.itemsReport,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canViewReports,
            child: ItemReportsScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.storeSessionHistory,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canViewStoreHistory,
            child: const StoreSessionHistoryScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.invoiceScreen,
          child: (_) => InvoicePreviewScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.customers,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canAccessCustomers,
            child: CustomerListScreen(),
          ),
        ),
        ChildRoute(HomeMainRoutes.printer, child: (_) => PrinterScreen2()),
        ChildRoute(
          HomeMainRoutes.staff,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canManageStaff,
            child: const StaffDetailsScreen(),
          ),
        ),
        ChildRoute(HomeMainRoutes.menu, child: (_) => MenuScreen()),
        ChildRoute(
          HomeMainRoutes.profile,
          child: (_) => BusinessDetailsScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.category,
          child: (_) => _staffGatedRoute(
            allowed: _isEditRouteArgs()
                ? StaffAccess.canUpdateCategories
                : StaffAccess.canCreateCategories,
            child: AddCategoryScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.orderSettings,
          child: (_) => OrderPreferencesScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.orderDetails,
          child: (_) => OrderDetailsScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.customersDetails,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canAccessCustomers,
            child: CustomerDetailsScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.addRegularCustomer,
          child: (_) => _staffGatedRoute(
            allowed: _isEditRouteArgs()
                ? StaffAccess.canUpdateCustomers
                : StaffAccess.canCreateCustomers,
            child: AddRegularCustomerScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.addStaffScreen,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canManageStaff,
            child: const AddStaffScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.staffActivityScreen,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canManageStaff,
            child: const StaffActivityScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.whatsaapMarketing,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canUseWhatsAppMarketing,
            child: WhatsappMarketingScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.settings,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canManageSettings,
            child: AppSettingsScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.notifications,
          child: (_) => AppNotificationsScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.changeLanguage,
          child: (_) => LanguageScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.subscriptions,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canManageSubscriptions,
            child: SubscriptionScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.wallet,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.isOwnerSession,
            child: const WalletScreen(),
          ),
        ),

        ChildRoute(
          HomeMainRoutes.subscriptionForm,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canManageSubscriptions,
            child: SubscriptionFormScreen(),
          ),
        ),
        ChildRoute(
          HomeMainRoutes.subscriptionReview,
          child: (_) => _staffGatedRoute(
            allowed: StaffAccess.canManageSubscriptions,
            child: SubscriptionReviewScreen(),
          ),
        ),
      ],
    );
  }
}
