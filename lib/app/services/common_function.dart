import 'package:billkaro/app/Widgets/membershipSheet.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/billing/billing_access_mode.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Free trial length from account/outlet `createdAt`.
const Duration kFreeTrialDuration = Duration(days: 7);

/// Trial start: selected outlet `createdAt`, else any [user.outletData] outlet, else [user.createdAt].
DateTime? trialCreatedAtStart(OutletData? outlet, User? user) {
  if (outlet?.createdAt != null && outlet!.createdAt!.isNotEmpty) {
    final d = tryParseDateTimeLoose(outlet.createdAt!);
    if (d != null) return d;
  }
  final list = user?.outletData;
  if (list != null) {
    for (final o in list) {
      if (o.createdAt != null && o.createdAt!.isNotEmpty) {
        final d = tryParseDateTimeLoose(o.createdAt!);
        if (d != null) return d;
      }
    }
  }
  if (user?.createdAt != null && user!.createdAt!.isNotEmpty) {
    final d = tryParseDateTimeLoose(user.createdAt!);
    if (d != null) return d;
  }
  return null;
}

/// End of free trial for [user] on [outlet], or null if not on trial or no start date.
DateTime? trialEndDate(OutletData? outlet, User? user) {
  if (user?.isTrial != true) return null;
  final start = trialCreatedAtStart(outlet, user);
  if (start == null) return null;
  return start.add(kFreeTrialDuration);
}

/// Returns true if the user can access features that require billing entitlement.
///
/// - Active trial → always allowed
/// - [BillingAccessMode.wallet] → allowed (pay-as-you-go)
/// - [BillingAccessMode.subscription] → requires an active outlet subscription
bool hasTrialOrSubscription(AppPref appPref) {
  final user = appPref.user;
  if (user == null) return false;

  if (user.isTrial == true) {
    final end = trialEndDate(appPref.selectedOutlet, user);
    if (end == null) return true;
    return DateTime.now().isBefore(end);
  }

  final mode = BillingAccessModeX.fromStorage(
    appPref.billingAccessModeRawForOutlet(appPref.selectedOutlet?.id),
  );
  if (mode.isWallet) return true;

  // Subscription mode: allow if selected outlet (or matched user outlet) has active subscription.
  final selectedOutlet = appPref.selectedOutlet;
  if (outletHasAnyActiveSubscription(selectedOutlet)) return true;

  final outlets = user.outletData;
  if (outlets == null || outlets.isEmpty) return false;

  if (selectedOutlet?.id != null && selectedOutlet!.id!.trim().isNotEmpty) {
    final selectedId = selectedOutlet.id!.trim();
    for (final outlet in outlets) {
      if (outlet.id == selectedId) {
        return outletHasAnyActiveSubscription(outlet);
      }
    }
  }

  // Fallback for cases where no outlet is selected yet in preferences.
  for (final outlet in outlets) {
    if (outletHasAnyActiveSubscription(outlet)) return true;
  }
  return false;
}

