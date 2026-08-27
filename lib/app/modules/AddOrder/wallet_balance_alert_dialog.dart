import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/billing/billing_access_mode.dart';
import 'package:billkaro/app/services/billing/platform_fee_service.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';

/// Alert when wallet balance is ₹100 or less on Create Order (wallet mode).
///
/// Returns `true` when the caller should exit the order screen (insufficient
/// balance and user dismissed / tapped recharge).
Future<bool> maybeShowWalletBalanceAlert({
  required AppPref appPref,
  ApiClient? apiClient,
}) async {
  if (!_shouldShowWalletAlert(appPref)) return false;

  final context = Get.context;
  if (context == null || !context.mounted) return false;

  final loc = AppLocalizations.of(context)!;
  var balance = PlatformFeeService.currentBalance(appPref);

  final outletId = appPref.selectedOutlet?.id;
  final userId = appPref.user?.id;
  final client =
      apiClient ??
      (Get.isRegistered<ApiClient>() ? Get.find<ApiClient>() : null);

  if (outletId != null && userId != null && client != null) {
    try {
      final res = await client.getOutletWallet(outletId, userId);
      if (res is Map && res['data'] is Map) {
        balance = (res['data']['balance'] as num?)?.toDouble() ?? balance;
      }
    } catch (_) {}
  }

  // Only alert when credit is ≤ ₹100.
  if (balance > PlatformFeeService.lowBalanceAlertThreshold) return false;

  if (!context.mounted) return false;

  final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
  final amountText = currency.format(balance);
  final isEmpty = balance < PlatformFeeService.feeAmount;

  await showDialog<void>(
    context: context,
    barrierDismissible: !isEmpty,
    builder: (dialogCtx) {
      return PopScope(
        canPop: !isEmpty,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && isEmpty) {
            Navigator.of(dialogCtx).pop();
          }
        },
        child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColor.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                color: AppColor.error,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc.wallet_title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.wallet_balance,
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amountText,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColor.error,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              isEmpty
                  ? 'Your wallet has insufficient balance. Recharge at least ₹${PlatformFeeService.feeAmount.toStringAsFixed(0)} before Save & Hold or Save & Bill.'
                  : '₹${PlatformFeeService.feeAmount.toStringAsFixed(0)} will be deducted from your wallet on every Save & Hold and Save & Bill.',
              style: TextStyle(
                fontSize: 13.5,
                height: 1.35,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Text(
                loc.wallet_low_balance_warning,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFFB91C1C),
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (!isEmpty)
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: Text(loc.got_it),
            ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              Modular.to.pushNamed(HomeMainRoutes.wallet);
            },
            icon: const Icon(Icons.add_card_outlined, size: 18),
            label: Text(loc.wallet_recharge),
          ),
        ],
      ),
      );
    },
  );

  return isEmpty;
}

bool _shouldShowWalletAlert(AppPref appPref) {
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
