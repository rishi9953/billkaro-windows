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
import 'package:billkaro/app/modules/Items/menuItem/menu_item_screen.dart';
import 'package:billkaro/app/modules/KOTHistory/kot_history_screen.dart';
import 'package:billkaro/app/modules/Language/language_screen.dart';
import 'package:billkaro/app/modules/Menu/menu_screen.dart';
import 'package:billkaro/app/modules/Order/ClosedOrders/closed_orders_screen.dart';
import 'package:billkaro/app/modules/Order/HoldOrders/hold_orders_screen.dart';
import 'package:billkaro/app/modules/OrderPrefrences/order_prefrences_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/AddRegularCustomer/addregular_customer_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerDetails/customer_details_screen.dart';
import 'package:billkaro/app/modules/Regular%20customer/CustomerList/customer_list_Screen.dart';
import 'package:billkaro/app/modules/Reports/ItemReports/item_reports_screen.dart';
import 'package:billkaro/app/modules/Reports/OrderReports/order_reports_screen.dart';
import 'package:billkaro/app/modules/Reports/reports_screen.dart';
import 'package:billkaro/app/modules/Staff/add_staff_screen.dart';
import 'package:billkaro/app/modules/Staff/staff_details_screen.dart';
import 'package:billkaro/app/modules/Tables/table_screen.dart';
import 'package:billkaro/app/modules/Whatsapp%20Marketing/whatsapp_marketing_screen.dart';
import 'package:billkaro/app/modules/subscription/Form/subscription_form.dart';
import 'package:billkaro/app/modules/subscription/review/subscription_review_screen.dart';
import 'package:billkaro/app/modules/subscription/subscription_screen.dart';
import 'package:billkaro/app/services/PrinterService2/printer_screen2.dart';
import 'package:flutter_modular/flutter_modular.dart';

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
          child: (_) => const ClosedOrdersScreen(),
        ),
        ChildRoute(HomeMainRoutes.holdOrders, child: (_) => HoldOrdersScreen()),
        ChildRoute(HomeMainRoutes.items, child: (_) => MenuItemScreen()),
        ChildRoute(HomeMainRoutes.createOrder, child: (_) => AddOrderScreen()),
        ChildRoute(HomeMainRoutes.reports, child: (_) => ReportsScreen()),
        ChildRoute(HomeMainRoutes.tables, child: (_) => TableScreen()),
        ChildRoute(HomeMainRoutes.addItem, child: (_) => AddMenuItemScreen()),
        ChildRoute(
          HomeMainRoutes.businessOverview,
          child: (_) => BusinessOverviewScreen(),
        ),
        ChildRoute(HomeMainRoutes.kotHistory, child: (_) => KotHistoryScreen()),
        ChildRoute(
          HomeMainRoutes.kotReceipt,
          child: (_) => ThermalKOTReceipt(),
        ),
        ChildRoute(
          HomeMainRoutes.orderReport,
          child: (_) => OrderReportsScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.itemsReport,
          child: (_) => ItemReportsScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.invoiceScreen,
          child: (_) => InvoicePreviewScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.customers,
          child: (_) => CustomerListScreen(),
        ),
        ChildRoute(HomeMainRoutes.printer, child: (_) => PrinterScreen2()),
        ChildRoute(
          HomeMainRoutes.staff,
          child: (_) => const StaffDetailsScreen(),
        ),
        ChildRoute(HomeMainRoutes.menu, child: (_) => MenuScreen()),
        ChildRoute(
          HomeMainRoutes.profile,
          child: (_) => BusinessDetailsScreen(),
        ),
        ChildRoute(HomeMainRoutes.category, child: (_) => AddCategoryScreen()),
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
          child: (_) => CustomerDetailsScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.addRegularCustomer,
          child: (_) => AddRegularCustomerScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.addStaffScreen,
          child: (_) => const AddStaffScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.whatsaapMarketing,
          child: (_) => WhatsappMarketingScreen(),
        ),
        ChildRoute(HomeMainRoutes.settings, child: (_) => AppSettingsScreen()),
        ChildRoute(
          HomeMainRoutes.changeLanguage,
          child: (_) => LanguageScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.subscriptions,
          child: (_) => SubscriptionScreen(),
        ),

        ChildRoute(
          HomeMainRoutes.subscriptionForm,
          child: (_) => SubscriptionFormScreen(),
        ),
        ChildRoute(
          HomeMainRoutes.subscriptionReview,
          child: (_) => SubscriptionReviewScreen(),
        ),
      ],
    );
  }
}
