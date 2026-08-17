import 'dart:async';

import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Network/api_client.dart';
import 'package:billkaro/app/services/billing/billing_access_mode.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/app_pref.dart';
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

  double walletBalance = 0;
  bool isLoadingWalletBalance = false;
  double walletLowBalanceThreshold = 50;

  bool get isWalletLowBalance =>
      walletBalance > 0 && walletBalance < walletLowBalanceThreshold;

  @override
  void onInit() {
    super.onInit();
    syncExpansionFromPath(Modular.to.path, collapsed: false);
    // One-shot seed; live updates arrive via WalletRealtimeService WebSocket.
    unawaited(refreshWalletBalance(force: true));
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

  bool get _isWalletMode {
    if (!Get.isRegistered<AppPref>()) return false;
    final appPref = Get.find<AppPref>();
    final user = appPref.user;
    if (user?.isTrial == true) {
      final end = trialEndDate(appPref.selectedOutlet, user);
      if (end == null || DateTime.now().isBefore(end)) return false;
    }
    final mode = BillingAccessModeX.fromStorage(
      appPref.billingAccessModeRawForOutlet(appPref.selectedOutlet?.id),
    );
    return mode.isWallet;
  }

  void applyRealtimeWalletBalance(
    double balance, {
    double? lowBalanceThreshold,
  }) {
    walletBalance = balance;
    if (lowBalanceThreshold != null) {
      walletLowBalanceThreshold = lowBalanceThreshold;
    }
    isLoadingWalletBalance = false;
    update(['subscription']);
  }

  Future<void> refreshWalletBalance({bool force = false}) async {
    if (!_isWalletMode && !force) return;
    if (!Get.isRegistered<AppPref>() || !Get.isRegistered<ApiClient>()) return;

    final appPref = Get.find<AppPref>();
    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    if (outletId == null || userId == null) return;

    if (isLoadingWalletBalance) return;
    isLoadingWalletBalance = true;
    update(['subscription']);

    try {
      final res = await Get.find<ApiClient>().getOutletWallet(outletId, userId);
      if (res is Map && res['data'] is Map) {
        final data = res['data'] as Map;
        walletBalance = (data['balance'] as num?)?.toDouble() ?? walletBalance;
        walletLowBalanceThreshold =
            (data['lowBalanceThreshold'] as num?)?.toDouble() ??
                walletLowBalanceThreshold;
      }
    } catch (_) {
      // Keep last known balance on failure.
    } finally {
      isLoadingWalletBalance = false;
      update(['subscription']);
    }
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
        path.startsWith(HomeMainRoutes.holdOrders) ||
        path.startsWith(HomeMainRoutes.deletedOrders) ||
        path.startsWith(HomeMainRoutes.stockSummary);
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