DateTime? tryParseDateTimeLoose(String value) {
  final v = value.trim();
  if (v.isEmpty) return null;

  final parsed = DateTime.tryParse(v);
  if (parsed != null) return parsed;

  // Common backend date formats (non-ISO). If it's a date-only string,
  // treat it as end-of-day to avoid prematurely marking it expired.
  const dateOnlyFormats = <String>[
    'dd/MM/yyyy',
    'dd-MM-yyyy',
    'yyyy/MM/dd',
    'yyyy-MM-dd',
  ];
  for (final f in dateOnlyFormats) {
    try {
      final dt = DateFormat(f).parseStrict(v);
      return DateTime(dt.year, dt.month, dt.day, 23, 59, 59, 999);
    } catch (_) {
      // try next format
    }
  }

  const dateTimeFormats = <String>[
    'yyyy-MM-dd HH:mm:ss',
    'yyyy-MM-dd HH:mm:ss.SSS',
    'dd/MM/yyyy HH:mm:ss',
    'dd-MM-yyyy HH:mm:ss',
    'dd/MM/yyyy HH:mm',
    'dd-MM-yyyy HH:mm',
  ];
  for (final f in dateTimeFormats) {
    try {
      return DateFormat(f).parseStrict(v);
    } catch (_) {
      // try next format
    }
  }

  // Some backends return epoch timestamps as strings.
  final asInt = int.tryParse(v);
  if (asInt == null) return null;

  // Heuristic: 10-digit => seconds, 13-digit => millis.
  if (v.length <= 10) {
    return DateTime.fromMillisecondsSinceEpoch(
      asInt * 1000,
      isUtc: true,
    ).toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(asInt, isUtc: true).toLocal();
}

/// Returns plan IDs for subscriptions that are still active (endDate in future).
Set<String> activeSubscriptionPlanIdsFromOutlet(
  OutletData? outlet, {
  DateTime? now,
}) {
  final subs = outlet?.subscriptions;
  if (subs == null || subs.isEmpty) return <String>{};
  final current = now ?? DateTime.now();
  final ids = <String>{};
  for (final s in subs) {
    final endStr = s.endDate;
    if (endStr == null || endStr.trim().isEmpty) continue;
    final endDate = tryParseDateTimeLoose(endStr);
    if (endDate != null && endDate.isAfter(current)) {
      final id = s.subscription?.id;
      if (id != null && id.trim().isNotEmpty) ids.add(id.trim());
    }
  }
  return ids;
}

/// Returns true when the outlet has any subscription that appears active.
///
/// - If `endDate` is missing/unparseable for a subscription entry, we conservatively
///   treat it as active to avoid allowing duplicate purchases.
bool outletHasAnyActiveSubscription(OutletData? outlet, {DateTime? now}) {
  final subs = outlet?.subscriptions;
  if (subs == null || subs.isEmpty) return false;
  final current = now ?? DateTime.now();

  for (final s in subs) {
    final endStr = s.endDate;
    if (endStr == null || endStr.trim().isEmpty) return true;
    final endDate = tryParseDateTimeLoose(endStr);
    if (endDate == null) return true;
    if (endDate.isAfter(current)) return true;
  }
  return false;
}

bool outletHasActiveSubscriptionForPlan(
  OutletData? outlet,
  String? planId, {
  DateTime? now,
}) {
  if (planId == null || planId.trim().isEmpty) return false;
  final ids = activeSubscriptionPlanIdsFromOutlet(outlet, now: now);
  return ids.contains(planId.trim());
}

String buildRegularCustomerWelcomeMessage({
  required String outletName,
  required String customerName,
  required String phoneNumber,
  required double loyaltyDiscount,
  String loyaltyDiscountType = 'percentage',
}) {
  final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
  final displayPhone = digits.length >= 10
      ? '+91${digits.substring(digits.length - 10)}'
      : phoneNumber;
  final isAmount = loyaltyDiscountType == 'amount';
  final discountLine = loyaltyDiscount > 0
      ? isAmount
          ? 'Loyalty Discount: ₹$loyaltyDiscount off on your orders'
          : 'Loyalty Discount: $loyaltyDiscount% on your orders'
      : 'You are now registered as our regular customer';

  return '''Hello $customerName! 👋

Welcome to $outletName! 🎉

You have been added as our regular customer.

📱 Phone: $displayPhone
$discountLine

Thank you for choosing $outletName. We look forward to serving you! ❤️''';
}

Future<void> openWhatsApp(
  String phoneNumber, {
  String? message,
}) async {
  final digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
  final phone = digits.length >= 10
      ? '91${digits.substring(digits.length - 10)}'
      : digits.replaceAll(RegExp(r'[^\d+]'), '');
  final encodedMessage = Uri.encodeComponent(message ?? 'Hi');
  final whatsappUrl = 'https://wa.me/$phone?text=$encodedMessage';

  final uri = Uri.parse(whatsappUrl);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    showError(description: 'Could not open WhatsApp');
  }
}

Future<void> sendRegularCustomerWelcomeWhatsApp({
  required String phoneNumber,
  required String customerName,
  required double loyaltyDiscount,
  String loyaltyDiscountType = 'percentage',
  required String outletName,
  bool serverSent = false,
}) async {
  if (serverSent) return;

  final message = buildRegularCustomerWelcomeMessage(
    outletName: outletName,
    customerName: customerName,
    phoneNumber: phoneNumber,
    loyaltyDiscount: loyaltyDiscount,
    loyaltyDiscountType: loyaltyDiscountType,
  );
  await openWhatsApp(phoneNumber, message: message);
}

Future<void> checkSubscription() async {
  final appPref = Get.find<AppPref>();
  if (hasTrialOrSubscription(appPref)) return;

  final mode = BillingAccessModeX.fromStorage(
    appPref.billingAccessModeRawForOutlet(appPref.selectedOutlet?.id),
  );

  // Wallet mode without entitlement (e.g. logged out edge cases): send to wallet.
  if (mode.isWallet) {
    Modular.to.pushNamed(HomeMainRoutes.wallet);
    return;
  }

  showModalBottomSheet(
    context: Get.context!,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const GoldMembershipSheet(),
  );
}

Future<void> callCheckSubscription() async {
  final appPref = Get.find<AppPref>();
  if (!hasTrialOrSubscription(appPref)) {
    checkSubscription();
    return;
  }
}
