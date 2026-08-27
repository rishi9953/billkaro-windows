import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/app_shell_sidebar_controller.dart';
import 'package:billkaro/app/modules/Wallet/wallet_controller.dart';
import 'package:billkaro/app/services/billing/billing_access_mode.dart';
import 'package:billkaro/app/services/billing/billing_access_service.dart';
import 'package:billkaro/config/config.dart';

/// Reloads profile, billing mode, and wallet so UI updates without app restart.
Future<void> refreshAfterAccessModeChoice(BillingAccessMode mode) async {
  if (!Get.isRegistered<AppPref>() || !Get.isRegistered<ApiClient>()) return;

  final appPref = Get.find<AppPref>();
  final apiClient = Get.find<ApiClient>();
  final userId = appPref.user?.userId ?? appPref.user?.id;
  final outletId = appPref.selectedOutlet?.id;

  BillingAccessService.of().setMode(mode, outletId: outletId);

  if (userId != null && userId.isNotEmpty) {
    try {
      final response = await callApi(
        apiClient.getUserDetails(userId),
        showLoader: false,
      );
      if (response?.status == 'success' && response?.data != null) {
        appPref.user = response!.data;
      }
    } catch (e) {
      debugPrint('refreshAfterAccessModeChoice user refresh failed: $e');
    }
  }

  if (outletId != null &&
      outletId.isNotEmpty &&
      userId != null &&
      userId.isNotEmpty) {
    try {
      final res = await callApi(
        apiClient.getOutletWallet(outletId, userId),
        showLoader: false,
      );
      if (res is Map && res['data'] is Map) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final balance = (data['balance'] as num?)?.toDouble();
        final threshold = (data['lowBalanceThreshold'] as num?)?.toDouble();
        if (balance != null) {
          appPref.setWalletBalanceForOutlet(outletId, balance);
          appPref.setWalletInitializedForOutlet(outletId, true);
          if (Get.isRegistered<WalletController>()) {
            Get.find<WalletController>().applyRealtimeBalance(
              balance,
              lowBalanceThreshold: threshold,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('refreshAfterAccessModeChoice wallet refresh failed: $e');
    }
  }

  if (Get.isRegistered<AppShellSidebarController>()) {
    final shell = Get.find<AppShellSidebarController>();
    await shell.refreshWalletBalance(force: true);
    shell.update(['subscription']);
  }

  if (Get.isRegistered<HomeScreenController>()) {
    Get.find<HomeScreenController>().update();
  }
}
