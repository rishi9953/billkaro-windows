import 'package:billkaro/app/modules/Home/home_screen_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/app_shell_sidebar_controller.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_layout.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_nav_indices.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_navigation.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_route_selection.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_theme.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_header.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_nav_item.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_notification_icon.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_scrollable_nav.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/widgets/sidebar_subscription_card.dart';
import 'package:billkaro/app/modules/Theme/theme_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_modular/flutter_modular.dart';

export 'sidebar_layout.dart' show SidebarLayout;

class AppShellSidebar extends StatefulWidget {
  const AppShellSidebar({
    super.key,
    required this.selectedIndex,
    required this.collapsed,
    required this.onToggleCollapsed,
  });

  final int selectedIndex;
  final bool collapsed;
  final VoidCallback onToggleCollapsed;

  static const double widthExpanded = SidebarLayout.widthExpanded;
  static const double widthCollapsed = SidebarLayout.widthCollapsed;
  static const double navIconSize = SidebarLayout.navIconSize;

  @override
  State<AppShellSidebar> createState() => _AppShellSidebarState();
}

class _AppShellSidebarState extends State<AppShellSidebar> {
  late final AppShellSidebarController _sidebarController;

  @override
  void initState() {
    super.initState();
    _sidebarController = Get.isRegistered<AppShellSidebarController>()
        ? Get.find<AppShellSidebarController>()
        : Get.put(AppShellSidebarController());
    _syncExpansion();
  }

  @override
  void didUpdateWidget(covariant AppShellSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncExpansion();
  }

  void _syncExpansion() {
    _sidebarController.syncExpansionFromPath(
      Modular.to.path,
      collapsed: widget.collapsed,
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final hasThemeController = Get.isRegistered<ThemeController>();

    if (Get.isRegistered<HomeScreenController>()) {
      return Obx(() {
        if (hasThemeController) {
          Get.find<ThemeController>().themeColor.value;
        }
        final hc = Get.find<HomeScreenController>();
        hc.isKOT.value;
        hc.selectedOutlet.value;
        return _buildShell(
          loc,
          kotEnabled:
              hc.isKOT.value && HomeMainRoutes.outletIsCafeOrRestaurant(),
          hasSeating: HomeMainRoutes.outletShowsTables(),
        );
      });
    }

    if (hasThemeController) {
      return Obx(() {
        Get.find<ThemeController>().themeColor.value;
        return _buildShell(
          loc,
          kotEnabled: HomeMainRoutes.kotFeatureEnabled(),
          hasSeating: HomeMainRoutes.outletShowsTables(),
        );
      });
    }

    return _buildShell(
      loc,
      kotEnabled: HomeMainRoutes.kotFeatureEnabled(),
      hasSeating: HomeMainRoutes.outletShowsTables(),
    );
  }

  Widget _buildShell(
    AppLocalizations loc, {
    required bool kotEnabled,
    required bool hasSeating,
  }) {
    final width = widget.collapsed
        ? AppShellSidebar.widthCollapsed
        : AppShellSidebar.widthExpanded;
    final currentPath = Modular.to.path;
    final routes = SidebarRouteSelection.fromPath(currentPath);
    final indices = SidebarNavIndices.compute(
      kotEnabled: kotEnabled,
      hasSeating: hasSeating,
    );
    final primary = AppColor.primary;
    final activeBackground = primary.withOpacity(0.22);

    return Container(
      width: width,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.alphaBlend(
              primary.withOpacity(0.24),
              const Color(0xFF0F172A),
            ),
            Color.alphaBlend(
              primary.withOpacity(0.12),
              const Color(0xFF070B17),
            ),
          ],
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(2, 0)),
        ],
      ),
      child: Column(
        children: [
          SidebarHeader(
            collapsed: widget.collapsed,
            onToggleCollapsed: widget.onToggleCollapsed,
            loc: loc,
          ),
          Expanded(
            child: SidebarScrollableNav(
              loc: loc,
              selectedIndex: widget.selectedIndex,
              collapsed: widget.collapsed,
              currentPath: currentPath,
              kotEnabled: kotEnabled,
              hasSeating: hasSeating,
              indices: indices,
              routes: routes,
              sidebarController: _sidebarController,
              onStateChange: () => setState(() {}),
              scrollController: _sidebarController.scrollController,
              activeBackground: activeBackground,
            ),
          ),
          const Divider(height: 1, color: SidebarColors.divider),
          SidebarNavItem(
            selectedIndex: widget.selectedIndex,
            collapsed: widget.collapsed,
            index: indices.profile,
            label: loc.profile,
            icon: Icon(
              Icons.person_rounded,
              size: AppShellSidebar.navIconSize,
              color: widget.selectedIndex == indices.profile
                  ? SidebarColors.textActive
                  : SidebarColors.iconInactive,
            ),
          ),
          SidebarNavItem(
            selectedIndex: widget.selectedIndex,
            collapsed: widget.collapsed,
            index: -1,
            label: loc.notifications,
            selectedOverride: routes.notifications,
            onTapOverride: () => SidebarNavigation.navigateFromSidebar(
              context,
              HomeMainRoutes.notifications,
            ),
            icon: SidebarNotificationIcon(
              isSelected: routes.notifications,
              collapsed: widget.collapsed,
            ),
          ),
          SidebarNavItem(
            selectedIndex: widget.selectedIndex,
            collapsed: widget.collapsed,
            index: indices.logout,
            label: loc.logout,
            isSignOut: true,
            icon: Icon(
              Icons.logout_rounded,
              size: AppShellSidebar.navIconSize,
              color: SidebarColors.iconInactive,
            ),
          ),
          SidebarSubscriptionCard(collapsed: widget.collapsed, loc: loc),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
