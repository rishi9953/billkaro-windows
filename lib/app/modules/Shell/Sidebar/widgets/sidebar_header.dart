import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_theme.dart';
import 'package:billkaro/app/modules/StoreSession/store_session_widget.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/config/config.dart';

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({
    super.key,
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.loc,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final hasController = Get.isRegistered<HomeScreenController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!collapsed)
                Expanded(
                  child: hasController
                      ? Obx(
                          () => _HeaderExpanded(
                            outlet: Get.find<HomeScreenController>()
                                .selectedOutlet
                                .value,
                          ),
                        )
                      : _HeaderExpanded(
                          outlet: Get.find<AppPref>().selectedOutlet,
                        ),
                ),
              IconButton(
                onPressed: onToggleCollapsed,
                icon: Icon(
                  collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  color: SidebarColors.textInactive,
                  size: 24,
                ),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          if (collapsed) _CollapsedTrialCountdown(loc: loc),
          if (!collapsed) const StoreSessionSidebarInfo(),
        ],
      ),
    );
  }
}

class _HeaderExpanded extends StatelessWidget {
  const _HeaderExpanded({required this.outlet});

  final dynamic outlet;

  @override
  Widget build(BuildContext context) {
    final hasLogo =
        (outlet?.logo is String) && (outlet.logo as String).isNotEmpty;
    final name =
        (outlet?.businessName is String) &&
            (outlet.businessName as String).isNotEmpty
        ? (outlet.businessName as String)
        : 'बिल करो चिल करो';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: hasLogo
              ? AppCachedNetworkImage(
                  imageUrl: resolvedMediaUrl(outlet.logo as String),
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => const _LogoPlaceholder(),
                  errorWidget: (_, __, ___) => const _LogoPlaceholder(),
                )
              : const _LogoPlaceholder(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: SidebarColors.textActive,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _LogoPlaceholder extends StatelessWidget {
  const _LogoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColor.primary.withOpacity(0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(
        Icons.store_rounded,
        color: AppColor.secondaryPrimary,
        size: 22,
      ),
    );
  }
}

class _CollapsedTrialCountdown extends StatelessWidget {
  const _CollapsedTrialCountdown({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final hasHomeController = Get.isRegistered<HomeScreenController>();

    Widget buildInner() {
      final outlet = hasHomeController
          ? Get.find<HomeScreenController>().selectedOutlet.value
          : Get.find<AppPref>().selectedOutlet;
      final user = Get.find<AppPref>().user;
      final end = trialEndDate(outlet, user);
      if (end == null) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          SidebarSubscriptionFormatter.formatTimeRemaining(end, loc),
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
            color: Color(0xFFFFD88A),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      );
    }

    if (hasHomeController) {
      return Obx(() {
        Get.find<HomeScreenController>().selectedOutlet.value;
        return buildInner();
      });
    }
    return buildInner();
  }
}

/// Shared time-remaining formatter for header and subscription card.
abstract final class SidebarSubscriptionFormatter {
  static String formatTimeRemaining(DateTime endDate, AppLocalizations loc) {
    final now = DateTime.now();
    final diff = endDate.difference(now);
    if (diff.isNegative) return loc.expired;

    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    return '${d}d ${h}h ${m}m ${s}s';
  }
}
