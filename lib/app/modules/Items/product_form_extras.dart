import 'package:billkaro/app/Widgets/app_dropdowns.dart';
import 'package:billkaro/app/modules/Items/add_menu_items_controller.dart';
import 'package:billkaro/config/config.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Color? parsePosColor(String hex) {
  if (hex.isEmpty) return null;
  var value = hex.replaceFirst('#', '');
  if (value.length == 6) value = 'FF$value';
  if (value.length != 8) return null;
  return Color(int.parse(value, radix: 16));
}

/// Extra product fields matching Square-like New Product form.
class ProductFormExtras extends StatelessWidget {
  const ProductFormExtras({
    super.key,
    required this.controller,
    this.barcodeController,
    this.showBarcodeScanner = true,
    this.onScanBarcode,
  });

  final AddMenuItemController controller;
  final TextEditingController? barcodeController;
  final bool showBarcodeScanner;
  final VoidCallback? onScanBarcode;

  InputDecoration _decoration(
    BuildContext context, {
    String? hintText,
    Widget? suffixIcon,
    String? prefixText,
  }) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: Colors.grey[400]),
      prefixText: prefixText,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: theme.colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: AppColor.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final barcodeCtrl = barcodeController ?? controller.barcodeController;

    Widget sectionDivider(IconData icon, String label) {
      return Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 14),
        child: Row(
          children: [
            Icon(icon, size: 18, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Divider(color: Colors.grey[300])),
          ],
        ),
      );
    }

    Widget fieldLabel(String text) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 13,
          color: Colors.grey[600],
          fontWeight: FontWeight.w600,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        fieldLabel('Sold by'),
        const SizedBox(height: 8),
        Obx(
          () => AppDropdownFormField2<String>(
            isExpanded: true,
            decoration: _decoration(context),
            value: controller.selectedSoldBy.value,
            items: AddMenuItemController.soldByOptions
                .map(
                  (o) => DropdownItem<String>(value: o, child: Text(o)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) controller.selectedSoldBy.value = value;
            },
            iconStyleData: IconStyleData(
              icon: Icon(Icons.keyboard_arrow_down, color: AppColor.primary),
            ),
          ),
        ),
        const SizedBox(height: 18),
        fieldLabel('Cost'),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller.costPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
          ],
          decoration: _decoration(
            context,
            hintText: 'Cost price (optional)',
            prefixText: '₹ ',
          ),
        ),
        const SizedBox(height: 18),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('Barcode'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: barcodeCtrl,
                    decoration: _decoration(
                      context,
                      hintText: 'Barcode (optional)',
                      suffixIcon: showBarcodeScanner
                          ? SizedBox(
                              width: 96,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  IconButton(
                                    tooltip: 'Look up on Open Food Facts',
                                    onPressed: controller
                                        .lookupOpenFoodFactsByBarcode,
                                    icon: Icon(
                                      Icons.travel_explore_outlined,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Scan barcode',
                                    onPressed: onScanBarcode ??
                                        controller.scanBarcode,
                                    icon: Icon(
                                      Icons.qr_code_scanner,
                                      color: AppColor.primary,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : IconButton(
                              tooltip: 'Look up on Open Food Facts',
                              onPressed:
                                  controller.lookupOpenFoodFactsByBarcode,
                              icon: Icon(
                                Icons.travel_explore_outlined,
                                color: AppColor.primary,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  fieldLabel('SKU'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: controller.skuController,
                    decoration: _decoration(
                      context,
                      hintText: 'SKU (optional)',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        sectionDivider(Icons.warehouse_outlined, 'Inventory'),
        Obx(
          () => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Track Stock',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[800],
                        ),
                      ),
                    ),
                    Switch(
                      value: controller.trackStock.value,
                      activeColor: AppColor.primary.withOpacity(0.95),
                      activeTrackColor: AppColor.primary.withOpacity(0.25),
                      onChanged: (v) => controller.trackStock.value = v,
                    ),
                  ],
                ),
                if (controller.trackStock.value) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: controller.stockController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: _decoration(context, hintText: 'Stock'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: controller.minStockController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'),
                            ),
                          ],
                          decoration: _decoration(
                            context,
                            hintText: 'Low stock alert',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sales auto-deduct product stock. Recipes deduct ingredients separately.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        sectionDivider(Icons.desktop_windows_outlined, 'Representation on POS'),
        fieldLabel('POS tile color (used when no image)'),
        const SizedBox(height: 10),
        Obx(
          () => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: AddMenuItemController.posColorOptions.map((hex) {
              final selected = controller.selectedPosColor.value == hex;
              final color = parsePosColor(hex);
              return InkWell(
                onTap: () => controller.selectedPosColor.value = hex,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color ?? Colors.white,
                    border: Border.all(
                      color: selected
                          ? AppColor.primary
                          : Colors.grey.shade400,
                      width: selected ? 2.5 : 1,
                    ),
                  ),
                  child: hex.isEmpty
                      ? Icon(Icons.close, size: 16, color: Colors.grey[600])
                      : selected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}
