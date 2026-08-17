import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';

class SidebarRouteSelection {
  const SidebarRouteSelection({
    required this.itemList,
    required this.addItem,
    required this.orderReport,
    required this.itemReport,
    required this.storeHistory,
    required this.closedOrders,
    required this.holdOrders,
    required this.deletedOrders,
    required this.stockSummary,
    required this.inventory,
    required this.purchaseOrders,
    required this.notifications,
    required this.wallet,
  });

  final bool itemList;
  final bool addItem;
  final bool orderReport;
  final bool itemReport;
  final bool storeHistory;
  final bool closedOrders;
  final bool holdOrders;
  final bool deletedOrders;
  final bool stockSummary;
  final bool inventory;
  final bool purchaseOrders;
  final bool notifications;
  final bool wallet;

  factory SidebarRouteSelection.fromPath(String path) {
    return SidebarRouteSelection(
      itemList: path.startsWith(HomeMainRoutes.items),
      addItem: path.startsWith(HomeMainRoutes.addItem),
      orderReport: path.startsWith(HomeMainRoutes.orderReport),
      itemReport: path.startsWith(HomeMainRoutes.itemsReport),
      storeHistory: path.startsWith(HomeMainRoutes.storeSessionHistory),
      closedOrders: path.startsWith(HomeMainRoutes.closedOrders),
      holdOrders: path.startsWith(HomeMainRoutes.holdOrders),
      deletedOrders: path.startsWith(HomeMainRoutes.deletedOrders),
      stockSummary: path.startsWith(HomeMainRoutes.stockSummary),
      inventory: path.startsWith(HomeMainRoutes.inventory),
      purchaseOrders: path.startsWith(HomeMainRoutes.purchaseOrders),
      notifications: path.startsWith(HomeMainRoutes.notifications),
      wallet: path.startsWith(HomeMainRoutes.wallet),
    );
  }
}
