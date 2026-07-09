import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/Widgets/gstin_verify_row.dart';
import 'package:billkaro/app/Widgets/windows_desktop_title_bar.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/gstin_verify_helper.dart';

double? _parseNonNegativeNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return 0;
  final value = double.tryParse(trimmed);
  if (value == null || value < 0) return null;
  return value;
}

double? _parsePositiveNumber(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return null;
  final value = double.tryParse(trimmed);
  if (value == null || value <= 0) return null;
  return value;
}

final _numberInputFormatters = [
  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
];

final _phoneInputFormatters = [FilteringTextInputFormatter.digitsOnly];

Widget _requiredLabel(String label) {
  return RichText(
    text: TextSpan(
      text: label,
      style: const TextStyle(color: Colors.black87, fontSize: 16),
      children: const [
        TextSpan(
          text: ' *',
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
        ),
      ],
    ),
  );
}

bool _isValidEmail(String email) {
  final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
  return regex.hasMatch(email);
}

Future<void> showInventoryEndDrawer({
  required String title,
  required Widget body,
  required List<Widget> footerActions,
  double width = 460,
}) async {
  await Get.generalDialog(
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (_, __, ___) => const SizedBox.shrink(),
    transitionBuilder: (context, animation, _, __) {
      final topInset = desktopOverlayTopInset();
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return Stack(
        children: [
          Positioned(
            top: topInset,
            left: 0,
            right: 0,
            bottom: 0,
            child: FadeTransition(
              opacity: curved,
              child: ModalBarrier(
                dismissible: true,
                color: Colors.black54,
                onDismiss: Get.back,
              ),
            ),
          ),
          Positioned(
            top: topInset,
            right: 0,
            bottom: 0,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(curved),
              child: Material(
                color: Colors.white,
                elevation: 16,
                child: SizedBox(
                  width: width,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: Get.back,
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: body,
                        ),
                      ),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: footerActions,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
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
  if (c.rawMaterialCategories.isEmpty) {
    await c.loadRawMaterialCategories();
  }
  final availableCategories = <String>{
    ...c.rawMaterialCategories,
    if ((material?.category ?? '').trim().isNotEmpty) material!.category.trim(),
  }.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  final nameCtrl = TextEditingController(text: material?.name ?? '');
  final stockCtrl = TextEditingController(
    text: (material?.currentStock ?? 0).toString(),
  );
  final minStockCtrl = TextEditingController(
    text: (material?.minStock ?? 5).toString(),
  );
  final priceCtrl = TextEditingController(
    text: (material?.purchasePrice ?? 0).toString(),
  );
  String? selectedCategory = (material?.category ?? '').trim().isNotEmpty
      ? material!.category
      : null;
  var unit = material?.unit ?? 'PIECE';

  await showInventoryEndDrawer(
    title: isEdit ? loc.edit_raw_material : loc.add_raw_material,
    body: Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(
              label: _requiredLabel(loc.material_column),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return loc.please_enter_material_name;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          AppDropdownFormField2<String>(
            value: selectedCategory,
            decoration: InputDecoration(
              label: _requiredLabel(loc.category),
              border: OutlineInputBorder(),
            ),
            items: availableCategories
                .map(
                  (category) => DropdownItem(
                    value: category,
                    child: Text(category.capitalizeFirst ?? ''),
                  ),
                )
                .toList(),
            onChanged: (v) => selectedCategory = v,
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return loc.select_category_required;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          AppDropdownFormField2<String>(
            value: unit,
            decoration: InputDecoration(
              labelText: loc.unit,
              border: OutlineInputBorder(),
            ),
            items: [
              DropdownItem(value: 'KG', child: Text(loc.kilogram_kg)),
              DropdownItem(value: 'GRAM', child: Text(loc.gram_g)),
              DropdownItem(value: 'LITER', child: Text(loc.liter_l)),
              DropdownItem(value: 'ML', child: Text(loc.milliliter_ml)),
              DropdownItem(value: 'PIECE', child: Text(loc.piece)),
              DropdownItem(value: 'PACKET', child: Text(loc.packet)),
              DropdownItem(value: 'BOX', child: Text(loc.box)),
            ],
            onChanged: (v) => unit = v ?? 'PIECE',
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: stockCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _numberInputFormatters,
                  decoration: InputDecoration(
                    label: _requiredLabel(loc.opening_stock),
                    helperText: ' ',
                    errorMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final stock = _parsePositiveNumber(value ?? '');
                    if (stock == null) return loc.invalid_opening_stock;
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: minStockCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: _numberInputFormatters,
                  decoration: InputDecoration(
                    label: _requiredLabel(loc.min_stock_alert),
                    helperText: ' ',
                    errorMaxLines: 2,
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    final raw = (value ?? '').trim();
                    if (raw.isEmpty) return loc.min_stock_required;
                    final minStock = _parseNonNegativeNumber(raw);
                    if (minStock == null) return loc.invalid_min_stock;
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _numberInputFormatters,
            decoration: InputDecoration(
              label: _requiredLabel(loc.purchase_price_per_unit),
              prefixText: '₹ ',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final price = _parsePositiveNumber(value ?? '');
              if (price == null) return loc.invalid_purchase_price;
              return null;
            },
          ),
        ],
      ),
    ),
    footerActions: [
      TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
      ElevatedButton(
        onPressed: () async {
          final isValid = formKey.currentState?.validate() ?? false;
          if (!isValid) return;
          final stock = _parsePositiveNumber(stockCtrl.text.trim())!;
          final minStock = _parseNonNegativeNumber(minStockCtrl.text.trim())!;
          final price = _parsePositiveNumber(priceCtrl.text.trim())!;
          final payload = {
            'name': nameCtrl.text.trim(),
            'category': selectedCategory!.trim(),
            'unit': unit,
            'currentStock': stock,
            'minStock': minStock,
            'purchasePrice': price,
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

  nameCtrl.dispose();
  stockCtrl.dispose();
  minStockCtrl.dispose();
  priceCtrl.dispose();
}

Future<void> showAddSupplierDialog(InventoryController c) async {
  await _showSupplierDialog(c);
}

Future<void> showEditSupplierDialog(
  InventoryController c,
  SupplierData supplier,
) async {
  await _showSupplierDialog(c, supplier: supplier);
}

Future<void> _showSupplierDialog(
  InventoryController c, {
  SupplierData? supplier,
}) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final isEdit = supplier != null;
  if (!isEdit) {
    await c.loadSuppliers();
  }
  final formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController(text: supplier?.name ?? '');
  final vendorNo = isEdit ? (supplier.vendorNo ?? '') : c.generateVendorNo();
  final vendorNoCtrl = TextEditingController(text: vendorNo);
  final contactPersonCtrl = TextEditingController(
    text: supplier?.contactPerson ?? '',
  );
  final phoneCtrl = TextEditingController(text: supplier?.phone ?? '');
  final emailCtrl = TextEditingController(text: supplier?.email ?? '');
  final addressCtrl = TextEditingController(text: supplier?.address ?? '');
  final gstCtrl = TextEditingController(text: supplier?.gstNumber ?? '');
  final gstinVerify = GstinVerifyHelper();
  final originalGst = (supplier?.gstNumber ?? '').trim().toUpperCase();
  if (isEdit && originalGst.isNotEmpty) {
    gstinVerify.isGstinVerified.value = true;
    gstinVerify.verifiedGstin.value = originalGst;
  }

  void handleGstinChanged() => gstinVerify.resetIfChanged(gstCtrl.text);
  gstCtrl.addListener(handleGstinChanged);

  Future<void> verifySupplierGstin() async {
    final details = await gstinVerify.verify(
      gstCtrl.text,
      onError: ({title, required description}) =>
          showError(title: title, description: description),
      onSuccess: ({title, required description}) =>
          showSuccess(title: title, description: description),
    );

    if (details == null || !gstinVerify.isGstinVerified.value) return;

    if (nameCtrl.text.trim().isEmpty && details.legalName != null) {
      nameCtrl.text = details.legalName!;
    }
    if (addressCtrl.text.trim().isEmpty && details.principalAddress != null) {
      addressCtrl.text = details.principalAddress!;
    }
    formKey.currentState?.validate();
  }

  await showInventoryEndDrawer(
    title: isEdit ? loc.edit_supplier : loc.add_supplier,
    body: Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            controller: nameCtrl,
            decoration: InputDecoration(
              label: _requiredLabel(loc.supplier_label),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return loc.please_enter_supplier_name;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: vendorNoCtrl,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Vendor No',
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: contactPersonCtrl,
            decoration: InputDecoration(
              label: _requiredLabel('Contact Person'),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return loc.please_enter_contact_person;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: _phoneInputFormatters,
            maxLength: 10,
            decoration: InputDecoration(
              label: _requiredLabel(loc.phone_label),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final phone = (value ?? '').trim().replaceAll(' ', '');
              if (phone.isEmpty) return loc.please_enter_phone_number;
              if (!RegExp(r'^\d{10}$').hasMatch(phone)) {
                return loc.please_enter_valid_10_digit_phone;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: emailCtrl,
            decoration: InputDecoration(
              label: _requiredLabel(loc.email),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final email = (value ?? '').trim();
              if (email.isEmpty) return loc.please_enter_email;
              if (!_isValidEmail(email)) return loc.please_enter_valid_email;
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: addressCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              label: _requiredLabel(loc.address_label),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if ((value ?? '').trim().isEmpty) {
                return loc.please_enter_address;
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: gstCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              label: _requiredLabel(loc.gst_number_label),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              final gst = (value ?? '').trim().toUpperCase();
              if (gst.isEmpty) return loc.please_enter_gst_number;
              if (gstinVerify.requiresVerification(gst)) {
                return 'Please verify GSTIN before saving supplier';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          GstinVerifyRow(helper: gstinVerify, onVerify: verifySupplierGstin),
        ],
      ),
    ),
    footerActions: [
      TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
      ElevatedButton(
        onPressed: () async {
          final isValid = formKey.currentState?.validate() ?? false;
          if (!isValid) return;
          final name = nameCtrl.text.trim();
          final contactPerson = contactPersonCtrl.text.trim();
          final phone = phoneCtrl.text.trim().replaceAll(' ', '');
          final email = emailCtrl.text.trim();
          final address = addressCtrl.text.trim();
          final gst = gstCtrl.text.trim().toUpperCase();
          final payload = {
            'name': name,
            'vendorNo': vendorNoCtrl.text.trim(),
            'contactPerson': contactPerson,
            'phone': phone,
            'email': email,
            'address': address,
            'gstNumber': gst,
          };
          final ok = isEdit
              ? await c.updateSupplier(supplier.id, payload)
              : await c.createSupplier(payload);
          if (ok) Get.back();
        },
        child: Text(loc.save),
      ),
    ],
  );

  gstCtrl.removeListener(handleGstinChanged);
  gstCtrl.dispose();
  vendorNoCtrl.dispose();
  contactPersonCtrl.dispose();
  nameCtrl.dispose();
  phoneCtrl.dispose();
  emailCtrl.dispose();
  addressCtrl.dispose();
}

Future<void> showStockAdjustDialog(
  InventoryController c,
  RawMaterialData material,
) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final qtyCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  var type = 'ADJUSTMENT_IN';

  await Get.dialog(
    AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      title: Text(loc.adjust_stock_title(material.name)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.current_stock_label(
                '${material.currentStock}',
                material.unit,
              ),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            AppDropdownFormField2<String>(
              value: type,
              decoration: InputDecoration(
                labelText: loc.transaction_type,
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownItem(value: 'ADJUSTMENT_IN', child: Text(loc.stock_in)),
                DropdownItem(
                  value: 'ADJUSTMENT_OUT',
                  child: Text(loc.stock_out),
                ),
                DropdownItem(value: 'WASTAGE', child: Text(loc.wastage)),
                DropdownItem(
                  value: 'RETURN',
                  child: Text(loc.return_to_supplier),
                ),
              ],
              onChanged: (v) => type = v ?? 'ADJUSTMENT_IN',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: loc.quantity_with_unit_label(material.unit),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: InputDecoration(
                labelText: loc.notes_label,
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
        ElevatedButton(
          onPressed: () async {
            final qty = double.tryParse(qtyCtrl.text);
            if (qty == null || qty <= 0) return;
            final ok = await c.adjustStock(
              rawMaterialId: material.id,
              type: type,
              quantity: qty,
              notes: notesCtrl.text.trim(),
            );
            if (ok) Get.back();
          },
          child: Text(loc.update_stock),
        ),
      ],
    ),
  );
}

Future<void> showAddRecipeDialog(
  InventoryController c, {
  String? preselectedItemId,
}) => _showRecipeDialog(c, preselectedItemId: preselectedItemId);

Future<void> showEditRecipeDialog(InventoryController c, RecipeData recipe) =>
    _showRecipeDialog(c, recipe: recipe);

Future<void> _showRecipeDialog(
  InventoryController c, {
  RecipeData? recipe,
  String? preselectedItemId,
}) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final isEdit = recipe != null;

  if (c.menuItems.isEmpty || c.rawMaterials.isEmpty) {
    await c.loadRecipeData();
  }

  final qtyCtrl = TextEditingController(
    text: isEdit ? recipe.quantity.toString() : '',
  );
  var selectedItemId = preselectedItemId ?? recipe?.itemId ?? '';
  var selectedMaterialId = recipe?.rawMaterialId ?? '';

  if (!isEdit) {
    if (selectedItemId.isEmpty && c.menuItems.length == 1) {
      selectedItemId = c.menuItems.first.id;
    }
    if (selectedMaterialId.isEmpty && c.rawMaterials.length == 1) {
      selectedMaterialId = c.rawMaterials.first.id;
    }
  }

  final lockItem = isEdit || preselectedItemId != null;

  await showInventoryEndDrawer(
    title: isEdit ? loc.edit_recipe : loc.add_recipe,
    body: StatefulBuilder(
      builder: (context, setState) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (lockItem)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                isEdit ? recipe.itemName : c.menuItemName(preselectedItemId!),
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            )
          else
            AppDropdownFormField2<String>(
              value: selectedItemId.isEmpty ? null : selectedItemId,
              decoration: InputDecoration(
                labelText: loc.select_menu_item,
                border: const OutlineInputBorder(),
              ),
              items: c.menuItems
                  .map(
                    (item) => DropdownItem(
                      value: item.id,
                      child: Text(item.itemName),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedItemId = v ?? ''),
            ),
          const SizedBox(height: 12),
          AppDropdownFormField2<String>(
            value: selectedMaterialId.isEmpty ? null : selectedMaterialId,
            decoration: InputDecoration(
              labelText: loc.select_raw_material,
              border: const OutlineInputBorder(),
            ),
            items: c.rawMaterials
                .map(
                  (m) => DropdownItem(
                    value: m.id,
                    child: Text('${m.name} (${m.unit})'),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => selectedMaterialId = v ?? ''),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: qtyCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: loc.recipe_quantity_hint,
              helperText: loc.recipe_quantity_helper,
              border: const OutlineInputBorder(),
            ),
          ),
        ],
      ),
    ),
    footerActions: [
      TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
      ElevatedButton(
        onPressed: () async {
          final itemId = lockItem
              ? (recipe?.itemId ?? preselectedItemId ?? '')
              : selectedItemId;
          if (itemId.isEmpty) {
            showError(description: loc.select_menu_item_required);
            return;
          }
          if (selectedMaterialId.isEmpty) {
            showError(description: loc.select_raw_material_required);
            return;
          }
          final qty = double.tryParse(qtyCtrl.text.trim());
          if (qty == null || qty <= 0) {
            showError(description: loc.recipe_quantity_invalid);
            return;
          }
          final ok = isEdit
              ? await c.updateRecipe(
                  id: recipe.id,
                  rawMaterialId: selectedMaterialId,
                  quantity: qty,
                )
              : await c.createRecipe(
                  itemId: itemId,
                  rawMaterialId: selectedMaterialId,
                  quantity: qty,
                );
          if (ok) Get.back();
        },
        child: Text(loc.save),
      ),
    ],
  );

  qtyCtrl.dispose();
}
