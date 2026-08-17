import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_dialogs.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_drawer_scope.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';

extension PurchaseOrderUiActions on PurchaseOrderController {
  void openCreateDrawer() {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
    showCreatePurchaseOrderDialog(
      this,
      drawerTopInset: PurchaseOrderController.drawerTopInset,
      drawerTabId: currentTabId,
    );
  }

  void openEditDrawer(PurchaseOrderData order) {
    if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
    showEditPurchaseOrderDialog(
      this,
      order,
      drawerTopInset: PurchaseOrderController.drawerTopInset,
      drawerTabId: currentTabId,
    );
  }

  void openDetails(PurchaseOrderData order) {
    showPurchaseOrderDetailDialog(this, order);
  }

  Future<void> requestCloseTab(int index, AppLocalizations loc) async {
    if (tabIds.length == 1) return;

    final tabNumber = index + 1;
    final shouldClose = await showPoAwareDialog<bool>(
      builder: (dialogContext, close) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Text(loc.confirm_delete),
          content: Text(
            'Close Purchase Orders tab $tabNumber? Any unsaved changes in this tab will be lost.',
          ),
          actions: [
            TextButton(
              onPressed: () => close(false),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () => close(true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text(loc.close),
            ),
          ],
        );
      },
    );

    if (shouldClose == true) {
      closeTab(index);
    }
  }
}
