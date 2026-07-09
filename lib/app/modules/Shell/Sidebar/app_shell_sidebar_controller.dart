import 'dart:async';

import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:get/get.dart';

class AppShellSidebarController extends GetxController {
  final scrollController = ScrollController();
  Timer? _subscriptionTimer;

  bool itemsExpanded = false;
  bool purchasesExpanded = false;
  bool ordersExpanded = false;
  bool reportsExpanded = false;

  @override
  void onInit() {
    super.onInit();
    syncExpansionFromPath(Modular.to.path, collapsed: false);
    _subscriptionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      update(['subscription']);
    });
  }

  @override
  void onClose() {
    _subscriptionTimer?.cancel();
    scrollController.dispose();
    super.onClose();
  }

  void syncExpansionFromPath(String path, {required bool collapsed}) {
    final isItemsPath =
        path.startsWith(HomeMainRoutes.items) ||
        path.startsWith(HomeMainRoutes.addItem);
    final isReportPath =
        path.startsWith(HomeMainRoutes.reports) ||
        path.startsWith(HomeMainRoutes.orderReport) ||
        path.startsWith(HomeMainRoutes.itemsReport) ||
        path.startsWith(HomeMainRoutes.storeSessionHistory);
    final isOrdersPath =
        path.startsWith(HomeMainRoutes.closedOrders) ||
        path.startsWith(HomeMainRoutes.holdOrders);
    final isPurchasePath = path.startsWith(HomeMainRoutes.purchaseOrders);

    if (isItemsPath) itemsExpanded = true;
    if (isPurchasePath) purchasesExpanded = true;
    if (isOrdersPath) ordersExpanded = true;
    if (isReportPath) reportsExpanded = true;

    if (collapsed) {
      itemsExpanded = false;
      purchasesExpanded = false;
      ordersExpanded = false;
      reportsExpanded = false;
    }
  }

  void setItemsExpanded(bool value) => itemsExpanded = value;
  void setPurchasesExpanded(bool value) => purchasesExpanded = value;
  void setOrdersExpanded(bool value) => ordersExpanded = value;
  void setReportsExpanded(bool value) => reportsExpanded = value;
}
