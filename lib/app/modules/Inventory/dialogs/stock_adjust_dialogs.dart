part of 'inventory_dialogs.dart';

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
            if (!StaffAccess.ensure(StaffAccess.canAdjustStock)) return;
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
