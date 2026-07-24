import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';

class SidebarNavIndices {
  const SidebarNavIndices({
    required this.createOrder,
    required this.tables,
    required this.items,
    required this.inventory,
    required this.purchases,
    required this.orders,
    required this.reports,
    required this.kot,
    required this.kds,
    required this.customers,
    required this.staff,
    required this.subscriptions,
    required this.whatsapp,
    required this.printer,
    required this.settings,
    required this.profile,
    required this.logout,
  });

  final int createOrder;
  final int tables;
  final int items;
  final int inventory;
  final int purchases;
  final int orders;
  final int reports;
  final int kot;
  final int kds;
  final int customers;
  final int staff;
  final int subscriptions;
  final int whatsapp;
  final int printer;
  final int settings;
  final int profile;
  final int logout;

  factory SidebarNavIndices.compute({
    required bool kotEnabled,
    required bool hasSeating,
  }) {
    final routes = HomeMainRoutes.navRouteOrder(
      kotEnabled: kotEnabled,
      hasSeating: hasSeating,
    );

    int idx(String route) => routes.indexOf(route);

    return SidebarNavIndices(
      createOrder: idx(HomeMainRoutes.createOrder),
      tables: idx(HomeMainRoutes.tables),
      items: idx(HomeMainRoutes.items),
      inventory: idx(HomeMainRoutes.inventory),
      purchases: idx(HomeMainRoutes.purchaseOrders),
      orders: idx(HomeMainRoutes.closedOrders),
      reports: idx(HomeMainRoutes.reports),
      kot: idx(HomeMainRoutes.kotHistory),
      kds: idx(HomeMainRoutes.kitchenDisplay),
      customers: idx(HomeMainRoutes.customers),
      staff: idx(HomeMainRoutes.staff),
      subscriptions: idx(HomeMainRoutes.subscriptions),
      whatsapp: idx(HomeMainRoutes.whatsaapMarketing),
      printer: idx(HomeMainRoutes.printer),
      settings: idx(HomeMainRoutes.settings),
      profile: idx(HomeMainRoutes.profile),
      logout: routes.length,
    );
  }
}
