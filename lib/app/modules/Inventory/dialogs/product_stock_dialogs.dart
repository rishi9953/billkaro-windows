import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/modules/Inventory/dialogs/inventory_dialogs.dart';
import 'package:billkaro/app/modules/Inventory/dialogs/searchable_category_dropdown.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/staff_access.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:intl/intl.dart';

export 'searchable_category_dropdown.dart';

const _productStockReasons = ['Sale', 'Purchase', 'Damage', 'Refund', 'Other'];

const _productStockUoms = [
  ('KG', 'KG'),
  ('GRAM', 'GRAM'),
  ('LITER', 'LITER'),
  ('ML', 'ML'),
  ('PIECE', 'PIECE'),
  ('PACKET', 'PACKET'),
  ('BOX', 'BOX'),
  ('DOZEN', 'DOZEN'),
  ('BOTTLE', 'BOTTLE'),
  ('NOS', 'Nos'),
];

Future<void> showAddProductStockDrawer(InventoryController controller) async {
  if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
  if (controller.menuItems.isEmpty) {
    await controller.loadMenuItems();
  }
  if (controller.menuItems.isEmpty) {
    Get.snackbar(
      'No menu items',
      'Create a menu item first, then Add Item Stock here.',
      snackPosition: SnackPosition.BOTTOM,
    );
    return;
  }
  if (controller.suppliers.isEmpty) {
    await controller.loadSuppliers();
  }
  if (controller.categories.isEmpty) {
    await controller.loadMenuCategories();
  }

  final formKey = GlobalKey<FormState>();
  final qtyCtrl = TextEditingController();
  final rateCtrl = TextEditingController();
  final amountCtrl = TextEditingController(text: '0.00');
  final taxCtrl = TextEditingController(text: '0');
  final totalCtrl = TextEditingController(text: '0.00');
  final skuCtrl = TextEditingController();
  final barcodeCtrl = TextEditingController();
  String? selectedItemId;
  String? selectedSupplierId;
  String? selectedCategory;
  var uom = 'NOS';
  final saving = false.obs;

  final activeSuppliers = controller.suppliers
      .where((s) => s.isActive)
      .toList();
  final categoryOptions = controller.productStockCategories;

  void recalc() {
    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
    final taxPct = double.tryParse(taxCtrl.text.trim()) ?? 0;
    final amount = qty * rate;
    final total = amount + (amount * taxPct / 100);
    amountCtrl.text = amount.toStringAsFixed(2);
    totalCtrl.text = total.toStringAsFixed(2);
  }

  void populateItemDetails(String? itemId, VoidCallback refresh) {
    selectedItemId = itemId;
    if (itemId == null || itemId.isEmpty) {
      skuCtrl.clear();
      barcodeCtrl.clear();
      rateCtrl.clear();
      taxCtrl.text = '0';
      selectedCategory = null;
      recalc();
      refresh();
      return;
    }

    final item = controller.menuItems.firstWhereOrNull((e) => e.id == itemId);
    if (item == null) return;

    skuCtrl.text = item.sku;
    barcodeCtrl.text = item.barcode;
    final rate = item.costPrice > 0 ? item.costPrice : item.salePrice;
    rateCtrl.text = rate.toStringAsFixed(rate == rate.roundToDouble() ? 0 : 2);
    taxCtrl.text = item.gst.toString();
    selectedCategory = item.category.trim().isEmpty
        ? null
        : item.category.trim();
    recalc();
    refresh();
  }

  InputDecoration deco(String label, {bool readOnly = false, String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      filled: readOnly,
      fillColor: readOnly ? const Color(0xFFF3F4F6) : null,
      border: const OutlineInputBorder(),
    );
  }

  await showInventoryEndDrawer(
    title: 'Add Item Stock',
    width: 480,
    body: StatefulBuilder(
      builder: (context, setDrawerState) {
        return Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SearchableItemDropdown(
                items: {
                  for (final item in controller.menuItems)
                    item.id: item.itemName,
                },
                value: selectedItemId,
                decoration: deco('Item name *'),
                onChanged: (v) =>
                    populateItemDetails(v, () => setDrawerState(() {})),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Select an item' : null,
              ),
              const SizedBox(height: 12),
              SearchableCategoryDropdown(
                categories: categoryOptions,
                value: selectedCategory,
                label: 'Category',
                decoration: deco('Category'),
                onChanged: (v) {
                  setDrawerState(() {
                    selectedCategory = (v == null || v.isEmpty) ? null : v;
                  });
                },
              ),
              const SizedBox(height: 12),
              AppDropdownFormField2<String>(
                value: selectedSupplierId,
                isExpanded: true,
                decoration: deco('Supplier (optional)'),
                items: activeSuppliers
                    .map((s) => DropdownItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => selectedSupplierId = v,
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: deco('Quantity *'),
                      onChanged: (_) => recalc(),
                      validator: (v) {
                        final qty = double.tryParse((v ?? '').trim());
                        if (qty == null || qty <= 0) return 'Enter quantity';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdownFormField2<String>(
                      value: uom,
                      isExpanded: true,
                      decoration: deco('UOM'),
                      items: _productStockUoms
                          .map(
                            (e) => DropdownItem(value: e.$1, child: Text(e.$2)),
                          )
                          .toList(),
                      onChanged: (v) => uom = v ?? 'NOS',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: deco('Rate *', prefix: '₹ '),
                onChanged: (_) => recalc(),
                validator: (v) {
                  final rate = double.tryParse((v ?? '').trim());
                  if (rate == null || rate < 0) return 'Enter rate';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                readOnly: true,
                decoration: deco('Amount', readOnly: true, prefix: '₹ '),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: taxCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: deco('Tax (%)'),
                onChanged: (_) => recalc(),
                validator: (v) {
                  final tax = double.tryParse((v ?? '').trim());
                  if (tax == null || tax < 0) return 'Enter tax %';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: totalCtrl,
                readOnly: true,
                decoration: deco('Total', readOnly: true, prefix: '₹ '),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: skuCtrl,
                decoration: deco('SKU (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: barcodeCtrl,
                keyboardType: TextInputType.text,
                decoration: deco('Barcode (optional)'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
    footerActions: [
      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
      Obx(
        () => ElevatedButton(
          onPressed: saving.value
              ? null
              : () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final itemId = selectedItemId;
                  if (itemId == null || itemId.isEmpty) return;
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
                  final taxPct = double.tryParse(taxCtrl.text.trim()) ?? 0;
                  final amount = qty * rate;
                  final total = amount + (amount * taxPct / 100);
                  final uomLabel = _productStockUoms
                      .firstWhere((e) => e.$1 == uom, orElse: () => (uom, uom))
                      .$2;
                  final sku = skuCtrl.text.trim();
                  final barcode = barcodeCtrl.text.trim();
                  final category = selectedCategory?.trim() ?? '';
                  final supplierName = activeSuppliers
                      .where((s) => s.id == selectedSupplierId)
                      .map((s) => s.name)
                      .firstOrNull;
                  saving.value = true;
                  final ok = await controller.adjustProductStock(
                    itemId: itemId,
                    adjustmentType: 'STOCK_IN',
                    quantity: qty,
                    reason: 'Purchase',
                    costPrice: rate,
                    sku: sku.isEmpty ? null : sku,
                    barcode: barcode.isEmpty ? null : barcode,
                    taxPercent: taxPct,
                    category: category.isEmpty ? null : category,
                    supplierId: selectedSupplierId,
                    notes:
                        'UOM: $uomLabel | Rate: ₹${rate.toStringAsFixed(2)} | '
                        'Amount: ₹${amount.toStringAsFixed(2)} | '
                        'Tax: ${taxPct.toStringAsFixed(2)}% | '
                        'Total: ₹${total.toStringAsFixed(2)}'
                        '${category.isEmpty ? '' : ' | Category: $category'}'
                        '${supplierName == null || supplierName.isEmpty ? '' : ' | Supplier: $supplierName'}'
                        '${sku.isEmpty ? '' : ' | SKU: $sku'}'
                        '${barcode.isEmpty ? '' : ' | Barcode: $barcode'}',
                  );
                  saving.value = false;
                  if (ok) {
                    Get.back();
                    Get.snackbar(
                      'Stock added',
                      'Item Stock updated successfully',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF16A34A),
                      colorText: Colors.white,
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
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
    ],
  );

  qtyCtrl.dispose();
  rateCtrl.dispose();
  amountCtrl.dispose();
  taxCtrl.dispose();
  totalCtrl.dispose();
  skuCtrl.dispose();
  barcodeCtrl.dispose();
}

Future<void> showEditProductStockDrawer(
  InventoryController controller,
  ProductStockData item,
) async {
  if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
  if (controller.suppliers.isEmpty) {
    await controller.loadSuppliers();
  }
  if (controller.categories.isEmpty) {
    await controller.loadMenuCategories();
  }

  final formKey = GlobalKey<FormState>();
  final qtyCtrl = TextEditingController(
    text: item.stockQuantity == item.stockQuantity.roundToDouble()
        ? item.stockQuantity.toStringAsFixed(0)
        : item.stockQuantity.toStringAsFixed(2),
  );
  final rateCtrl = TextEditingController(
    text: item.rate == item.rate.roundToDouble()
        ? item.rate.toStringAsFixed(0)
        : item.rate.toStringAsFixed(2),
  );
  final amountCtrl = TextEditingController();
  final taxCtrl = TextEditingController(
    text: item.taxPercent == item.taxPercent.roundToDouble()
        ? item.taxPercent.toStringAsFixed(0)
        : item.taxPercent.toStringAsFixed(2),
  );
  final totalCtrl = TextEditingController();
  final skuCtrl = TextEditingController(text: item.sku);
  final barcodeCtrl = TextEditingController(text: item.barcode);
  String? selectedCategory = item.category.trim().isEmpty
      ? null
      : item.category.trim();
  var uom = 'NOS';
  final saving = false.obs;
  final categoryOptions = controller.productStockCategories;

  void recalc() {
    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
    final taxPct = double.tryParse(taxCtrl.text.trim()) ?? 0;
    final amount = qty * rate;
    final total = amount + (amount * taxPct / 100);
    amountCtrl.text = amount.toStringAsFixed(2);
    totalCtrl.text = total.toStringAsFixed(2);
  }

  recalc();

  InputDecoration deco(String label, {bool readOnly = false, String? prefix}) {
    return InputDecoration(
      labelText: label,
      prefixText: prefix,
      filled: readOnly,
      fillColor: readOnly ? const Color(0xFFF3F4F6) : null,
      border: const OutlineInputBorder(),
    );
  }

  await showInventoryEndDrawer(
    title: 'Edit Item Stock',
    width: 480,
    body: StatefulBuilder(
      builder: (context, setDrawerState) {
        return Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: item.itemName,
                readOnly: true,
                decoration: deco('Item name', readOnly: true),
              ),
              const SizedBox(height: 12),
              SearchableCategoryDropdown(
                categories: categoryOptions,
                value: selectedCategory,
                label: 'Category',
                decoration: deco('Category'),
                onChanged: (v) {
                  setDrawerState(() {
                    selectedCategory = (v == null || v.isEmpty) ? null : v;
                  });
                },
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d*'),
                        ),
                      ],
                      decoration: deco('Quantity *'),
                      onChanged: (_) => recalc(),
                      validator: (v) {
                        final qty = double.tryParse((v ?? '').trim());
                        if (qty == null || qty < 0) return 'Enter quantity';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdownFormField2<String>(
                      value: uom,
                      isExpanded: true,
                      decoration: deco('UOM'),
                      items: _productStockUoms
                          .map(
                            (e) => DropdownItem(value: e.$1, child: Text(e.$2)),
                          )
                          .toList(),
                      onChanged: (v) => uom = v ?? 'NOS',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: rateCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: deco('Rate *', prefix: '₹ '),
                onChanged: (_) => recalc(),
                validator: (v) {
                  final rate = double.tryParse((v ?? '').trim());
                  if (rate == null || rate < 0) return 'Enter rate';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: amountCtrl,
                readOnly: true,
                decoration: deco('Amount', readOnly: true, prefix: '₹ '),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: taxCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                decoration: deco('Tax (%)'),
                onChanged: (_) => recalc(),
                validator: (v) {
                  final tax = double.tryParse((v ?? '').trim());
                  if (tax == null || tax < 0) return 'Enter tax %';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: totalCtrl,
                readOnly: true,
                decoration: deco('Total', readOnly: true, prefix: '₹ '),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: skuCtrl,
                decoration: deco('SKU (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: barcodeCtrl,
                keyboardType: TextInputType.text,
                decoration: deco('Barcode (optional)'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    ),
    footerActions: [
      TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
      Obx(
        () => ElevatedButton(
          onPressed: saving.value
              ? null
              : () async {
                  if (!(formKey.currentState?.validate() ?? false)) return;
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                  final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
                  final taxPct = double.tryParse(taxCtrl.text.trim()) ?? 0;
                  final amount = qty * rate;
                  final total = amount + (amount * taxPct / 100);
                  final uomLabel = _productStockUoms
                      .firstWhere((e) => e.$1 == uom, orElse: () => (uom, uom))
                      .$2;
                  final sku = skuCtrl.text.trim();
                  final barcode = barcodeCtrl.text.trim();
                  final category = selectedCategory?.trim() ?? '';
                  saving.value = true;
                  final ok = await controller.adjustProductStock(
                    itemId: item.id,
                    adjustmentType: 'ADJUSTMENT',
                    quantity: qty,
                    reason: 'Other',
                    costPrice: rate,
                    sku: sku.isEmpty ? null : sku,
                    barcode: barcode.isEmpty ? null : barcode,
                    taxPercent: taxPct,
                    category: category.isEmpty ? null : category,
                    notes:
                        'Edited Item Stock | UOM: $uomLabel | '
                        'Rate: ₹${rate.toStringAsFixed(2)} | '
                        'Amount: ₹${amount.toStringAsFixed(2)} | '
                        'Tax: ${taxPct.toStringAsFixed(2)}% | '
                        'Total: ₹${total.toStringAsFixed(2)}'
                        '${category.isEmpty ? '' : ' | Category: $category'}'
                        '${item.supplierName.trim().isEmpty ? '' : ' | Supplier: ${item.supplierName.trim()}'}'
                        '${sku.isEmpty ? '' : ' | SKU: $sku'}'
                        '${barcode.isEmpty ? '' : ' | Barcode: $barcode'}',
                  );
                  saving.value = false;
                  if (ok) {
                    Get.back();
                    Get.snackbar(
                      'Stock updated',
                      'Item Stock updated successfully',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF16A34A),
                      colorText: Colors.white,
                    );
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColor.primary,
            foregroundColor: Colors.white,
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
    ],
  );

  qtyCtrl.dispose();
  rateCtrl.dispose();
  amountCtrl.dispose();
  taxCtrl.dispose();
  totalCtrl.dispose();
  skuCtrl.dispose();
  barcodeCtrl.dispose();
}

Future<void> showProductStockItemFilterDialog(
  InventoryController controller,
) async {
  final selected = <String>{...controller.productStockItemIdFilter}.obs;
  final searchQuery = ''.obs;
  final searchCtrl = TextEditingController();

  String money(num v) => v.toStringAsFixed(v == v.roundToDouble() ? 0 : 2);

  await Get.dialog(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: SizedBox(
        width: 520,
        height: 560,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filter Items',
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
              const Text(
                'Select items to include in the list and total stock value.',
                style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: searchCtrl,
                onChanged: (v) => searchQuery.value = v.trim().toLowerCase(),
                decoration: const InputDecoration(
                  hintText: 'Search items',
                  prefixIcon: Icon(Icons.search, size: 20),
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Obx(() {
                  final q = searchQuery.value;
                  final all = controller.productStock.toList();
                  final visible = q.isEmpty
                      ? all
                      : all
                            .where((i) => i.itemName.toLowerCase().contains(q))
                            .toList();
                  final visibleIds = visible.map((e) => e.id).toSet();
                  final allSelected =
                      visible.isNotEmpty && visibleIds.every(selected.contains);
                  final previewTotal = controller.productStock
                      .where((i) => selected.contains(i.id))
                      .fold<double>(0, (sum, i) => sum + i.total);

                  return Column(
                    children: [
                      Row(
                        children: [
                          TextButton(
                            onPressed: visible.isEmpty
                                ? null
                                : () {
                                    if (allSelected) {
                                      selected.removeAll(visibleIds);
                                    } else {
                                      selected.addAll(visibleIds);
                                    }
                                    selected.refresh();
                                  },
                            child: Text(
                              allSelected
                                  ? 'Deselect visible'
                                  : 'Select visible',
                            ),
                          ),
                          TextButton(
                            onPressed: selected.isEmpty
                                ? null
                                : () {
                                    selected.clear();
                                    selected.refresh();
                                  },
                            child: const Text('Clear'),
                          ),
                          const Spacer(),
                          Text(
                            selected.isEmpty
                                ? 'All items'
                                : '${selected.length} selected · ₹${money(previewTotal)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: visible.isEmpty
                            ? const Center(child: Text('No items found'))
                            : ListView.separated(
                                itemCount: visible.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                                itemBuilder: (_, i) {
                                  final item = visible[i];
                                  final checked = selected.contains(item.id);
                                  return CheckboxListTile(
                                    value: checked,
                                    dense: true,
                                    controlAffinity:
                                        ListTileControlAffinity.leading,
                                    title: Text(
                                      item.itemName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [
                                        if (item.category.trim().isNotEmpty)
                                          item.category.trim(),
                                        '₹${money(item.total)}',
                                      ].join(' · '),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    onChanged: (v) {
                                      if (v == true) {
                                        selected.add(item.id);
                                      } else {
                                        selected.remove(item.id);
                                      }
                                      selected.refresh();
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                }),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      controller.setProductStockItemFilter(selected);
                      Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );

  searchCtrl.dispose();
}

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
                final hasQty =
                    quantityText.value.trim().isNotEmpty &&
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
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
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
                                if (!StaffAccess.ensure(
                                  StaffAccess.canAdjustStock,
                                ))
                                  return;
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
                    _movementFilterChip('All', 'ALL', filter.value, () {
                      filter.value = 'ALL';
                      load();
                    }),
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
                              '${isOut
                                  ? '-'
                                  : isIn
                                  ? '+'
                                  : ''}${_formatQty(m.quantity)}',
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

/// Searchable item dropdown (id value, searchable by item name).
class SearchableItemDropdown extends StatefulWidget {
  const SearchableItemDropdown({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.label = 'Item name *',
    this.validator,
    this.decoration,
  });

  /// Map of item id -> item name
  final Map<String, String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final FormFieldValidator<String>? validator;
  final InputDecoration? decoration;

  @override
  State<SearchableItemDropdown> createState() => _SearchableItemDropdownState();
}

class _SearchableItemDropdownState extends State<SearchableItemDropdown> {
  late final TextEditingController _searchCtrl;
  late final ValueNotifier<String?> _valueListenable;

  @override
  void initState() {
    super.initState();
    _searchCtrl = TextEditingController();
    _valueListenable = ValueNotifier<String?>(widget.value);
  }

  @override
  void didUpdateWidget(covariant SearchableItemDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _valueListenable.value = widget.value;
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _valueListenable.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.items.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    return DropdownButtonFormField2<String>(
      isExpanded: true,
      valueListenable: _valueListenable,
      decoration:
          widget.decoration ??
          InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
      items: entries
          .map(
            (e) => DropdownItem(
              value: e.key,
              child: Text(
                e.value,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      selectedItemBuilder: (context) => entries
          .map(
            (e) => Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                e.value,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          )
          .toList(),
      validator: widget.validator,
      onChanged: (value) {
        _valueListenable.value = value;
        widget.onChanged(value);
      },
      onMenuStateChange: (isOpen) {
        if (!isOpen) _searchCtrl.clear();
      },
      iconStyleData: IconStyleData(
        icon: Icon(Icons.keyboard_arrow_down, color: AppColor.primary),
      ),
      dropdownStyleData: DropdownStyleData(
        maxHeight: 320,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
        ),
      ),
      dropdownSearchData: DropdownSearchData(
        searchController: _searchCtrl,
        searchBarWidgetHeight: 50,
        searchBarWidget: Container(
          height: 50,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: TextFormField(
            expands: true,
            maxLines: null,
            controller: _searchCtrl,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              hintText: 'Search item',
              hintStyle: const TextStyle(fontSize: 12),
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        searchMatchFn: (item, searchValue) {
          final id = item.value?.toString() ?? '';
          final name = widget.items[id] ?? '';
          return name.toLowerCase().contains(searchValue.toLowerCase());
        },
        noResultsWidget: const Padding(
          padding: EdgeInsets.all(12),
          child: Text('No item found', style: TextStyle(fontSize: 13)),
        ),
      ),
    );
  }
}
