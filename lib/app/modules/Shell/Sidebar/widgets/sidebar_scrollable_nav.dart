import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/app_shell_sidebar_controller.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_layout.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_nav_indices.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_route_selection.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_theme.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_child_nav_item.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_expansion_nav.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_nav_item.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/kitchen_display_browser.dart';
import 'package:billkaro/utils/kitchen_display_window_launcher.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

class SidebarScrollableNav extends StatelessWidget {
  const SidebarScrollableNav({
    super.key,
    required this.loc,
    required this.selectedIndex,
    required this.collapsed,
    required this.currentPath,
    required this.kotEnabled,
    required this.hasSeating,
    required this.indices,
    required this.routes,
    required this.sidebarController,
    required this.onStateChange,
    required this.scrollController,
    required this.activeBackground,
  });

  final AppLocalizations loc;
  final int selectedIndex;
  final bool collapsed;
  final String currentPath;
  final bool kotEnabled;
  final bool hasSeating;
  final SidebarNavIndices indices;
  final SidebarRouteSelection routes;
  final AppShellSidebarController sidebarController;
  final VoidCallback onStateChange;
  final ScrollController scrollController;
  final Color activeBackground;

  Color get _active => SidebarColors.textActive;
  Color get _inactive => SidebarColors.iconInactive;

