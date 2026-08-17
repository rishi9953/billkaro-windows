import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_ui_actions.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';

class PurchaseOrderTabBar extends StatelessWidget {
  const PurchaseOrderTabBar({
    super.key,
    required this.controller,
    required this.loc,
  });

  final PurchaseOrderController controller;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tabIds = controller.tabIds;
      final activeIndex = controller.activeTabIndex.value;

      return Container(
        height: 40,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColor.primary,
          border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
        ),
        child: Row(
          children: [
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < tabIds.length; index++)
                      _TabChip(
                        label: '${loc.tab_purchase_orders} ${index + 1}',
                        isActive: activeIndex == index,
                        canClose: tabIds.length > 1,
                        onTap: () => controller.selectTab(index),
                        onClose: () => controller.requestCloseTab(index, loc),
                      ),
                    if (StaffAccess.canAdjustStock)
                      IconButton(
                        tooltip: loc.create_po,
                        onPressed: () {
                          if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) {
                            return;
                          }
                          controller.addTab();
                        },
                        icon: const Icon(Icons.add, size: 18),
                        visualDensity: VisualDensity.compact,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
      );
    });
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.isActive,
    required this.canClose,
    required this.onTap,
    required this.onClose,
  });

  final String label;
  final bool isActive;
  final bool canClose;
  final VoidCallback onTap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.grey.shade200,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
              if (canClose) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: Icon(
                      Icons.close,
                      size: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
