import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/modules/HomeMain/home_main_routes.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_drawer_scope.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:flutter_modular/flutter_modular.dart';

abstract final class SidebarNavigation {
  static bool canNavigateToRoute(String route) =>
      StaffAccess.canAccessRoute(route);

  static Future<bool> navigateFromSidebar(
    BuildContext context,
    String targetRoute, {
    Future<void> Function()? onBeforeNavigate,
    VoidCallback? onAfterNavigate,
    bool staffFromSidebar = false,
  }) async {
    final navLoc = AppLocalizations.of(context)!;
    if (!canNavigateToRoute(targetRoute)) {
      showError(description: navLoc.no_permission_section);
      return false;
    }

    final isLeavingCreateOrder =
        Modular.to.path.startsWith(HomeMainRoutes.createOrder) &&
        !targetRoute.startsWith(HomeMainRoutes.createOrder);
    if (isLeavingCreateOrder) {
      final shouldLeave = await _confirmLeaveCreateOrder(context, navLoc);
      if (!shouldLeave) return false;
    }

    final isLeavingPurchaseOrders =
        Modular.to.path.startsWith(HomeMainRoutes.purchaseOrders) &&
        !targetRoute.startsWith(HomeMainRoutes.purchaseOrders);
    if (isLeavingPurchaseOrders) {
      final shouldLeave = await confirmLeavePurchaseOrdersScreen(
        context,
        navLoc,
      );
      if (!shouldLeave) return false;
    }

    await onBeforeNavigate?.call();

    dismissAllAppLoader();

    if (staffFromSidebar) {
      Modular.to.navigate('${HomeMainRoutes.staff}?fromSidebar=true');
    } else {
      Modular.to.navigate(targetRoute);
    }

    onAfterNavigate?.call();
    return true;
  }

  static Future<bool> _confirmLeaveCreateOrder(
    BuildContext context,
    AppLocalizations loc,
  ) async {
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
          title: Text(loc.discard_order_title),
          content: Text(loc.discard_order_message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.stay),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(loc.leave),
            ),
          ],
        );
      },
    );
    return shouldLeave ?? false;
  }
}
