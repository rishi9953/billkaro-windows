import 'package:billkaro/app/Widgets/gstin_verify_row.dart';
import 'package:billkaro/app/modules/Inventory/inventory_controller.dart';
import 'package:billkaro/app/services/Modals/inventory/inventory_models.dart';
import 'package:billkaro/config/config.dart';
import 'package:billkaro/utils/gstin_verify_helper.dart';

Future<void> showAddRawMaterialDialog(InventoryController c) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final nameCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final stockCtrl = TextEditingController(text: '0');
  final minStockCtrl = TextEditingController(text: '5');
  final priceCtrl = TextEditingController(text: '0');
  var unit = 'PIECE';

  await Get.dialog(
    AlertDialog(
      title: Text(loc.add_raw_material),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: '${loc.material_column} *',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                decoration: InputDecoration(
                  labelText: loc.category_example_hint,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: unit,
                decoration: InputDecoration(
                  labelText: loc.unit,
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'KG', child: Text(loc.kilogram_kg)),
                  DropdownMenuItem(value: 'GRAM', child: Text(loc.gram_g)),
                  DropdownMenuItem(value: 'LITER', child: Text(loc.liter_l)),
                  DropdownMenuItem(value: 'ML', child: Text(loc.milliliter_ml)),
                  DropdownMenuItem(value: 'PIECE', child: Text(loc.piece)),
                  DropdownMenuItem(value: 'PACKET', child: Text(loc.packet)),
                  DropdownMenuItem(value: 'BOX', child: Text(loc.box)),
                ],
                onChanged: (v) => unit = v ?? 'PIECE',
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.opening_stock,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: minStockCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: loc.min_stock_alert,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: loc.purchase_price_per_unit,
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            final ok = await c.createRawMaterial({
              'name': nameCtrl.text.trim(),
              'category': categoryCtrl.text.trim(),
              'unit': unit,
              'currentStock': double.tryParse(stockCtrl.text) ?? 0,
              'minStock': double.tryParse(minStockCtrl.text) ?? 0,
              'purchasePrice': double.tryParse(priceCtrl.text) ?? 0,
            });
            if (ok) Get.back();
          },
          child: Text(loc.save),
        ),
      ],
    ),
  );
}

Future<void> showAddSupplierDialog(InventoryController c) async {
  final loc = AppLocalizations.of(Get.context!)!;
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final gstCtrl = TextEditingController();
  final gstinVerify = GstinVerifyHelper();

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
  }

  await Get.dialog(
    AlertDialog(
      title: Text(loc.add_supplier),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: loc.supplier_name_required,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: loc.phone_label,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: loc.email,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: loc.address_label,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: gstCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: loc.gst_number_label,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              GstinVerifyRow(
                helper: gstinVerify,
                onVerify: verifySupplierGstin,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back(), child: Text(loc.cancel)),
        ElevatedButton(
          onPressed: () async {
            if (nameCtrl.text.trim().isEmpty) return;
            if (gstinVerify.requiresVerification(gstCtrl.text)) {
              showError(description: 'Please verify GSTIN before saving supplier');
              return;
            }
            final ok = await c.createSupplier({
              'name': nameCtrl.text.trim(),
              'phone': phoneCtrl.text.trim(),
              'email': emailCtrl.text.trim(),
              'address': addressCtrl.text.trim(),
              'gstNumber': gstCtrl.text.trim().toUpperCase(),
            });
            if (ok) Get.back();
          },
          child: Text(loc.save),
        ),
      ],
    ),
  );

  gstCtrl.removeListener(handleGstinChanged);
  gstCtrl.dispose();
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
      title: Text(loc.adjust_stock_title(material.name)),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.current_stock_label('${material.currentStock}', material.unit),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: type,
              decoration: InputDecoration(
                labelText: loc.transaction_type,
                border: OutlineInputBorder(),
              ),
              items: [
                DropdownMenuItem(
                  value: 'ADJUSTMENT_IN',
                  child: Text(loc.stock_in),
                ),
                DropdownMenuItem(
                  value: 'ADJUSTMENT_OUT',
                  child: Text(loc.stock_out),
                ),
                DropdownMenuItem(value: 'WASTAGE', child: Text(loc.wastage)),
                DropdownMenuItem(value: 'RETURN', child: Text(loc.return_to_supplier)),
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
