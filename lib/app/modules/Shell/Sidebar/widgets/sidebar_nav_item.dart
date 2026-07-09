import 'package:billkaro/app/Widgets/logout_dialog.dart';
import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_navigation.dart';
import 'package:billkaro/app/modules/Shell/Sidebar/sidebar_theme.dart';
import 'package:billkaro/app/modules/Tables/table_controller.dart';
import 'package:billkaro/config/config.dart';

class SidebarNavItem extends StatelessWidget {
  const SidebarNavItem({
    super.key,
    required this.selectedIndex,
    required this.collapsed,
    required this.index,
    required this.label,
    required this.icon,
    this.isSignOut = false,
    this.selectedOverride,
    this.onTapOverride,
    this.trailing,
  });

  final int selectedIndex;
  final bool collapsed;
  final int index;
  final String label;
  final Widget icon;
  final bool isSignOut;
  final bool? selectedOverride;
  final Future<void> Function()? onTapOverride;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isSelected =
        selectedOverride ?? (selectedIndex == index && !isSignOut);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2.5),
      child: Material(
        color: isSelected
            ? AppColor.primary.withOpacity(0.22)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _onTap(context),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: collapsed ? 10 : 12,
              vertical: 9.5,
            ),
            child: Row(
              children: [
                if (isSelected && !collapsed)
                  Container(
                    width: 3,
                    height: 18,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                SizedBox(width: 24, height: 24, child: Center(child: icon)),
                if (!collapsed) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSignOut
                            ? SidebarColors.textInactive
                            : (isSelected
                                  ? SidebarColors.textActive
                                  : SidebarColors.textInactive),
                        fontSize: 13.5,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        letterSpacing: 0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context) async {
    if (isSignOut) {
      showLogoutDialog(context, AppLocalizations.of(context)!);
      return;
    }

    if (onTapOverride != null) {
      await onTapOverride!();
      return;
    }

    final targetRoute = HomeMainRoutes.routeForIndex(index);
    final navLoc = AppLocalizations.of(context)!;
    if (!SidebarNavigation.canNavigateToRoute(targetRoute)) {
      showError(description: navLoc.no_permission_section);
      return;
    }

    await SidebarNavigation.navigateFromSidebar(
      context,
      targetRoute,
      onBeforeNavigate: () async {
        if (index == 1 && Get.isRegistered<AddOrderController>()) {
          Get.delete<AddOrderController>();
        }
      },
      onAfterNavigate: () {
        if (HomeMainRoutes.outletShowsTables() && index == 2) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.isRegistered<TableController>()) {
              Get.find<TableController>().refresh();
            }
          });
        }
      },
      staffFromSidebar: targetRoute == HomeMainRoutes.staff,
    );
  }
}
