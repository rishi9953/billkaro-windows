import 'dart:async';

import 'package:billkaro/app/Widgets/logout_dialog.dart';
import 'package:billkaro/app/services/Modals/login_response.dart';
import 'package:billkaro/app/services/common_function.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/date_util.dart';
import 'package:flutter_modular/flutter_modular.dart';

class _SidebarColors {
  static const textActive = Color(0xFFFFFFFF);
  static const textInactive = Color(0xFFD6DEEE);
  static const iconInactive = Color(0xFFC8D3E7);
  static const divider = Color(0xFF26324A);
}

class AppShellSidebar extends StatefulWidget {
  final int selectedIndex;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  const AppShellSidebar({
    super.key,
    required this.selectedIndex,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  static const double widthExpanded = 230;
  static const double widthCollapsed = 72;
  static const double navIconSize = 20;

  @override
  State<AppShellSidebar> createState() => _AppShellSidebarState();
}

class _AppShellSidebarState extends State<AppShellSidebar> {
  bool _itemsExpanded = false;
  bool _ordersExpanded = false;
  bool _reportsExpanded = false;
  Timer? _subscriptionTimer;

  @override
  void initState() {
    super.initState();
    _syncReportsExpansion();
    _subscriptionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _subscriptionTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AppShellSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncReportsExpansion();
  }

  void _syncReportsExpansion() {
    final path = Modular.to.path;
    final isItemsPath =
        path.startsWith(HomeMainRoutes.items) ||
        path.startsWith(HomeMainRoutes.addItem);
    final isReportPath =
        path.startsWith(HomeMainRoutes.reports) ||
        path.startsWith(HomeMainRoutes.orderReport) ||
        path.startsWith(HomeMainRoutes.itemsReport);
    final isOrdersPath =
        path.startsWith(HomeMainRoutes.closedOrders) ||
        path.startsWith(HomeMainRoutes.holdOrders);
    if (isItemsPath) {
      _itemsExpanded = true;
    }
    if (isOrdersPath) {
      _ordersExpanded = true;
    }
    if (isReportPath) {
      _reportsExpanded = true;
    }
    if (widget.collapsed) {
      _itemsExpanded = false;
      _ordersExpanded = false;
      _reportsExpanded = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasThemeController = Get.isRegistered<ThemeController>();
    final width = widget.collapsed
        ? AppShellSidebar.widthCollapsed
        : AppShellSidebar.widthExpanded;
    final currentPath = Modular.to.path;
    final isItemListSelected = currentPath.startsWith(HomeMainRoutes.items);
    final isAddItemSelected = currentPath.startsWith(HomeMainRoutes.addItem);
    final isOrderReportSelected = currentPath.startsWith(
      HomeMainRoutes.orderReport,
    );
    final isItemReportSelected = currentPath.startsWith(
      HomeMainRoutes.itemsReport,
    );
    final isClosedOrdersSelected = currentPath.startsWith(
      HomeMainRoutes.closedOrders,
    );
    final isHoldOrdersSelected = currentPath.startsWith(
      HomeMainRoutes.holdOrders,
    );

    // Obx must read at least one .obs — AppPref.isKOT is not reactive.
    // Only wrap in Obx when HomeScreenController provides Rx isKOT.
    if (Get.isRegistered<HomeScreenController>()) {
      return Obx(() {
        if (hasThemeController) {
          Get.find<ThemeController>().themeColor.value;
        }
        final hc = Get.find<HomeScreenController>();
        hc.isKOT.value;
        hc.selectedOutlet.value;
        return _sidebarColumn(
          context,
          loc: loc,
          width: width,
          currentPath: currentPath,
          isItemListSelected: isItemListSelected,
          isAddItemSelected: isAddItemSelected,
          isOrderReportSelected: isOrderReportSelected,
          isItemReportSelected: isItemReportSelected,
          isClosedOrdersSelected: isClosedOrdersSelected,
          isHoldOrdersSelected: isHoldOrdersSelected,
          kotEnabled:
              hc.isKOT.value && HomeMainRoutes.outletIsCafeOrRestaurant(),
          hasSeating: HomeMainRoutes.outletShowsTables(),
        );
      });
    }

    if (hasThemeController) {
      return Obx(() {
        Get.find<ThemeController>().themeColor.value;
        return _sidebarColumn(
          context,
          loc: loc,
          width: width,
          currentPath: currentPath,
          isItemListSelected: isItemListSelected,
          isAddItemSelected: isAddItemSelected,
          isOrderReportSelected: isOrderReportSelected,
          isItemReportSelected: isItemReportSelected,
          isClosedOrdersSelected: isClosedOrdersSelected,
          isHoldOrdersSelected: isHoldOrdersSelected,
          kotEnabled: HomeMainRoutes.kotFeatureEnabled(),
          hasSeating: HomeMainRoutes.outletShowsTables(),
        );
      });
    }

    return _sidebarColumn(
      context,
      loc: loc,
      width: width,
      currentPath: currentPath,
      isItemListSelected: isItemListSelected,
      isAddItemSelected: isAddItemSelected,
      isOrderReportSelected: isOrderReportSelected,
      isItemReportSelected: isItemReportSelected,
      isClosedOrdersSelected: isClosedOrdersSelected,
      isHoldOrdersSelected: isHoldOrdersSelected,
      kotEnabled: HomeMainRoutes.kotFeatureEnabled(),
      hasSeating: HomeMainRoutes.outletShowsTables(),
    );
  }

  Widget _sidebarColumn(
    BuildContext context, {
    required AppLocalizations loc,
    required double width,
    required String currentPath,
    required bool isItemListSelected,
    required bool isAddItemSelected,
    required bool isOrderReportSelected,
    required bool isItemReportSelected,
    required bool isClosedOrdersSelected,
    required bool isHoldOrdersSelected,
    required bool kotEnabled,
    required bool hasSeating,
  }) {
    final seatOffset = hasSeating ? 0 : -1;
    final iItems = 3 + seatOffset;
    final iOrders = 4 + seatOffset;
    final iReports = 5 + seatOffset;
    final iKot = 6 + seatOffset;
    final iCust = (kotEnabled ? 7 : 6) + seatOffset;
    final iPrinter = (kotEnabled ? 8 : 7) + seatOffset;
    final iStaff = (kotEnabled ? 9 : 8) + seatOffset;
    final iSubs = (kotEnabled ? 11 : 10) + seatOffset;
    final iWa = (kotEnabled ? 12 : 11) + seatOffset;
    final iSettings = (kotEnabled ? 13 : 12) + seatOffset;
    final iProfile = (kotEnabled ? 14 : 13) + seatOffset;
    final iLogout = (kotEnabled ? 15 : 14) + seatOffset;
    final primary = AppColor.primary;
    final sidebarTop = Color.alphaBlend(
      primary.withOpacity(0.24),
      const Color(0xFF0F172A),
    );
    final sidebarBottom = Color.alphaBlend(
      primary.withOpacity(0.12),
      const Color(0xFF070B17),
    );
    final activeBackground = primary.withOpacity(0.22);

    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [sidebarTop, sidebarBottom],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(context),

          const SizedBox(height: 8),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _navItem(
                    context: context,
                    index: 0,
                    label: 'Dashboard',
                    svgIcon: Assets.svg.home.svg(
                      width: AppShellSidebar.navIconSize,
                      height: AppShellSidebar.navIconSize,
                      colorFilter: ColorFilter.mode(
                        widget.selectedIndex == 0
                            ? _SidebarColors.textActive
                            : _SidebarColors.iconInactive,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  _navItem(
                    context: context,
                    index: 1,
                    label: 'Create Order',
                    svgIcon: Icon(
                      Icons.add_circle_outline_rounded,
                      size: AppShellSidebar.navIconSize,
                      color: widget.selectedIndex == 1
                          ? _SidebarColors.textActive
                          : _SidebarColors.iconInactive,
                    ),
                  ),
                  if (hasSeating)
                    _navItem(
                      context: context,
                      index: 2,
                      label: 'Tables',
                      svgIcon: Icon(
                        Icons.table_restaurant,
                        size: AppShellSidebar.navIconSize,
                        color: widget.selectedIndex == 2
                            ? _SidebarColors.textActive
                            : _SidebarColors.iconInactive,
                      ),
                    ),
                  if (widget.collapsed)
                    _navItem(
                      context: context,
                      index: iItems,
                      label: loc.items,
                      svgIcon: Assets.svg.items.svg(
                        width: AppShellSidebar.navIconSize,
                        height: AppShellSidebar.navIconSize,
                        colorFilter: ColorFilter.mode(
                          widget.selectedIndex == iItems
                              ? _SidebarColors.textActive
                              : _SidebarColors.iconInactive,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2.5,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.selectedIndex == iItems
                              ? activeBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            key: const PageStorageKey<String>(
                              'items-sidebar-tile',
                            ),
                            initiallyExpanded: _itemsExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() => _itemsExpanded = expanded);
                              if (expanded &&
                                  !currentPath.startsWith(
                                    HomeMainRoutes.items,
                                  ) &&
                                  !currentPath.startsWith(
                                    HomeMainRoutes.addItem,
                                  )) {
                                Modular.to.navigate(HomeMainRoutes.items);
                              }
                            },
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 1,
                            ),
                            childrenPadding: const EdgeInsets.only(
                              left: 46,
                              right: 10,
                              bottom: 6,
                            ),
                            iconColor: _SidebarColors.textInactive,
                            collapsedIconColor: _SidebarColors.textInactive,
                            leading: SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: Assets.svg.items.svg(
                                  width: AppShellSidebar.navIconSize,
                                  height: AppShellSidebar.navIconSize,
                                  colorFilter: ColorFilter.mode(
                                    widget.selectedIndex == iItems
                                        ? _SidebarColors.textActive
                                        : _SidebarColors.iconInactive,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              loc.items,
                              style: TextStyle(
                                color: widget.selectedIndex == iItems
                                    ? _SidebarColors.textActive
                                    : _SidebarColors.textInactive,
                                fontSize: 13.5,
                                fontWeight: widget.selectedIndex == iItems
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                            children: [
                              _reportChildItem(
                                context: context,
                                label: 'Item List',
                                selected: isItemListSelected,
                                onTap: () =>
                                    Modular.to.navigate(HomeMainRoutes.items),
                              ),
                              _reportChildItem(
                                context: context,
                                label: 'Add Item',
                                selected: isAddItemSelected,
                                onTap: () =>
                                    Modular.to.navigate(HomeMainRoutes.addItem),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (widget.collapsed)
                    _navItem(
                      context: context,
                      index: iOrders,
                      label: 'Orders',
                      svgIcon: Icon(
                        Icons.receipt_long_outlined,
                        size: AppShellSidebar.navIconSize,
                        color: widget.selectedIndex == iOrders
                            ? _SidebarColors.textActive
                            : _SidebarColors.iconInactive,
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2.5,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.selectedIndex == iOrders
                              ? activeBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            key: const PageStorageKey<String>(
                              'orders-sidebar-tile',
                            ),
                            initiallyExpanded: _ordersExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() => _ordersExpanded = expanded);
                              if (expanded &&
                                  !currentPath.startsWith(
                                    HomeMainRoutes.closedOrders,
                                  ) &&
                                  !currentPath.startsWith(
                                    HomeMainRoutes.holdOrders,
                                  )) {
                                Modular.to.navigate(
                                  HomeMainRoutes.closedOrders,
                                );
                              }
                            },
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 1,
                            ),
                            childrenPadding: const EdgeInsets.only(
                              left: 46,
                              right: 10,
                              bottom: 6,
                            ),
                            iconColor: _SidebarColors.textInactive,
                            collapsedIconColor: _SidebarColors.textInactive,
                            leading: SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: Icon(
                                  Icons.receipt_long_outlined,
                                  size: AppShellSidebar.navIconSize,
                                  color: widget.selectedIndex == iOrders
                                      ? _SidebarColors.textActive
                                      : _SidebarColors.iconInactive,
                                ),
                              ),
                            ),
                            title: Text(
                              'Orders',
                              style: TextStyle(
                                color: widget.selectedIndex == iOrders
                                    ? _SidebarColors.textActive
                                    : _SidebarColors.textInactive,
                                fontSize: 13.5,
                                fontWeight: widget.selectedIndex == iOrders
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                            children: [
                              _reportChildItem(
                                context: context,
                                label: loc.closedOrders,
                                selected: isClosedOrdersSelected,
                                onTap: () => Modular.to.navigate(
                                  HomeMainRoutes.closedOrders,
                                ),
                              ),
                              _reportChildItem(
                                context: context,
                                label: loc.onHoldOrders,
                                selected: isHoldOrdersSelected,
                                onTap: () => Modular.to.navigate(
                                  HomeMainRoutes.holdOrders,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (widget.collapsed)
                    _navItem(
                      context: context,
                      index: iReports,
                      label: loc.reports,
                      svgIcon: Assets.svg.reports.svg(
                        width: AppShellSidebar.navIconSize,
                        height: AppShellSidebar.navIconSize,
                        colorFilter: ColorFilter.mode(
                          widget.selectedIndex == iReports
                              ? _SidebarColors.textActive
                              : _SidebarColors.iconInactive,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2.5,
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: widget.selectedIndex == iReports
                              ? activeBackground
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Theme(
                          data: Theme.of(
                            context,
                          ).copyWith(dividerColor: Colors.transparent),
                          child: ExpansionTile(
                            key: const PageStorageKey<String>(
                              'reports-sidebar-tile',
                            ),
                            initiallyExpanded: _reportsExpanded,
                            onExpansionChanged: (expanded) {
                              setState(() => _reportsExpanded = expanded);
                              if (expanded &&
                                  !currentPath.startsWith(
                                    HomeMainRoutes.reports,
                                  ) &&
                                  !currentPath.startsWith(
                                    HomeMainRoutes.orderReport,
                                  ) &&
                                  !currentPath.startsWith(
                                    HomeMainRoutes.itemsReport,
                                  )) {
                                Modular.to.navigate(HomeMainRoutes.reports);
                              }
                            },
                            tilePadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 1,
                            ),
                            childrenPadding: const EdgeInsets.only(
                              left: 46,
                              right: 10,
                              bottom: 6,
                            ),
                            iconColor: _SidebarColors.textInactive,
                            collapsedIconColor: _SidebarColors.textInactive,
                            leading: SizedBox(
                              width: 24,
                              height: 24,
                              child: Center(
                                child: Assets.svg.reports.svg(
                                  width: AppShellSidebar.navIconSize,
                                  height: AppShellSidebar.navIconSize,
                                  colorFilter: ColorFilter.mode(
                                    widget.selectedIndex == iReports
                                        ? _SidebarColors.textActive
                                        : _SidebarColors.iconInactive,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              loc.reports,
                              style: TextStyle(
                                color: widget.selectedIndex == iReports
                                    ? _SidebarColors.textActive
                                    : _SidebarColors.textInactive,
                                fontSize: 13.5,
                                fontWeight: widget.selectedIndex == iReports
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                letterSpacing: 0.1,
                              ),
                            ),
                            children: [
                              _reportChildItem(
                                context: context,
                                label: loc.order_Reports,
                                selected: isOrderReportSelected,
                                onTap: () => Modular.to.navigate(
                                  HomeMainRoutes.orderReport,
                                ),
                              ),
                              _reportChildItem(
                                context: context,
                                label: loc.item_Reports,
                                selected: isItemReportSelected,
                                onTap: () => Modular.to.navigate(
                                  HomeMainRoutes.itemsReport,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (kotEnabled)
                    _navItem(
                      context: context,
                      index: iKot,
                      label: 'KOT History',
                      svgIcon: Icon(
                        Icons.history_rounded,
                        size: AppShellSidebar.navIconSize,
                        color: widget.selectedIndex == iKot
                            ? _SidebarColors.textActive
                            : _SidebarColors.iconInactive,
                      ),
                    ),
                  _navItem(
                    context: context,
                    index: iCust,
                    label: loc.customers,
                    svgIcon: Assets.svg.group.svg(
                      width: AppShellSidebar.navIconSize,
                      height: AppShellSidebar.navIconSize,
                      colorFilter: ColorFilter.mode(
                        widget.selectedIndex == iCust
                            ? _SidebarColors.textActive
                            : _SidebarColors.iconInactive,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  _navItem(
                    context: context,
                    index: iPrinter,
                    label: loc.printer,
                    svgIcon: Icon(
                      Icons.print_rounded,
                      size: AppShellSidebar.navIconSize,
                      color: widget.selectedIndex == iPrinter
                          ? _SidebarColors.textActive
                          : _SidebarColors.iconInactive,
                    ),
                  ),
                  _navItem(
                    context: context,
                    index: iStaff,
                    label: loc.manage_staff,
                    svgIcon: Icon(
                      Icons.group_outlined,
                      size: AppShellSidebar.navIconSize,
                      color: widget.selectedIndex == iStaff
                          ? _SidebarColors.textActive
                          : _SidebarColors.iconInactive,
                    ),
                  ),
                  _navItem(
                    context: context,
                    index: iSubs,
                    label: 'Plans & Pricing',
                    svgIcon: Assets.plan.image(
                      width: AppShellSidebar.navIconSize,
                      height: AppShellSidebar.navIconSize,
                      color: widget.selectedIndex == iSubs
                          ? _SidebarColors.textActive
                          : _SidebarColors.iconInactive,
                    ),
                    //  Assets.svg.menu.svg(
                    //   width: 22,
                    //   height: 22,
                    //   colorFilter: ColorFilter.mode(
                    //     selectedIndex == 8
                    //         ? _SidebarColors.textActive
                    //         : _SidebarColors.iconInactive,
                    //     BlendMode.srcIn,
                    //   ),
                    // ),
                  ),
                  _navItem(
                    context: context,
                    index: iWa,
                    label: 'WhatsApp Marketing',
                    svgIcon: Icon(
                      Icons.campaign_outlined,
                      size: AppShellSidebar.navIconSize,
                      color: widget.selectedIndex == iWa
                          ? _SidebarColors.textActive
                          : _SidebarColors.iconInactive,
                    ),
                  ),
                  _navItem(
                    context: context,
                    index: iSettings,
                    label: 'Settings',
                    svgIcon: Icon(
                      Icons.settings_outlined,
                      size: AppShellSidebar.navIconSize,
                      color: widget.selectedIndex == iSettings
                          ? _SidebarColors.textActive
                          : _SidebarColors.iconInactive,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1, color: _SidebarColors.divider),
          _navItem(
            context: context,
            index: iProfile,
            label: 'Profile',
            svgIcon: Icon(
              Icons.person_rounded,
              size: AppShellSidebar.navIconSize,
              color: widget.selectedIndex == iProfile
                  ? _SidebarColors.textActive
                  : _SidebarColors.iconInactive,
            ),
          ),
          _navItem(
            context: context,
            index: iLogout,
            label: loc.logout,
            svgIcon: Icon(
              Icons.logout_rounded,
              size: AppShellSidebar.navIconSize,
              color: _SidebarColors.iconInactive,
            ),
            isSignOut: true,
          ),
          _buildSubscriptionInfoCard(),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final hasController = Get.isRegistered<HomeScreenController>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!widget.collapsed)
                Expanded(
                  child: hasController
                      ? Obx(
                          () => _buildHeaderExpanded(
                            context,
                            Get.find<HomeScreenController>()
                                .selectedOutlet
                                .value,
                          ),
                        )
                      : _buildHeaderExpanded(
                          context,
                          Get.find<AppPref>().selectedOutlet,
                        ),
                ),
              IconButton(
                onPressed: widget.onToggleCollapsed,
                icon: Icon(
                  widget.collapsed
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  color: _SidebarColors.textInactive,
                  size: 24,
                ),
                padding: const EdgeInsets.all(6),
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
            ],
          ),
          if (widget.collapsed) _buildCollapsedTrialCountdown(hasController),
        ],
      ),
    );
  }

  Widget _buildCollapsedTrialCountdown(bool hasHomeController) {
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
          _formatTimeRemaining(end),
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

  Widget _buildHeaderExpanded(BuildContext context, dynamic outlet) {
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
              ? CachedNetworkImage(
                  imageUrl: outlet.logo as String,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => _collapsePlaceholder(),
                  errorWidget: (_, __, ___) => _collapsePlaceholder(),
                )
              : _collapsePlaceholder(),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            name,
            style: const TextStyle(
              color: _SidebarColors.textActive,
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

  Widget _collapsePlaceholder() {
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

  Widget _navItem({
    required BuildContext context,
    required int index,
    required String label,
    required Widget svgIcon,
    bool isSignOut = false,
  }) {
    final isSelected = widget.selectedIndex == index && !isSignOut;
    final isLogout = isSignOut;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
      child: Material(
        color: isSelected
            ? AppColor.primary.withOpacity(0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () async {
            if (isLogout) {
              showLogoutDialog(context, AppLocalizations.of(context)!);
              return;
            }

            final targetRoute = HomeMainRoutes.routeForIndex(index);
            final isLeavingCreateOrder =
                Modular.to.path.startsWith(HomeMainRoutes.createOrder) &&
                targetRoute != HomeMainRoutes.createOrder;
            if (isLeavingCreateOrder) {
              final shouldLeave = await _confirmLeaveCreateOrder(context);
              if (!shouldLeave) return;
            }

            if (index == 1 && Get.isRegistered<AddOrderController>()) {
              Get.delete<AddOrderController>();
            }

            if (targetRoute == HomeMainRoutes.staff) {
              Modular.to.navigate('${HomeMainRoutes.staff}?fromSidebar=true');
            } else {
              Modular.to.navigate(targetRoute);
            }

            if (HomeMainRoutes.outletShowsTables() && index == 2) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (Get.isRegistered<TableController>()) {
                  Get.find<TableController>().refresh();
                }
              });
            }
          },
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 10 : 12,
              vertical: 9.5,
            ),
            child: Row(
              children: [
                if (isSelected && !widget.collapsed)
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                SizedBox(width: 24, height: 24, child: Center(child: svgIcon)),
                if (!widget.collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSignOut
                            ? _SidebarColors.textInactive
                            : (isSelected
                                  ? _SidebarColors.textActive
                                  : _SidebarColors.textInactive),
                        fontSize: 13.5,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _reportChildItem({
    required BuildContext context,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 2),
      child: Material(
        color: selected
            ? AppColor.primary.withOpacity(0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColor.primary
                        : _SidebarColors.iconInactive,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selected
                          ? _SidebarColors.textActive
                          : _SidebarColors.textInactive,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionInfoCard() {
    final hasController = Get.isRegistered<HomeScreenController>();
    final outlet = hasController
        ? Get.find<HomeScreenController>().selectedOutlet.value
        : Get.find<AppPref>().selectedOutlet;
    final user = Get.find<AppPref>().user;
    final subscriptionData = _resolveSubscriptionData(outlet, user);

    if (subscriptionData == null) return const SizedBox.shrink();

    final compact = widget.collapsed;
    final remaining = _formatTimeRemaining(subscriptionData.endDate);
    final validTill = formatDateTimeForDisplay(
      subscriptionData.endDate,
      'dd MMM yyyy, hh:mm a',
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        compact ? 6 : 10,
        compact ? 8 : 12,
        6,
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF182538), Color(0xFF0D1524)],
          ),
          borderRadius: BorderRadius.circular(compact ? 10 : 12),
          border: Border.all(color: Colors.white12),
        ),
        padding: EdgeInsets.all(compact ? 8 : 10),
        child: Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            Text(
              compact
                  ? '${subscriptionData.daysLeft}d\n${subscriptionData.label}'
                  : '${subscriptionData.daysLeft} days ${subscriptionData.label} left',
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                color: Colors.white,
                fontSize: compact ? 10 : 11.5,
                fontWeight: FontWeight.w600,
                height: compact ? 1.15 : null,
              ),
            ),
            SizedBox(height: compact ? 6 : 8),
            LinearProgressIndicator(
              value: subscriptionData.progress,
              minHeight: compact ? 4 : 5,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              backgroundColor: const Color(0xFF3D4558),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFF55A7A),
              ),
            ),
            SizedBox(height: compact ? 5 : 7),
            Text(
              compact ? remaining : 'Remaining: $remaining',
              textAlign: compact ? TextAlign.center : TextAlign.start,
              style: TextStyle(
                color: Colors.white70,
                fontSize: compact ? 9.5 : 10.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (!compact) ...[
              const SizedBox(height: 2),
              Text(
                'Valid till: $validTill',
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
  }

  _SubscriptionCardData? _resolveSubscriptionData(
    OutletData? outlet,
    User? user,
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
        label: 'Subscription',
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
          label: 'Free Trial',
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

  String _formatTimeRemaining(DateTime endDate) {
    final now = DateTime.now();
    final diff = endDate.difference(now);
    if (diff.isNegative) return 'Expired';

    final d = diff.inDays;
    final h = diff.inHours % 24;
    final m = diff.inMinutes % 60;
    final s = diff.inSeconds % 60;
    return '${d}d ${h}h ${m}m ${s}s';
  }

  Future<bool> _confirmLeaveCreateOrder(BuildContext context) async {
    if (!Get.isRegistered<AddOrderController>()) return true;

    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          constraints: const BoxConstraints(maxWidth: 360),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          title: const Text('Discard order?'),
          content: const Text(
            'You have unsaved order changes. Are you sure you want to leave this screen?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Stay'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Leave'),
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false;
  }
}

class _SubscriptionCardData {
  final String label;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  final int daysLeft;

  const _SubscriptionCardData({
    required this.label,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.daysLeft,
  });
}
