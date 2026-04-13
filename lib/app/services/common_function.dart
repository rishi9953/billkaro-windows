import 'package:billkaro/app/Widgets/membershipSheet.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/config/config.dart';
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

/// Returns true if the user can access features that require trial or subscription.
/// Allowed when: user is on an active trial (isTrial and within [kFreeTrialDuration]
/// from [trialCreatedAtStart]) OR selected outlet has subscription.
/// Not allowed when: isTrial == false and selected outlet has no subscription.
/// Use for voice add item, or any other feature gated by trial/subscription.
bool hasTrialOrSubscription(AppPref appPref) {
  final user = appPref.user;
  if (user == null) return false;

  if (user.isTrial == true) {
    final end = trialEndDate(appPref.selectedOutlet, user);
    if (end == null) return true;
    return DateTime.now().isBefore(end);
  }

  // Non-trial: allow only if selected outlet has subscription
  final subs = appPref.selectedOutlet?.subscriptions;
  final outletHasSubscription = subs != null && subs.isNotEmpty;
  return outletHasSubscription;
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
    return DateTime.fromMillisecondsSinceEpoch(asInt * 1000, isUtc: true)
        .toLocal();
  }
  return DateTime.fromMillisecondsSinceEpoch(asInt, isUtc: true).toLocal();
}

/// Returns plan IDs for subscriptions that are still active (endDate in future).
Set<String> activeSubscriptionPlanIdsFromOutlet(OutletData? outlet,
    {DateTime? now}) {
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

bool outletHasActiveSubscriptionForPlan(OutletData? outlet, String? planId,
    {DateTime? now}) {
  if (planId == null || planId.trim().isEmpty) return false;
  final ids = activeSubscriptionPlanIdsFromOutlet(outlet, now: now);
  return ids.contains(planId.trim());
}

Future<void> openWhatsApp(String phoneNumber) async {
  final phone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), ''); // Remove spaces
  final message = Uri.encodeComponent('Hi');
  final whatsappUrl = 'https://wa.me/$phone?text=$message';

  final uri = Uri.parse(whatsappUrl);

  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else {
    showError(description: 'Could not open WhatsApp');
  }
}

Future<void> checkSubscription() async {
  final appPref = Get.find<AppPref>();
  // Check if user is on trial
  if (appPref.user != null && appPref.user?.isTrial == false) {
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
}

Future<void> callCheckSubscription() async {
  final appPref = Get.find<AppPref>();
  if (!hasTrialOrSubscription(appPref)) {
    checkSubscription();
    return;
  }
}
