import 'package:get/get.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:billkaro/utils/staff_access.dart';

abstract class HomeMainRoutes {
  static const shell = '/';
  static const home = '/home';
  static const closedOrders = '/closed-orders';
  static const holdOrders = '/hold-orders';
  static const deletedOrders = '/deleted-orders';
  static const stockSummary = '/stock-summary';
  static const items = '/items';
  static const addItem = '/add-menu-item';
  static const inventory = '/inventory';
  static const purchaseOrders = '/purchase-orders';
  static const businessOverview = '/business-overview';
  static const kotHistory = '/kot-history';
  static const kitchenDisplay = '/kitchen-display';
  static const kotReceipt = '/kot-receipt';
  static const orderReport = '/order-report';
  static const itemsReport = '/item-report';
  static const invoiceScreen = '/invoice-screen';
  static const createOrder = '/create-order';
  static const reports = '/reports';
  static const tables = '/tables';
  static const customers = '/customers';
  static const printer = '/printer';
  static const staff = '/staff';
  static const menu = '/menu';
  static const profile = '/profile';
  static const category = '/category';
  static const orderSettings = '/order-settings';
  static const orderDetails = '/order-details';
  static const customersDetails = '/customer-details';
  static const addRegularCustomer = '/add-regular-customer';
  static const addStaffScreen = '/add-staff';
  static const staffMemberDetails = '/staff-member-details';
  static const staffActivityScreen = '/staff-activity';
  static const whatsaapMarketing = '/whatsaap-marketing';
  static const storeSessionHistory = '/store-session-history';
  static const settings = '/app-settings';
  static const promotions = '/promotions';
  static const helpSetup = '/help-setup';
  static const notifications = '/notifications';
  static const changeLanguage = '/change-language';
  static const subscriptions = '/subscriptions';
  static const wallet = '/wallet';
  static const subscriptionForm = '/subscription-form';
  static const subscriptionReview = '/subscriptionReview';

  /// Cafe / restaurant outlets (matches business type from outlet profile).
  static bool outletIsCafeOrRestaurant() {
    if (Get.isRegistered<HomeScreenController>()) {
      final o = Get.find<HomeScreenController>().selectedOutlet.value;
      if (o != null) {
        final t = o.businessType?.trim().toLowerCase() ?? '';
        return t == 'cafe' || t == 'restaurant';
      }
    }
    if (!Get.isRegistered<AppPref>()) return false;
    final o = Get.find<AppPref>().selectedOutlet;
    final t = o?.businessType?.trim().toLowerCase() ?? '';
    return t == 'cafe' || t == 'restaurant';
  }

  /// Tables quick action + sidebar: cafe/restaurant with configured seating.
  static bool outletShowsTables() =>
      outletIsCafeOrRestaurant() && outletHasSeating();

  /// KOT preference on and outlet supports KOT (cafe / restaurant only).
  static bool kotFeatureEnabled() {
    if (!Get.isRegistered<AppPref>()) return false;
    return Get.find<AppPref>().isKOT && outletIsCafeOrRestaurant();
  }

  static const _seatingValueKeys = [
    '0',
    '0-10',
    '10-20',
    '20-50',
    '50-100',
    '100+',
  ];

  /// Normalizes API/form values; `'0'` means "No Seating".
  static String _normalizedSeatingValue(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '0';
    final t = raw.trim();
    if (_seatingValueKeys.contains(t)) return t;
    final lower = t.toLowerCase();
    if (lower.contains('no seating')) return '0';
    if (lower.contains('less') && lower.contains('10')) return '0-10';
    if (lower.contains('more') && lower.contains('100')) return '100+';
    if (lower == '10-20') return '10-20';
    if (lower == '20-50') return '20-50';
    if (lower == '50-100') return '50-100';
    return '0';
  }

  /// False when outlet seating is "No Seating" (normalized value is '0').
  static bool outletHasSeating() {
    if (Get.isRegistered<HomeScreenController>()) {
      final o = Get.find<HomeScreenController>().selectedOutlet.value;
      if (o != null) {
        return _normalizedSeatingValue(o.seatingCapacity) != '0';
      }
    }
    if (!Get.isRegistered<AppPref>()) return true;
    final o = Get.find<AppPref>().selectedOutlet;
    if (o == null) return true;
    return _normalizedSeatingValue(o.seatingCapacity) != '0';
  }