  @override
  Widget build(BuildContext context) {
    return ScrollbarTheme(
      data: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.dragged)) return Colors.white;
          if (states.contains(WidgetState.hovered)) {
            return Colors.grey.shade300;
          }
          return Colors.grey.shade400;
        }),
        trackColor: WidgetStateProperty.all(Colors.white.withOpacity(0.16)),
        trackBorderColor: WidgetStateProperty.all(
          Colors.white.withOpacity(0.22),
        ),
      ),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        trackVisibility: true,
        interactive: true,
        thickness: 8,
        radius: const Radius.circular(8),
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _nav(
                index: 0,
                label: loc.dashboard,
                icon: Assets.svg.home.svg(
                  width: SidebarLayout.navIconSize,
                  height: SidebarLayout.navIconSize,
                  colorFilter: ColorFilter.mode(
                    selectedIndex == 0 ? _active : _inactive,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              if (StaffAccess.canShowCreateOrder)
                _nav(
                  index: indices.createOrder,
                  label: loc.create_order,
                  icon: Icon(
                    Icons.add_circle_outline_rounded,
                    size: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.createOrder
                        ? _active
                        : _inactive,
                  ),
                ),
              if (hasSeating && StaffAccess.canAccessTables)
                _nav(
                  index: indices.tables,
                  label: loc.tables,
                  icon: Icon(
                    Icons.table_restaurant,
                    size: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.tables
                        ? _active
                        : _inactive,
                  ),
                ),
              if (StaffAccess.canAccessProducts) _buildItemsSection(context),
              if (StaffAccess.canShowOrdersList) _buildOrdersSection(context),
              if (StaffAccess.canViewInventory)
                _nav(
                  index: indices.inventory,
                  label: loc.inventory,
                  icon: Icon(
                    Icons.inventory_2_outlined,
                    size: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.inventory
                        ? _active
                        : _inactive,
                  ),
                ),
              if (StaffAccess.canViewInventory) _buildPurchasesSection(context),
              if (StaffAccess.canViewReports) _buildReportsSection(context),
              if (kotEnabled && StaffAccess.canViewKot)
                _nav(
                  index: indices.kot,
                  label: loc.kot_history,
                  icon: Icon(
                    Icons.history_rounded,
                    size: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.kot ? _active : _inactive,
                  ),
                ),
              if (kotEnabled && StaffAccess.canOpenKitchenDisplay)
                _nav(
                  index: indices.kds,
                  label: loc.kitchen_display,
                  icon: Icon(
                    Icons.soup_kitchen_rounded,
                    size: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.kds ? _active : _inactive,
                  ),
                  onTapOverride: KitchenDisplayWindowLauncher.open,
                  trailing: !collapsed
                      ? IconButton(
                          tooltip: loc.open_kitchen_display_in_browser,
                          onPressed: KitchenDisplayBrowser.open,
                          icon: Icon(
                            Icons.open_in_browser_rounded,
                            size: 18,
                            color: selectedIndex == indices.kds
                                ? _active
                                : _inactive,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                ),
              if (StaffAccess.canAccessCustomers)
                _nav(
                  index: indices.customers,
                  label: loc.customers,
                  icon: Assets.svg.group.svg(
                    width: SidebarLayout.navIconSize,
                    height: SidebarLayout.navIconSize,
                    colorFilter: ColorFilter.mode(
                      selectedIndex == indices.customers ? _active : _inactive,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              if (StaffAccess.canManageStaff)
                _nav(
                  index: indices.staff,
                  label: loc.manage_staff,
                  icon: Icon(
                    Icons.group_outlined,
                    size: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.staff ? _active : _inactive,
                  ),
                ),
              if (StaffAccess.canManageSubscriptions)
                _nav(
                  index: indices.subscriptions,
                  label: loc.plans_and_pricing,
                  icon: Assets.plan.image(
                    width: SidebarLayout.navIconSize,
                    height: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.subscriptions
                        ? _active
                        : _inactive,
                  ),
                ),
              if (StaffAccess.isOwnerSession)
                _nav(
                  index: -1,
                  label: loc.wallet_title,
                  selectedOverride: routes.wallet,
                  icon: Icon(
                    Icons.account_balance_wallet_outlined,
                    size: SidebarLayout.navIconSize,
                    color: routes.wallet ? _active : _inactive,
                  ),
                  onTapOverride: () async {
                    Modular.to.navigate(HomeMainRoutes.wallet);
                  },
                ),
              if (StaffAccess.canUseWhatsAppMarketing)
                _nav(
                  index: indices.whatsapp,
                  label: loc.whatsapp_marketing,
                  icon: Icon(
                    Icons.campaign_outlined,
                    size: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.whatsapp
                        ? _active
                        : _inactive,
                  ),
                ),
              _nav(
                index: indices.printer,
                label: loc.printer,
                icon: Icon(
                  Icons.print_rounded,
                  size: SidebarLayout.navIconSize,
                  color: selectedIndex == indices.printer ? _active : _inactive,
                ),
              ),
              if (StaffAccess.canManageSettings)
                _nav(
                  index: indices.settings,
                  label: loc.settings,
                  icon: Icon(
                    Icons.settings_outlined,
                    size: SidebarLayout.navIconSize,
                    color: selectedIndex == indices.settings
                        ? _active
                        : _inactive,
                  ),
                ),
              _nav(
                index: -1,
                label: loc.help_and_setup,
                selectedOverride: routes.helpSetup,
                icon: Icon(
                  Icons.support_outlined,
                  size: SidebarLayout.navIconSize,
                  color: routes.helpSetup ? _active : _inactive,
                ),
                onTapOverride: () async {
                  Modular.to.navigate(HomeMainRoutes.helpSetup);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nav({
    required int index,
    required String label,
    required Widget icon,
    bool? selectedOverride,
    Future<void> Function()? onTapOverride,
    Widget? trailing,
  }) {
    return SidebarNavItem(
      selectedIndex: selectedIndex,
      collapsed: collapsed,
      index: index,
      label: label,
      icon: icon,
      selectedOverride: selectedOverride,
      onTapOverride: onTapOverride,
      trailing: trailing,
    );
  }

  Widget _buildItemsSection(BuildContext context) {
    final isSelected = selectedIndex == indices.items;
    final leading = Assets.svg.items.svg(
      width: SidebarLayout.navIconSize,
      height: SidebarLayout.navIconSize,
      colorFilter: ColorFilter.mode(
        isSelected ? _active : _inactive,
        BlendMode.srcIn,
      ),
    );

    if (collapsed) {
      return _nav(index: indices.items, label: loc.items, icon: leading);
    }

    return SidebarExpansionNav(
      storageKey: 'items-sidebar-tile',
      initiallyExpanded: sidebarController.itemsExpanded,
      isSelected: isSelected,
      activeBackground: activeBackground,
      leading: leading,
      title: loc.items,
      onExpansionChanged: (expanded) {
        sidebarController.setItemsExpanded(expanded);
        onStateChange();
        if (expanded &&
            !currentPath.startsWith(HomeMainRoutes.items) &&
            !currentPath.startsWith(HomeMainRoutes.addItem)) {
          Modular.to.navigate(HomeMainRoutes.items);
        }
      },
      children: [
        SidebarChildNavItem(
          label: loc.item_list,
          selected: routes.itemList,
          targetRoute: HomeMainRoutes.items,
        ),
        if (StaffAccess.canShowAddMenuItemInShell)
          SidebarChildNavItem(
            label: loc.add_item,
            selected: routes.addItem,
            targetRoute: HomeMainRoutes.addItem,
          ),
        if (StaffAccess.canShowAddCategoryInShell)
          SidebarChildNavItem(
            label: loc.add_category,
            selected: currentPath.startsWith(HomeMainRoutes.category),
            targetRoute: HomeMainRoutes.category,
          ),
      ],
    );
  }

  Widget _buildPurchasesSection(BuildContext context) {
    final isSelected = selectedIndex == indices.purchases;
    final leading = Icon(
      Icons.shopping_bag_outlined,
      size: SidebarLayout.navIconSize,
      color: isSelected ? _active : _inactive,
    );

    if (collapsed) {
      return _nav(index: indices.purchases, label: 'Purchases', icon: leading);
    }

    return SidebarExpansionNav(
      storageKey: 'purchases-sidebar-tile',
      initiallyExpanded: sidebarController.purchasesExpanded,
      isSelected: isSelected,
      activeBackground: activeBackground,
      leading: leading,
      title: 'Purchases',
      onExpansionChanged: (expanded) {
        sidebarController.setPurchasesExpanded(expanded);
        onStateChange();
        if (expanded &&
            !currentPath.startsWith(HomeMainRoutes.purchaseOrders)) {
          Modular.to.navigate(HomeMainRoutes.purchaseOrders);
        }
      },
      children: [
        SidebarChildNavItem(
          label: loc.tab_purchase_orders,
          selected: routes.purchaseOrders,
          targetRoute: HomeMainRoutes.purchaseOrders,
        ),
      ],
    );
  }

  Widget _buildOrdersSection(BuildContext context) {
    final isSelected = selectedIndex == indices.orders;
    final leading = Icon(
      Icons.receipt_long_outlined,
      size: SidebarLayout.navIconSize,
      color: isSelected ? _active : _inactive,
    );

    if (collapsed) {
      return _nav(index: indices.orders, label: loc.orders, icon: leading);
    }

    return SidebarExpansionNav(
      storageKey: 'orders-sidebar-tile',
      initiallyExpanded: sidebarController.ordersExpanded,
      isSelected: isSelected,
      activeBackground: activeBackground,
      leading: leading,
      title: loc.orders,
      onExpansionChanged: (expanded) {
        sidebarController.setOrdersExpanded(expanded);
        onStateChange();
        if (expanded &&
            !currentPath.startsWith(HomeMainRoutes.closedOrders) &&
            !currentPath.startsWith(HomeMainRoutes.holdOrders) &&
            !currentPath.startsWith(HomeMainRoutes.deletedOrders) &&
            !currentPath.startsWith(HomeMainRoutes.stockSummary)) {
          Modular.to.navigate(HomeMainRoutes.closedOrders);
        }
      },
      children: [
        SidebarChildNavItem(
          label: loc.closedOrders,
          selected: routes.closedOrders,
          targetRoute: HomeMainRoutes.closedOrders,
        ),
        SidebarChildNavItem(
          label: loc.onHoldOrders,
          selected: routes.holdOrders,
          targetRoute: HomeMainRoutes.holdOrders,
        ),
        if (StaffAccess.canAccessDeletedOrders)
          SidebarChildNavItem(
            label: loc.deletedOrders,
            selected: routes.deletedOrders,
            targetRoute: HomeMainRoutes.deletedOrders,
          ),
        if (StaffAccess.canAccessStockSummary)
          SidebarChildNavItem(
            label: loc.stockSummary,
            selected: routes.stockSummary,
            targetRoute: HomeMainRoutes.stockSummary,
          ),
      ],
    );
  }

  Widget _buildReportsSection(BuildContext context) {
    final isSelected = selectedIndex == indices.reports;
    final leading = Assets.svg.reports.svg(
      width: SidebarLayout.navIconSize,
      height: SidebarLayout.navIconSize,
      colorFilter: ColorFilter.mode(
        isSelected ? _active : _inactive,
        BlendMode.srcIn,
      ),
    );

    if (collapsed) {
      return _nav(index: indices.reports, label: loc.reports, icon: leading);
    }

    return SidebarExpansionNav(
      storageKey: 'reports-sidebar-tile',
      initiallyExpanded: sidebarController.reportsExpanded,
      isSelected: isSelected,
      activeBackground: activeBackground,
      leading: leading,
      title: loc.reports,
      onExpansionChanged: (expanded) {
        sidebarController.setReportsExpanded(expanded);
        onStateChange();
        if (expanded &&
            !currentPath.startsWith(HomeMainRoutes.reports) &&
            !currentPath.startsWith(HomeMainRoutes.orderReport) &&
            !currentPath.startsWith(HomeMainRoutes.itemsReport) &&
            !currentPath.startsWith(HomeMainRoutes.storeSessionHistory)) {
          Modular.to.navigate(HomeMainRoutes.reports);
        }
      },
      children: [
        SidebarChildNavItem(
          label: loc.order_Reports,
          selected: routes.orderReport,
          targetRoute: HomeMainRoutes.orderReport,
        ),
        SidebarChildNavItem(
          label: loc.item_Reports,
          selected: routes.itemReport,
          targetRoute: HomeMainRoutes.itemsReport,
        ),
        if (StaffAccess.canViewStoreHistory)
          SidebarChildNavItem(
            label: loc.store_history_title,
            selected: routes.storeHistory,
            targetRoute: HomeMainRoutes.storeSessionHistory,
          ),
      ],
    );
  }
}
