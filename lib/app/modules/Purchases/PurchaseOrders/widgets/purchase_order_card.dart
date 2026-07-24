import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_pdf_service.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_ui_actions.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';

class PurchaseOrderCard extends StatelessWidget {
  const PurchaseOrderCard({
    super.key,
    required this.controller,
    required this.po,
    required this.loc,
  });

  final PurchaseOrderController controller;
  final PurchaseOrderData po;
  final AppLocalizations loc;

  @override
  Widget build(BuildContext context) {
    final canReceive = po.status == 'PENDING' || po.status == 'DRAFT';
    final canCancel = canReceive;

    return InkWell(
      onTap: () => controller.openDetails(po),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: PurchaseOrderController.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  po.orderNumber,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(width: 10),
                _StatusBadge(
                  label: po.status,
                  isWarning: po.status == 'PENDING',
                ),
                const Spacer(),
                Text(
                  '₹${controller.formatAmount(po.totalAmount)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: PurchaseOrderController.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              po.version > 0 && po.updatedAt.isNotEmpty
                  ? loc.purchase_order_supplier_updated_date(
                      po.supplierName,
                      controller.formatDate(po.updatedAt),
                    )
                  : loc.purchase_order_supplier_created_date(
                      po.supplierName,
                      controller.formatDate(po.createdAt),
                    ),
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            if (po.expectedDate?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                '${loc.delivery_date}: ${controller.formatDate(po.expectedDate!)}',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
            if (po.items.isNotEmpty) ...[
              const SizedBox(height: 10),
              ...po.items
                  .take(3)
                  .map(
                    (line) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '${loc.purchase_order_line_item(line.rawMaterialName, '${line.quantity}', line.unit, '${line.unitPrice}')}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
              if (po.items.length > 3)
                Text(
                  '+ ${po.items.length - 3} more...',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canCancel)
                  TextButton.icon(
                    onPressed: () => controller.openEditDrawer(po),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(loc.edit_po),
                  ),
                TextButton(
                  onPressed: () => controller.openDetails(po),
                  child: Text(loc.view_details),
                ),
                TextButton.icon(
                  onPressed: () => PurchaseOrderPdfService.printOrPreview(
                    po,
                    supplierFallback: controller.suppliers.firstWhereOrNull(
                      (s) => s.id == po.supplierId,
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(loc.print_po),
                ),
                if (canCancel)
                  TextButton(
                    onPressed: () => controller.confirmCancelPo(
                      po.orderNumber,
                      () => controller.cancelOrder(po.id),
                      loc,
                    ),
                    child: Text(
                      loc.cancel_po,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (canReceive)
                  ElevatedButton.icon(
                    onPressed: () => controller.receiveOrder(po.id),
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: Text(loc.mark_received),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isWarning});

  final String label;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? PurchaseOrderController.accent : Colors.green;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isWarning ? color.withOpacity(0.8) : Colors.green.shade700,
        ),
      ),
    );
  }
}