  static List<String> navRouteOrder({
    required bool kotEnabled,
    required bool hasSeating,
  }) {
    return [
      home,
      if (StaffAccess.canShowCreateOrder) createOrder,
      if (hasSeating && StaffAccess.canAccessTables) tables,
      if (StaffAccess.canAccessProducts) items,
      if (StaffAccess.canShowOrdersList) closedOrders,
      if (StaffAccess.canViewInventory) inventory,
      if (StaffAccess.canViewInventory) purchaseOrders,
      if (StaffAccess.canViewReports) reports,
      if (kotEnabled && StaffAccess.canViewKot) kotHistory,
      if (kotEnabled && StaffAccess.canOpenKitchenDisplay) kitchenDisplay,
      if (StaffAccess.canAccessCustomers) customers,
      if (StaffAccess.canManageStaff) staff,
      menu,
      if (StaffAccess.canManageSubscriptions) subscriptions,
      if (StaffAccess.canUseWhatsAppMarketing) whatsaapMarketing,
      printer,
      if (StaffAccess.canManageSettings) settings,
      profile,
    ];
  }

  static List<String> _navRouteOrder({required bool k, required bool s}) {
    return navRouteOrder(kotEnabled: k, hasSeating: s);
  }

  static int _indexOfRoute(List<String> routes, String route) {
    final index = routes.indexOf(route);
    return index >= 0 ? index : 0;
  }

  static String routeForIndex(int index) {
    final routes = _navRouteOrder(
      k: kotFeatureEnabled(),
      s: outletShowsTables(),
    );
    if (index >= 0 && index < routes.length) {
      return routes[index];
    }
    return shell;
  }

  static int selectedIndexForPath(String path) {
    if (path == shell || path == home) {
      return 0;
    }

    final k = kotFeatureEnabled();
    final s = outletShowsTables();
    final routes = _navRouteOrder(k: k, s: s);

    if (path.startsWith(createOrder) ||
        path.startsWith(orderDetails) ||
        path.startsWith(orderSettings) ||
        path.startsWith(category)) {
      return _indexOfRoute(routes, createOrder);
    }
    if (path.startsWith(tables)) {
      return _indexOfRoute(routes, tables);
    }
    if (path.startsWith(items) || path.startsWith(addItem)) {
      return _indexOfRoute(routes, items);
    }
    if (path.startsWith(inventory)) {
      return routes.contains(inventory)
          ? _indexOfRoute(routes, inventory)
          : _indexOfRoute(routes, items);
    }
    if (path.startsWith(purchaseOrders)) {
      return routes.contains(purchaseOrders)
          ? _indexOfRoute(routes, purchaseOrders)
          : _indexOfRoute(routes, items);
    }
    if (path.startsWith(closedOrders) ||
        path.startsWith(holdOrders) ||
        path.startsWith(deletedOrders) ||
        path.startsWith(stockSummary)) {
      return _indexOfRoute(routes, closedOrders);
    }
    if (path.startsWith(reports) ||
        path.startsWith(orderReport) ||
        path.startsWith(itemsReport) ||
        path.startsWith(storeSessionHistory)) {
      return _indexOfRoute(routes, reports);
    }
    if (path.startsWith(kotHistory) || path.startsWith(kotReceipt)) {
      return routes.contains(kotHistory)
          ? _indexOfRoute(routes, kotHistory)
          : 0;
    }
    if (path.startsWith(kitchenDisplay)) {
      return routes.contains(kitchenDisplay)
          ? _indexOfRoute(routes, kitchenDisplay)
          : 0;
    }
    if (path.startsWith(customers)) {
      return _indexOfRoute(routes, customers);
    }
    if (path.startsWith(staff)) {
      return _indexOfRoute(routes, staff);
    }
    if (path.startsWith(menu)) {
      return _indexOfRoute(routes, menu);
    }
    if (path.startsWith(notifications)) {
      return routes.length + 1;
    }
    if (path.startsWith(subscriptions)) {
      return _indexOfRoute(routes, subscriptions);
    }
    if (path.startsWith(whatsaapMarketing)) {
      return _indexOfRoute(routes, whatsaapMarketing);
    }
    if (path.startsWith(printer)) {
      return _indexOfRoute(routes, printer);
    }
    if (path.startsWith(settings) || path.startsWith(promotions)) {
      return _indexOfRoute(routes, settings);
    }
    if (path.startsWith(profile)) {
      return _indexOfRoute(routes, profile);
    }
    if (path.startsWith(changeLanguage)) {
      return _indexOfRoute(routes, menu);
    }

    return 0;
  }
}
