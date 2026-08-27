part of 'inventory_dialogs.dart';

String? _initialRawMaterialCategory(
  InventoryController c,
  RawMaterialData? material,
) {
  final existing = (material?.category ?? '').trim();
  if (existing.isNotEmpty) {
    return c.rawMaterialListCategories.firstWhereOrNull(
          (cat) => cat.toLowerCase() == existing.toLowerCase(),
        ) ??
        existing;
  }

  // Prefill from Stock tab category filter (empty = All).
  final filter = c.rawMaterialCategoryFilter.value.trim();
  if (filter.isEmpty) return null;
  return c.rawMaterialListCategories.firstWhereOrNull(
        (cat) => cat.toLowerCase() == filter.toLowerCase(),
      ) ??
      filter;
}

Future<void> showAddRawMaterialDialog(InventoryController c) async {
  await _showRawMaterialDialog(c);
}

Future<void> showEditRawMaterialDialog(
  InventoryController c,
  RawMaterialData material,
) async {
  await _showRawMaterialDialog(c, material: material);
}

Future<void> _showRawMaterialDialog(
  InventoryController c, {
  RawMaterialData? material,
}) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final formKey = GlobalKey<FormState>();
  final isEdit = material != null;

  if (c.suppliers.isEmpty) {
    await c.loadSuppliers();
  }
  if (c.rawMaterialCategoryItems.isEmpty) {
    await c.loadRawMaterialCategories();
  }

  final activeSuppliers = c.suppliers.where((s) => s.isActive).toList();
  final nameCtrl = TextEditingController(text: material?.name ?? '');
  String? selectedCategory = _initialRawMaterialCategory(c, material);
  final qtyCtrl = TextEditingController(
    text: material == null
        ? ''
        : material.currentStock.toStringAsFixed(
            material.currentStock == material.currentStock.roundToDouble()
                ? 0
                : 2,
          ),
  );
  final rateCtrl = TextEditingController(
    text: material == null
        ? ''
        : material.purchasePrice.toStringAsFixed(
            material.purchasePrice == material.purchasePrice.roundToDouble()
                ? 0
                : 2,
          ),
  );
  final amountCtrl = TextEditingController(text: '0.00');
  final taxCtrl = TextEditingController(
    text: (material?.taxRate ?? 0).toStringAsFixed(
      (material?.taxRate ?? 0) == (material?.taxRate ?? 0).roundToDouble()
          ? 0
          : 2,
    ),
  );
  final totalCtrl = TextEditingController(text: '0.00');
  final skuCtrl = TextEditingController(text: material?.materialCode ?? '');
  final barcodeCtrl = TextEditingController(text: material?.barcode ?? '');
  final minStockCtrl = TextEditingController(
    text: (material?.minStock ?? 5).toString(),
  );

  String? selectedSupplierId = (material?.supplierId ?? '').trim().isNotEmpty
      ? material!.supplierId
      : null;
  var unit = material?.unit ?? 'PIECE';

  void recalc() {
    final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
    final rate = double.tryParse(rateCtrl.text.trim()) ?? 0;
    final taxPct = double.tryParse(taxCtrl.text.trim()) ?? 0;
    final amount = qty * rate;
    amountCtrl.text = amount.toStringAsFixed(2);
    totalCtrl.text = (amount + (amount * taxPct / 100)).toStringAsFixed(2);
  }

  recalc();

  InputDecoration deco(
    String label, {
    bool readOnly = false,
    String? prefix,
    Widget? labelWidget,
  }) {
    return InputDecoration(
      labelText: labelWidget == null ? label : null,
      label: labelWidget,
      prefixText: prefix,
      filled: readOnly,
      fillColor: readOnly ? const Color(0xFFF3F4F6) : null,
      border: const OutlineInputBorder(),
    );
  }

  await showInventoryEndDrawer(
    title: isEdit ? loc.edit_raw_material : loc.add_raw_material,
    body: StatefulBuilder(
      builder: (context, setDrawerState) {
        return Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameCtrl,
                decoration: deco(
                  '',
                  labelWidget: _requiredLabel(loc.material_column),
                ),
                validator: (value) {
                  if ((value ?? '').trim().isEmpty) {
                    return loc.please_enter_material_name;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _requiredLabel(loc.category)),
                  TextButton.icon(
                    onPressed: () async {
                      final created = await c.showQuickAddCategoryDialog();
                      if (created != null && created.isNotEmpty) {
                        setDrawerState(() => selectedCategory = created);
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(loc.add_category),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColor.primary,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Obx(() {
                final _ = c.rawMaterialCategoryItems.length;
                final cats = List<String>.from(c.rawMaterialListCategories);
                if (selectedCategory != null &&
                    selectedCategory!.isNotEmpty &&
                    !cats.any(
                      (e) => e.toLowerCase() == selectedCategory!.toLowerCase(),
                    )) {
                  cats.add(selectedCategory!);
                }
                final dropdownValue = selectedCategory == null
                    ? null
                    : cats.firstWhereOrNull(
                            (e) =>
                                e.toLowerCase() ==
                                selectedCategory!.toLowerCase(),
                          ) ??
                          selectedCategory;
                return SearchableCategoryDropdown(
                  categories: cats,
                  value: dropdownValue,
                  label: loc.category,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    setDrawerState(() {
                      selectedCategory = (v == null || v.isEmpty) ? null : v;
                    });
                  },
                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return loc.category_example_hint;
                    }
                    return null;
                  },
                );
              }),
              const SizedBox(height: 12),
              AppDropdownFormField2<String>(
                value: selectedSupplierId,
                isExpanded: true,
                decoration: deco('Supplier (optional)'),
                items: activeSuppliers
                    .map((s) => DropdownItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) => setDrawerState(() => selectedSupplierId = v),
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
                      inputFormatters: _numberInputFormatters,
                      decoration: deco('Quantity *'),
                      onChanged: (_) => recalc(),
                      validator: (value) {
                        final qty = _parsePositiveNumber(value ?? '');
                        if (qty == null) return 'Enter quantity';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdownFormField2<String>(
                      value: unit,
                      isExpanded: true,
                      decoration: deco('UOM'),
                      items: [
                        DropdownItem(value: 'KG', child: Text(loc.kilogram_kg)),
                        DropdownItem(value: 'GRAM', child: Text(loc.gram_g)),
                        DropdownItem(value: 'LITER', child: Text(loc.liter_l)),
                        DropdownItem(
                          value: 'ML',
                          child: Text(loc.milliliter_ml),
                        ),
                        DropdownItem(
                          value: 'PIECE',
                          child: Text(loc.piece_pcs),
                        ),
                        DropdownItem(
                          value: 'PACKET',
                          child: Text(loc.packet_pkt),
                        ),
                        DropdownItem(value: 'BOX', child: Text(loc.box_box)),
                        DropdownItem(
                          value: 'DOZEN',
                          child: Text(loc.dozen_doz),
                        ),
                        DropdownItem(
                          value: 'BOTTLE',
                          child: Text(loc.bottle_btl),
                        ),
                      ],
                      onChanged: (v) =>
                          setDrawerState(() => unit = v ?? 'PIECE'),
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
                inputFormatters: _numberInputFormatters,
                decoration: deco('Rate *', prefix: '₹ '),
                onChanged: (_) => recalc(),
                validator: (value) {
                  final rate = _parseNonNegativeNumber(value ?? '');
                  if (rate == null) return 'Enter rate';
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
                inputFormatters: _numberInputFormatters,
                decoration: deco('Tax (%)'),
                onChanged: (_) => recalc(),
                validator: (value) {
                  final tax = _parseNonNegativeNumber(value ?? '');
                  if (tax == null) return 'Enter tax %';
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
                decoration: deco('Barcode (optional)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: minStockCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: _numberInputFormatters,
                decoration: deco(
                  '',
                  labelWidget: _requiredLabel(loc.min_stock_alert),
                ),
                validator: (value) {
                  final raw = (value ?? '').trim();
                  if (raw.isEmpty) return loc.min_stock_required;
                  final minStock = _parseNonNegativeNumber(raw);
                  if (minStock == null) return loc.invalid_min_stock;
                  return null;
                },
              ),
            ],
          ),
        );
      },
    ),
    footerActions: [
      TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
      ElevatedButton(
        onPressed: () async {
          final isValid = formKey.currentState?.validate() ?? false;
          if (!isValid) return;
          final qty = _parsePositiveNumber(qtyCtrl.text.trim())!;
          final rate = _parseNonNegativeNumber(rateCtrl.text.trim())!;
          final taxRate = _parseNonNegativeNumber(taxCtrl.text.trim())!;
          final minStock = _parseNonNegativeNumber(minStockCtrl.text.trim())!;
          final sku = skuCtrl.text.trim();
          final barcode = barcodeCtrl.text.trim();
          final supplierId = selectedSupplierId?.trim();
          final payload = <String, dynamic>{
            'name': nameCtrl.text.trim(),
            'category': (selectedCategory ?? '').trim(),
            'unit': unit,
            if (!isEdit) 'currentStock': qty,
            'minStock': minStock,
            'purchasePrice': rate,
            'taxRate': taxRate,
            'materialCode': sku,
            'barcode': barcode,
            if (supplierId != null && supplierId.isNotEmpty)
              'supplierId': supplierId,
          };
          final ok = isEdit
              ? await c.updateRawMaterial(material.id, payload)
              : await c.createRawMaterial(payload);
          if (ok) Get.back();
        },
        child: Text(loc.save),
      ),
    ],
  );

  // Wait for drawer reverse animation before disposing controllers.
  await Future.delayed(const Duration(milliseconds: 350));
  nameCtrl.dispose();
  qtyCtrl.dispose();
  rateCtrl.dispose();
  amountCtrl.dispose();
  taxCtrl.dispose();
  totalCtrl.dispose();
  skuCtrl.dispose();
  barcodeCtrl.dispose();
  minStockCtrl.dispose();
}
