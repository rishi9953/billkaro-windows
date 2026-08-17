import 'package:billkaro/app/services/Modals/addItem/item_response.dart';
import 'package:billkaro/app/services/Modals/addItem/menu_item_variant.dart';
import 'package:billkaro/config/config.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

Future<MenuItemVariant?> showVariantPickerDialog({
  required ItemData item,
  required List<MenuItemVariant> variants,
}) async {
  if (variants.isEmpty) return null;
  if (variants.length == 1) return variants.first;

  return Get.dialog<MenuItemVariant>(
    Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.itemName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Select Variant',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              ...variants.map(
                (variant) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.circle_outlined, color: AppColor.primary),
                  title: Text(variant.name),
                  trailing: Text(
                    '₹${variant.salePrice.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () => Get.back(result: variant),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    barrierDismissible: true,
  );
}
