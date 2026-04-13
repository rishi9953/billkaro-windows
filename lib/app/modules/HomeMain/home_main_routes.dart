import 'package:get/get.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/config/app_pref.dart';

abstract class HomeMainRoutes {
  static const shell = '/';
  static const home = '/home';
  static const closedOrders = '/closed-orders';
  static const holdOrders = '/hold-orders';
  static const items = '/items';
  static const addItem = '/add-menu-item';
  static const businessOverview = '/business-overview';
  static const kotHistory = '/kot-history';
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
  static const whatsaapMarketing = '/whatsaap-marketing';
  static const settings = '/app-settings';
  static const changeLanguage = '/change-language';
  static const subscriptions = '/subscriptions';
  static const subscriptionForm = '/subscription-form';

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

  static String routeForIndex(int index) {
    final k = kotFeatureEnabled();
    final s = outletShowsTables();

    if (!s) {
      if (k) {
        switch (index) {
          case 0:
            return home;
          case 1:
            return createOrder;
          case 2:
            return items;
          case 3:
            return closedOrders;
          case 4:
            return reports;
          case 5:
            return kotHistory;
          case 6:
            return customers;
          case 7:
            return printer;
          case 8:
            return staff;
          case 9:
            return menu;
          case 10:
            return subscriptions;
          case 11:
            return whatsaapMarketing;
          case 12:
            return settings;
          case 13:
            return profile;
          default:
            return shell;
        }
      }
      switch (index) {
        case 0:
          return home;
        case 1:
          return createOrder;
        case 2:
          return items;
        case 3:
          return closedOrders;
        case 4:
          return reports;
        case 5:
          return customers;
        case 6:
          return printer;
        case 7:
          return staff;
        case 8:
          return menu;
        case 9:
          return subscriptions;
        case 10:
          return whatsaapMarketing;
        case 11:
          return settings;
        case 12:
          return profile;
        default:
          return shell;
      }
    }

    if (k) {
      switch (index) {
        case 0:
          return home;
        case 1:
          return createOrder;
        case 2:
          return tables;
        case 3:
          return items;
        case 4:
          return closedOrders;
        case 5:
          return reports;
        case 6:
          return kotHistory;
        case 7:
          return customers;
        case 8:
          return printer;
        case 9:
          return staff;
        case 10:
          return menu;
        case 11:
          return subscriptions;
        case 12:
          return whatsaapMarketing;
        case 13:
          return settings;
        case 14:
          return profile;
        default:
          return shell;
      }
    }
    switch (index) {
      case 0:
        return home;
      case 1:
        return createOrder;
      case 2:
        return tables;
      case 3:
        return items;
      case 4:
        return closedOrders;
      case 5:
        return reports;
      case 6:
        return customers;
      case 7:
        return printer;
      case 8:
        return staff;
      case 9:
        return menu;
      case 10:
        return subscriptions;
      case 11:
        return whatsaapMarketing;
      case 12:
        return settings;
      case 13:
        return profile;
      default:
        return shell;
    }
  }

  static int selectedIndexForPath(String path) {
    final k = kotFeatureEnabled();
    final s = outletShowsTables();

    if (path == shell || path == home) {
      return 0;
    }

    if (!s) {
      if (path.startsWith(closedOrders) || path.startsWith(holdOrders)) {
        return 3;
      }

      if (path.startsWith(createOrder) ||
          path.startsWith(orderDetails) ||
          path.startsWith(orderSettings) ||
          path.startsWith(category)) {
        return 1;
      }
      if (path.startsWith(tables)) {
        return 0;
      }
      if (path.startsWith(items) || path.startsWith(addItem)) {
        return 2;
      }
      if (path.startsWith(reports) ||
          path.startsWith(orderReport) ||
          path.startsWith(itemsReport)) {
        return 4;
      }
      if (path.startsWith(kotHistory) || path.startsWith(kotReceipt)) {
        return k ? 5 : 0;
      }
      if (path.startsWith(customers)) {
        return k ? 6 : 5;
      }
      if (path.startsWith(printer)) {
        return k ? 7 : 6;
      }
      if (path.startsWith(staff)) {
        return k ? 8 : 7;
      }
      if (path.startsWith(whatsaapMarketing)) {
        return k ? 11 : 10;
      }
      if (path.startsWith(menu)) {
        return k ? 9 : 8;
      }
      if (path.startsWith(profile)) {
        return k ? 13 : 12;
      }

      if (path.startsWith(subscriptions)) {
        return k ? 10 : 9;
      }

      if (path.startsWith(settings)) {
        return k ? 12 : 11;
      }

      if (path.startsWith(changeLanguage)) {
        return k ? 9 : 8;
      }

      return 0;
    }

    if (path.startsWith(closedOrders) || path.startsWith(holdOrders)) {
      return 4;
    }

    if (path.startsWith(createOrder) ||
        path.startsWith(orderDetails) ||
        path.startsWith(orderSettings) ||
        path.startsWith(category)) {
      return 1;
    }
    if (path.startsWith(tables)) {
      return 2;
    }
    if (path.startsWith(items) || path.startsWith(addItem)) {
      return 3;
    }
    // Keep "Reports" tab selected for its sub-pages too (Order/Item reports).
    if (path.startsWith(reports) ||
        path.startsWith(orderReport) ||
        path.startsWith(itemsReport)) {
      return 5;
    }
    if (path.startsWith(kotHistory) || path.startsWith(kotReceipt)) {
      return k ? 6 : 0;
    }
    if (path.startsWith(customers)) {
      return k ? 7 : 6;
    }
    if (path.startsWith(printer)) {
      return k ? 8 : 7;
    }
    if (path.startsWith(staff)) {
      return k ? 9 : 8;
    }
    if (path.startsWith(whatsaapMarketing)) {
      return k ? 12 : 11;
    }
    if (path.startsWith(menu)) {
      return k ? 10 : 9;
    }
    if (path.startsWith(profile)) {
      return k ? 14 : 13;
    }

    if (path.startsWith(subscriptions)) {
      return k ? 11 : 10;
    }

    if (path.startsWith(settings)) {
      return k ? 13 : 12;
    }

    // Keep Change Language under the "Menu" section in the sidebar.
    // (Language screen is not a dedicated sidebar item.)
    if (path.startsWith(changeLanguage)) {
      return k ? 10 : 9;
    }

    return 0;
  }
}
