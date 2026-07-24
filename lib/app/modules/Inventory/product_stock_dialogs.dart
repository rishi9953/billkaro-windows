import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

const _productStockReasons = ['Sale', 'Purchase', 'Damage', 'Refund', 'Other'];

Future<void> showAdjustProductStockDialog(
  InventoryController controller,
  ProductStockData item,
) async {
  final qtyCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final adjustmentType = 'STOCK_IN'.obs;
  final reason = 'Purchase'.obs;
  final currentStock = item.stockQuantity.obs;
  final quantityText = ''.obs;
  final saving = false.obs;

  double previewNewStock() {
    final qty = double.tryParse(quantityText.value.trim()) ?? 0;
    switch (adjustmentType.value) {
      case 'STOCK_IN':
        return currentStock.value + qty;
      case 'STOCK_OUT':
        return (currentStock.value - qty).clamp(0, double.infinity);
      case 'ADJUSTMENT':
        return qty < 0 ? 0 : qty;
      default:
        return currentStock.value;
    }
  }

  Color previewNewStockColor() {
    final next = previewNewStock();
    if (next > currentStock.value) return const Color(0xFF16A34A);
    if (next < currentStock.value) return const Color(0xFFDC2626);
    return const Color(0xFF374151);
  }

  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Adjust Stock',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        'Current Stock: ${_formatQty(currentStock.value)}',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Adjustment',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4B5563),
                ),
              ),
              const SizedBox(height: 8),
              Obx(
                () => Row(
                  children: [
                    Expanded(
                      child: _adjustTypeChip(
                        label: 'Stock In',
                        selected: adjustmentType.value == 'STOCK_IN',
                        selectedColor: const Color(0xFF16A34A),
                        onTap: () => adjustmentType.value = 'STOCK_IN',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _adjustTypeChip(
                        label: 'Stock Out',
                        selected: adjustmentType.value == 'STOCK_OUT',
                        selectedColor: const Color(0xFFDC2626),
                        onTap: () => adjustmentType.value = 'STOCK_OUT',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _adjustTypeChip(
                        label: 'Adjustment',
                        selected: adjustmentType.value == 'ADJUSTMENT',
                        selectedColor: AppColor.primary,
                        onTap: () => adjustmentType.value = 'ADJUSTMENT',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                adjustmentType.value;
                final hasQty = quantityText.value.trim().isNotEmpty &&
                    double.tryParse(quantityText.value.trim()) != null;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 56,
                        child: TextField(
                          controller: qtyCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          onChanged: (v) => quantityText.value = v,
                          decoration: InputDecoration(
                            labelText: 'Quantity',
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: AppColor.primary,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (hasQty) ...[
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 110,
                        height: 56,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'New Stock',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.w500,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatQty(previewNewStock()),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: previewNewStockColor(),
                                  height: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                );
              }),
              const SizedBox(height: 14),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: reason.value,
                  decoration: InputDecoration(
                    labelText: 'Reason',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  items: _productStockReasons
                      .map(
                        (r) => DropdownMenuItem(value: r, child: Text(r)),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) reason.value = v;
                  },
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColor.primary,
                        side: BorderSide(color: AppColor.primary),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: saving.value
                            ? null
                            : () async {
                                final qty = double.tryParse(
                                  qtyCtrl.text.trim(),
                                );
                                if (qty == null || qty < 0) {
                                  showError(
                                    description: 'Enter a valid quantity',
                                  );
                                  return;
                                }
                                if (adjustmentType.value != 'ADJUSTMENT' &&
                                    qty <= 0) {
                                  showError(
                                    description:
                                        'Quantity must be greater than 0',
                                  );
                                  return;
                                }
                                saving.value = true;
                                final ok = await controller.adjustProductStock(
                                  itemId: item.id,
                                  adjustmentType: adjustmentType.value,
                                  quantity: qty,
                                  reason: reason.value,
                                  notes: notesCtrl.text.trim(),
                                );
                                saving.value = false;
                                if (ok) {
                                  Get.back();
                                  showSuccess(
                                    description:
                                        'Stock updated to ${_formatQty(previewNewStock())}',
                                  );
                                } else {
                                  showError(
                                    description: 'Failed to update stock',
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColor.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: saving.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save'),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: false,
  );
}

Future<void> showProductStockMovementsDialog(
  InventoryController controller,
  ProductStockData item,
) async {
  final filter = 'ALL'.obs;
  final loading = true.obs;
  final movements = <ProductStockMovementData>[].obs;
  final currentStock = item.stockQuantity.obs;

  Future<void> load() async {
    loading.value = true;
    movements.value = await controller.loadProductStockMovements(
      itemId: item.id,
      type: filter.value,
    );
    final match = controller.productStock.firstWhereOrNull(
      (e) => e.id == item.id,
    );
    if (match != null) currentStock.value = match.stockQuantity;
    loading.value = false;
  }

  load();

  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 640),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Stock Movements',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF374151),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Get.back(),
                    icon: const Icon(Icons.close, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(
                () => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.itemName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      Text(
                        'Current Stock: ${_formatQty(currentStock.value)}',
                        style: TextStyle(
                          color: AppColor.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Obx(
                () => Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _movementFilterChip(
                      'All',
                      'ALL',
                      filter.value,
                      () {
                        filter.value = 'ALL';
                        load();
                      },
                    ),
                    _movementFilterChip(
                      'Stock In',
                      'STOCK_IN',
                      filter.value,
                      () {
                        filter.value = 'STOCK_IN';
                        load();
                      },
                    ),
                    _movementFilterChip(
                      'Stock Out',
                      'STOCK_OUT',
                      filter.value,
                      () {
                        filter.value = 'STOCK_OUT';
                        load();
                      },
                    ),
                    _movementFilterChip(
                      'Adjustment',
                      'ADJUSTMENT',
                      filter.value,
                      () {
                        filter.value = 'ADJUSTMENT';
                        load();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Obx(() {
                  if (loading.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (movements.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.history,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No data available',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: movements.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = movements[i];
                      final date = m.createdAt == null
                          ? ''
                          : DateFormat(
                              'dd MMM yyyy, hh:mm a',
                            ).format(m.createdAt!.toLocal());
                      final isIn = m.type == 'STOCK_IN';
                      final isOut = m.type == 'STOCK_OUT';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isIn
                              ? const Color(0xFFDCFCE7)
                              : isOut
                              ? const Color(0xFFFEE2E2)
                              : const Color(0xFFDBEAFE),
                          child: Icon(
                            isIn
                                ? Icons.arrow_downward
                                : isOut
                                ? Icons.arrow_upward
                                : Icons.tune,
                            size: 18,
                            color: isIn
                                ? const Color(0xFF16A34A)
                                : isOut
                                ? const Color(0xFFDC2626)
                                : AppColor.primary,
                          ),
                        ),
                        title: Text(
                          '${m.typeLabel} · ${m.reason}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          [
                            date,
                            if (m.notes != null && m.notes!.isNotEmpty)
                              m.notes!,
                          ].where((e) => e.isNotEmpty).join(' · '),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${isOut ? '-' : isIn ? '+' : ''}${_formatQty(m.quantity)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: isIn
                                    ? const Color(0xFF16A34A)
                                    : isOut
                                    ? const Color(0xFFDC2626)
                                    : const Color(0xFF374151),
                              ),
                            ),
                            Text(
                              '${_formatQty(m.stockBefore)} → ${_formatQty(m.stockAfter)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _adjustTypeChip({
  required String label,
  required bool selected,
  required Color selectedColor,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(10),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: selected ? selectedColor.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? selectedColor : Colors.grey.shade300,
          width: selected ? 1.5 : 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (selected) ...[
            Icon(Icons.check, size: 16, color: selectedColor),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? selectedColor : const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _movementFilterChip(
  String label,
  String value,
  String selected,
  VoidCallback onTap,
) {
  final isSelected = selected == value;
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(20),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColor.primary.withValues(alpha: 0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColor.primary : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            Icon(Icons.check, size: 14, color: AppColor.primary),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? AppColor.primary : const Color(0xFF111827),
            ),
          ),
        ],
      ),
    ),
  );
}

String _formatQty(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toStringAsFixed(2);
}

Color? parseHexColor(String hex) {
  if (hex.isEmpty) return null;
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  return Color(int.parse(value, radix: 16));
}
