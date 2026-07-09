import 'package:billkaro/app/modules/AddOrder/add_order_controller.dart';
import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Bottom sheet to review order items, then confirm Save or Bill.
class ConfirmOrderBottomSheet extends StatelessWidget {
  const ConfirmOrderBottomSheet({super.key, required this.action});

  final PosOrderAction action;

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AddOrderController>();
    final loc = AppLocalizations.of(context)!;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header row: No. | Dishes | Count | Price
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    'No.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Dishes',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: Text(
                    'Count',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Price',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // List of items
          Flexible(
            child: Obx(() {
              final entries = controller.itemQuantities.entries
                  .where((e) => (e.value) >= 1)
                  .toList();
              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      loc.add_items,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                );
              }
              return ListView.separated(
                physics: const BouncingScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final item = controller.items.firstWhereOrNull(
                    (i) => i.id == entry.key,
                  );
                  if (item == null) return const SizedBox.shrink();
                  final qty = entry.value;
                  final lineTotal = item.salePrice * qty;
                  return _ConfirmOrderRow(
                    index: index + 1,
                    item: item,
                    quantity: qty,
                    lineTotal: lineTotal,
                    remark: controller.itemRemarks[item.id] ?? '',
                    onRemark: () =>
                        controller.showItemRemarkDialog(item.id, item.itemName),
                    onIncrement: () =>
                        controller.incrementItemQuantity(item.id),
                    onDecrement: () =>
                        controller.decrementItemQuantity(item.id),
                  );
                },
              );
            }),
          ),
          const Divider(height: 1),
          // Bottom bar: Subtotal, GST, Total + Confirm
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 12 + MediaQuery.of(context).viewPadding.bottom,
            ),
            decoration: BoxDecoration(color: Colors.grey[100]),
            child: Obx(() {
              final subtotal = controller.subtotal.value;
              final gst = controller.totalTax.value;
              final discount = controller.appliedDiscountAmount();
              final total = controller.totalAmount.value;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        _TotalSummaryRow(
                          label: 'Subtotal',
                          value: '₹${subtotal.toStringAsFixed(2)}',
                        ),
                        _TotalSummaryRow(
                          label: 'Tax',
                          value: '₹${gst.toStringAsFixed(2)}',
                        ),
                        _TotalSummaryRow(
                          label: loc.discount,
                          value: discount > 0
                              ? '-₹${discount.toStringAsFixed(2)}'
                              : '₹0.00',
                        ),
                        const SizedBox(height: 4),
                        _TotalSummaryRow(
                          label: loc.total_amount,
                          value: '₹${total.toStringAsFixed(2)}',
                          strong: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      spacing: 10,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 120,
                          child: OutlinedButton(
                            onPressed: () {
                              Get.back();
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,
                          child: ElevatedButton(
                            onPressed: () {
                              Get.back();
                              controller.executePosAction(action);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.primary,
                              foregroundColor: AppColor.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _ConfirmOrderRow extends StatelessWidget {
  final int index;
  final ItemData item;
  final int quantity;
  final double lineTotal;
  final String remark;
  final VoidCallback onRemark;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ConfirmOrderRow({
    required this.index,
    required this.item,
    required this.quantity,
    required this.lineTotal,
    required this.remark,
    required this.onRemark,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          child: Text(
            '$index',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: item.itemImage.isNotEmpty
                    ? Image.network(
                        item.itemImage,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 40,
                          height: 40,
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                            size: 20,
                          ),
                        ),
                      )
                    : Container(
                        width: 40,
                        height: 40,
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                          size: 20,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.itemName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (remark.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          '📝 ${remark.trim()}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: AppColor.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Item remark',
          icon: Icon(
            remark.trim().isNotEmpty
                ? Icons.chat_bubble
                : Icons.chat_bubble_outline,
            size: 20,
            color: remark.trim().isNotEmpty ? AppColor.primary : Colors.grey,
          ),
          onPressed: onRemark,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        SizedBox(
          width: 100,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                InkWell(
                  onTap: onDecrement,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.remove,
                      size: 16,
                      color: AppColor.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$quantity',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: onIncrement,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColor.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 16,
                      color: AppColor.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 62,
          child: Text(
            '₹${lineTotal.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}

class _TotalSummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool strong;

  const _TotalSummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: strong ? 14 : 13,
                color: strong ? Colors.black87 : Colors.grey[700],
                fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 16 : 13,
              color: strong ? Colors.black87 : Colors.grey[800],
              fontWeight: strong ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
