import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'menu_item_variant.g.dart';

@JsonSerializable()
class MenuItemVariant {
  final String id;
  final String itemId;
  final String outletId;
  final String userId;
  final String name;
  @JsonKey(defaultValue: '')
  final String sku;
  final String? barcode;
  @JsonKey(defaultValue: 0)
  final double salePrice;
  @JsonKey(defaultValue: 0)
  final double costPrice;
  @JsonKey(defaultValue: false)
  final bool trackStock;
  @JsonKey(defaultValue: 0)
  final double stockQuantity;
  @JsonKey(defaultValue: 0)
  final double minStock;
  @JsonKey(defaultValue: false)
  final bool isDefault;
  @JsonKey(defaultValue: true)
  final bool isActive;
  @JsonKey(defaultValue: 0)
  final int sortOrder;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  MenuItemVariant({
    required this.id,
    required this.itemId,
    required this.outletId,
    required this.userId,
    required this.name,
    this.sku = '',
    this.barcode,
    this.salePrice = 0,
    this.costPrice = 0,
    this.trackStock = false,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
    this.updatedAt,
  });

  factory MenuItemVariant.fromJson(Map<String, dynamic> json) =>
      _$MenuItemVariantFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemVariantToJson(this);
}

@JsonSerializable(includeIfNull: false)
class MenuItemVariantInput {
  final String? id;
  final String name;
  final String sku;
  final String barcode;
  final double salePrice;
  final double costPrice;
  final bool trackStock;
  final double stockQuantity;
  final double minStock;
  final bool isDefault;
  final bool isActive;
  final int sortOrder;

  MenuItemVariantInput({
    this.id,
    required this.name,
    this.sku = '',
    this.barcode = '',
    required this.salePrice,
    this.costPrice = 0,
    this.trackStock = false,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  factory MenuItemVariantInput.fromJson(Map<String, dynamic> json) =>
      _$MenuItemVariantInputFromJson(json);

  Map<String, dynamic> toJson() => _$MenuItemVariantInputToJson(this);
}

class VariantDraft {
  VariantDraft({
    this.id,
    required this.nameController,
    required this.priceController,
    this.sku = '',
    this.barcode = '',
    this.costPrice = 0,
    this.trackStock = false,
    this.stockQuantity = 0,
    this.minStock = 0,
    this.isDefault = false,
    this.isActive = true,
    this.sortOrder = 0,
  });

  final String? id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  String sku;
  String barcode;
  double costPrice;
  bool trackStock;
  double stockQuantity;
  double minStock;
  bool isDefault;
  bool isActive;
  int sortOrder;

  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }

  MenuItemVariantInput toInput() {
    return MenuItemVariantInput(
      id: id,
      name: nameController.text.trim(),
      sku: sku.trim(),
      barcode: barcode.trim(),
      salePrice: double.tryParse(priceController.text.trim()) ?? 0,
      costPrice: costPrice,
      trackStock: trackStock,
      stockQuantity: stockQuantity,
      minStock: minStock,
      isDefault: isDefault,
      isActive: isActive,
      sortOrder: sortOrder,
    );
  }

  static VariantDraft fromVariant(MenuItemVariant variant) {
    return VariantDraft(
      id: variant.id,
      nameController: TextEditingController(text: variant.name),
      priceController: TextEditingController(
        text: variant.salePrice.toString(),
      ),
      sku: variant.sku,
      barcode: variant.barcode ?? '',
      costPrice: variant.costPrice,
      trackStock: variant.trackStock,
      stockQuantity: variant.stockQuantity,
      minStock: variant.minStock,
      isDefault: variant.isDefault,
      isActive: variant.isActive,
      sortOrder: variant.sortOrder,
    );
  }
}
