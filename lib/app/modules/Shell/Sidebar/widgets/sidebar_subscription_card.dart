import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/app_shell_sidebar_controller.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_header.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter/material.dart';

class SidebarSubscriptionCard extends StatelessWidget {
  const SidebarSubscriptionCard({
    super.key,
    required this.collapsed,
    required this.loc,
  });

  final bool collapsed;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<AppShellSidebarController>(
      id: 'subscription',
      builder: (_) {
        final hasController = Get.isRegistered<HomeScreenController>();
        final outlet = hasController
            ? Get.find<HomeScreenController>().selectedOutlet.value
            : Get.find<AppPref>().selectedOutlet;
        final user = Get.find<AppPref>().user;
        final subscriptionData = _resolveSubscriptionData(outlet, user, loc);

        if (subscriptionData == null) return const SizedBox.shrink();

        final remaining = SidebarSubscriptionFormatter.formatTimeRemaining(
          subscriptionData.endDate,
          loc,
        );
        final validTill = formatDateTimeForDisplay(
          subscriptionData.endDate,
          'dd MMM yyyy, hh:mm a',
        );

        return Padding(
          padding: EdgeInsets.fromLTRB(
            collapsed ? 8 : 12,
            collapsed ? 6 : 10,
            collapsed ? 8 : 12,
            6,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF182538), Color(0xFF0D1524)],
              ),
              borderRadius: BorderRadius.circular(collapsed ? 10 : 12),
              border: Border.all(color: Colors.white12),
            ),
            padding: EdgeInsets.all(collapsed ? 8 : 10),
            child: Column(
              crossAxisAlignment: collapsed
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  collapsed
                      ? loc.subscription_days_left_compact(
                          subscriptionData.daysLeft.toString(),
                          subscriptionData.label,
                        )
                      : loc.subscription_days_left(
                          subscriptionData.daysLeft.toString(),
                          subscriptionData.label,
                        ),
                  textAlign: collapsed ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: collapsed ? 10 : 11.5,
                    fontWeight: FontWeight.w600,
                    height: collapsed ? 1.15 : null,
                  ),
                ),
                SizedBox(height: collapsed ? 6 : 8),
                LinearProgressIndicator(
                  value: subscriptionData.progress,
                  minHeight: collapsed ? 4 : 5,
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  backgroundColor: const Color(0xFF3D4558),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFF55A7A),
                  ),
                ),
                SizedBox(height: collapsed ? 5 : 7),
                Text(
                  collapsed ? remaining : loc.remaining_label(remaining),
                  textAlign: collapsed ? TextAlign.center : TextAlign.start,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: collapsed ? 9.5 : 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!collapsed) ...[
                  const SizedBox(height: 2),
                  Text(
                    loc.valid_till_label(validTill),
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SubscriptionCardData {
  const _SubscriptionCardData({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.daysLeft,
  });

  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  final int daysLeft;
}

_SubscriptionCardData? _resolveSubscriptionData(
  OutletData? outlet,
  User? user,
  AppLocalizations loc,
) {
  final now = DateTime.now();

  final subscriptions = outlet?.subscriptions ?? const <OutletSubscription>[];
  OutletSubscription? activeSubscription;
  DateTime? activeEndDate;

  for (final sub in subscriptions) {
    final parsedEnd = sub.endDate != null
        ? tryParseDateTimeLoose(sub.endDate!)
        : null;
    if (parsedEnd == null) continue;
    if (parsedEnd.isAfter(now)) {
      activeSubscription = sub;
      activeEndDate = parsedEnd;
      break;
    }
  }

  if (activeSubscription != null && activeEndDate != null) {
    final parsedStart = activeSubscription.startDate != null
        ? tryParseDateTimeLoose(activeSubscription.startDate!)
        : null;
    final fallbackStart = activeEndDate.subtract(const Duration(days: 30));
    final start = parsedStart ?? fallbackStart;
    return _toCardData(
      now: now,
      startDate: start,
      endDate: activeEndDate,
      label: loc.subscription_label,
    );
  }

  if (user?.isTrial == true) {
    final createdAt = trialCreatedAtStart(outlet, user);
    final trialEnd = trialEndDate(outlet, user);
    if (createdAt != null && trialEnd != null) {
      return _toCardData(
        now: now,
        startDate: createdAt,
        endDate: trialEnd,
        label: loc.free_trial,
      );
    }
  }

  return null;
}

_SubscriptionCardData _toCardData({
  required DateTime now,
  required DateTime startDate,
  required DateTime endDate,
  required String label,
}) {
  final totalSeconds = endDate.difference(startDate).inSeconds;
  final remainingSeconds = endDate.difference(now).inSeconds;
  final safeTotal = totalSeconds <= 0 ? 1 : totalSeconds;
  final remainingClamped = remainingSeconds.clamp(0, safeTotal);
  final progress = (remainingClamped / safeTotal).toDouble().clamp(0.0, 1.0);
  final daysLeft = endDate.isBefore(now)
      ? 0
      : endDate.difference(now).inDays + 1;

  return _SubscriptionCardData(
    label: label,
    startDate: startDate,
    endDate: endDate,
    progress: progress,
    daysLeft: daysLeft,
  );
}
