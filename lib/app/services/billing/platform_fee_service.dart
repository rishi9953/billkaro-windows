import 'package:billkaro/app/modules/Wallet/wallet_controller.dart';
import 'package:billkaro/app/services/Network/api_client.dart';
import 'package:billkaro/app/services/billing/billing_access_mode.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/services/wallet/wallet_local_store.dart';
import 'package:billkaro/config/app_pref.dart';
import 'package:get/get.dart';

/// ₹1 platform fee on Save & Hold / Save & Bill (wallet billing mode).
class PlatformFeeService {
  PlatformFeeService._();

  static const double feeAmount = 1;

  /// Show Create Order wallet alert when balance is at or below this amount.
  static const double lowBalanceAlertThreshold = 100;

  /// Charge only in wallet (pay-as-you-go) mode; skip active trial.
  static bool shouldCharge(AppPref appPref) {
    final user = appPref.user;
    if (user == null) return false;

    if (user.isTrial == true) {
      final end = trialEndDate(appPref.selectedOutlet, user);
      if (end == null || DateTime.now().isBefore(end)) return false;
    }

    final mode = BillingAccessModeX.fromStorage(
      appPref.billingAccessModeRawForOutlet(appPref.selectedOutlet?.id),
    );
    return mode.isWallet;
  }

  /// Cached / in-memory balance (controller or local store).
  static double currentBalance(AppPref appPref) {
    final cached = WalletLocalStore(appPref).balance;
    if (Get.isRegistered<WalletController>()) {
      final live = Get.find<WalletController>().balance.value;
      return live > 0 ? live : cached;
    }
    return cached;
  }

  static bool hasSufficientBalance(AppPref appPref) =>
      currentBalance(appPref) >= feeAmount;

  /// Prefers live API balance when possible (Windows wallet is server-backed).
  static Future<bool> ensureSufficientBalance(
    AppPref appPref, {
    ApiClient? apiClient,
  }) async {
    if (hasSufficientBalance(appPref)) return true;

    final outletId = appPref.selectedOutlet?.id;
    final userId = appPref.user?.id;
    final client = apiClient ??
        (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null);
    if (outletId == null || userId == null || client == null) {
      return hasSufficientBalance(appPref);
    }

    try {
      final res = await client.getOutletWallet(outletId, userId);
      if (res is Map && res['data'] is Map) {
        final balance =
            (res['data']['balance'] as num?)?.toDouble() ?? 0;
        if (Get.isRegistered<WalletController>()) {
          Get.find<WalletController>().balance.value = balance;
        }
        final store = WalletLocalStore(appPref);
        store.ensureInitialized();
        final gap = balance - store.balance;
        if (gap > 0.009) {
          store.credit(gap, description: 'Synced wallet balance');
        }
        return balance >= feeAmount;
      }
    } catch (_) {}

    return hasSufficientBalance(appPref);
  }

  static void markPendingFeeForOrder(AppPref appPref, String orderId) {
    appPref.addPendingPlatformFeeOrderId(orderId);
  }

  static bool consumePendingFeeForOrder(AppPref appPref, String orderId) {
    return appPref.consumePendingPlatformFeeOrderId(orderId);
  }

  /// Local debit used for offline wallet UX.
  static void debitLocal(AppPref appPref, {required String description}) {
    final store = WalletLocalStore(appPref);
    store.ensureInitialized();

    if (Get.isRegistered<WalletController>()) {
      final wc = Get.find<WalletController>();
      final gap = wc.balance.value - store.balance;
      if (gap > 0.009) {
        store.credit(gap, description: 'Synced wallet balance');
      }
    }

    store.debit(feeAmount, description: description);
    if (Get.isRegistered<WalletController>()) {
      Get.find<WalletController>().balance.value = store.balance;
    }
  }

  static Future<void> refreshWalletIfPossible() async {
    if (!Get.isRegistered<WalletController>()) return;
    try {
      await Get.find<WalletController>().loadWalletData();
    } catch (_) {}
  }
}
