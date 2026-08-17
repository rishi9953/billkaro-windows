import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_controller.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_pdf_service.dart';
import 'package:billkaro/app/modules/Purchases/PurchaseOrders/purchase_order_ui_actions.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';

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

  static const _radius = 14.0;
  static const _previewLimit = 3;

  bool get _canReceive => po.status == 'PENDING' || po.status == 'DRAFT';
  bool get _canMutate => StaffAccess.canAdjustStock;

  Color get _statusColor => _PoStatusStyle.colorOf(po.status);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.openDetails(po),
        borderRadius: BorderRadius.circular(_radius),
        child: Ink(
          decoration: BoxDecoration(
            color: PurchaseOrderController.cardBg,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(width: 4, color: _statusColor),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Header(
                            orderNumber: po.orderNumber,
                            amount: controller.formatAmount(po.totalAmount),
                            status: po.status,
                            statusColor: _statusColor,
                          ),
                          const SizedBox(height: 10),
                          _MetaRow(
                            supplierName: po.supplierName,
                            dateLabel: _dateLabel(),
                            itemCountLabel: loc.order_items_count(po.items.length),
                            deliveryLabel: po.expectedDate?.isNotEmpty == true
                                ? '${loc.delivery_date}: ${controller.formatDate(po.expectedDate!)}'
                                : null,
                          ),
                          if (po.items.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _ItemPreview(
                              lines: po.items,
                              limit: _previewLimit,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Divider(height: 1, color: Colors.grey.shade200),
                          const SizedBox(height: 8),
                          _Actions(
                            loc: loc,
                            canEdit: _canReceive && _canMutate,
                            canCancel: _canReceive && _canMutate,
                            canReceive: _canReceive && _canMutate,
                            onEdit: () => controller.openEditDrawer(po),
                            onDetails: () => controller.openDetails(po),
                            onPrint: () => PurchaseOrderPdfService.printOrPreview(
                              po,
                              supplierFallback:
                                  controller.suppliers.firstWhereOrNull(
                                (s) => s.id == po.supplierId,
                              ),
                            ),
                            onCancel: () => controller.confirmCancelPo(
                              po.orderNumber,
                              () => controller.cancelOrder(po.id),
                              loc,
                            ),
                            onReceive: () => controller.receiveOrder(po.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _dateLabel() {
    final isUpdated = po.version > 0 && po.updatedAt.isNotEmpty;
    return controller.formatDate(isUpdated ? po.updatedAt : po.createdAt);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.orderNumber,
    required this.amount,
    required this.status,
    required this.statusColor,
  });

  final String orderNumber;
  final String amount;
  final String status;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            size: 20,
            color: statusColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: -0.2,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(label: status, color: statusColor),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '₹$amount',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: -0.3,
                  color: PurchaseOrderController.accent,
                ),
              ),
            ],
          ),
        ),
        Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey.shade400,
          size: 22,
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.supplierName,
    required this.dateLabel,
    required this.itemCountLabel,
    this.deliveryLabel,
  });

  final String supplierName;
  final String dateLabel;
  final String itemCountLabel;
  final String? deliveryLabel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        if (supplierName.trim().isNotEmpty)
          _MetaChip(
            icon: Icons.storefront_outlined,
            label: supplierName,
          ),
        _MetaChip(
          icon: Icons.event_outlined,
          label: dateLabel,
        ),
        _MetaChip(
          icon: Icons.inventory_2_outlined,
          label: itemCountLabel,
        ),
        if (deliveryLabel != null)
          _MetaChip(
            icon: Icons.local_shipping_outlined,
            label: deliveryLabel!,
          ),
      ],
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemPreview extends StatelessWidget {
  const _ItemPreview({
    required this.lines,
    required this.limit,
  });

  final List<PurchaseOrderLineData> lines;
  final int limit;

  @override
  Widget build(BuildContext context) {
    final visible = lines.take(limit).toList();
    final remaining = lines.length - visible.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFD),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < visible.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            _LineRow(line: visible[i]),
          ],
          if (remaining > 0) ...[
            const SizedBox(height: 6),
            Text(
              '+ $remaining more...',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});

  final PurchaseOrderLineData line;

  @override
  Widget build(BuildContext context) {
    final qty = line.quantity == line.quantity.roundToDouble()
        ? '${line.quantity.round()}'
        : '${line.quantity}';
    final price = line.unitPrice == line.unitPrice.roundToDouble()
        ? '${line.unitPrice.round()}'
        : line.unitPrice.toStringAsFixed(2);

    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: PurchaseOrderController.accent.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            line.rawMaterialName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$qty ${line.unit}',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '₹$price',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.loc,
    required this.canEdit,
    required this.canCancel,
    required this.canReceive,
    required this.onEdit,
    required this.onDetails,
    required this.onPrint,
    required this.onCancel,
    required this.onReceive,
  });

  final AppLocalizations loc;
  final bool canEdit;
  final bool canCancel;
  final bool canReceive;
  final VoidCallback onEdit;
  final VoidCallback onDetails;
  final VoidCallback onPrint;
  final VoidCallback onCancel;
  final VoidCallback onReceive;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      alignment: WrapAlignment.spaceBetween,
      children: [
        Wrap(
          spacing: 2,
          runSpacing: 2,
          children: [
            if (canEdit)
              _ActionChip(
                icon: Icons.edit_outlined,
                label: loc.edit_po,
                onTap: onEdit,
              ),
            _ActionChip(
              icon: Icons.visibility_outlined,
              label: loc.view_details,
              onTap: onDetails,
            ),
            _ActionChip(
              icon: Icons.picture_as_pdf_outlined,
              label: loc.print_po,
              onTap: onPrint,
            ),
            if (canCancel)
              _ActionChip(
                icon: Icons.cancel_outlined,
                label: loc.cancel_po,
                onTap: onCancel,
                foreground: Colors.red.shade700,
              ),
          ],
        ),
        if (canReceive)
          FilledButton.icon(
            onPressed: onReceive,
            icon: const Icon(Icons.check_circle_outline, size: 17),
            label: Text(loc.mark_received),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.foreground,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? foreground;

  @override
  Widget build(BuildContext context) {
    final color = foreground ?? Colors.grey.shade700;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 16, color: color),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          visualDensity: VisualDensity.compact,
          foregroundColor: color,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: color,
        ),
      ),
    );
  }
}

class _PoStatusStyle {
  static Color colorOf(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return PurchaseOrderController.accent;
      case 'DRAFT':
        return Colors.blueGrey.shade600;
      case 'RECEIVED':
      case 'COMPLETED':
        return Colors.green.shade700;
      case 'CANCELLED':
      case 'CANCELED':
        return Colors.red.shade600;
      case 'PARTIAL':
      case 'PARTIALLY_RECEIVED':
        return Colors.indigo.shade600;
      default:
        return Colors.grey.shade600;
    }
  }
}
