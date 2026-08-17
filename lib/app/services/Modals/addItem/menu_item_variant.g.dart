// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'menu_item_variant.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MenuItemVariant _$MenuItemVariantFromJson(Map<String, dynamic> json) =>
    MenuItemVariant(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      outletId: json['outletId'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String? ?? '',
      barcode: json['barcode'] as String?,
      salePrice: (json['salePrice'] as num?)?.toDouble() ?? 0,
      costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
      trackStock: json['trackStock'] as bool? ?? false,
      stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0,
      minStock: (json['minStock'] as num?)?.toDouble() ?? 0,
      isDefault: json['isDefault'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$MenuItemVariantToJson(MenuItemVariant instance) =>
    <String, dynamic>{
      'id': instance.id,
      'itemId': instance.itemId,
      'outletId': instance.outletId,
      'userId': instance.userId,
      'name': instance.name,
      'sku': instance.sku,
      'barcode': instance.barcode,
      'salePrice': instance.salePrice,
      'costPrice': instance.costPrice,
      'trackStock': instance.trackStock,
      'stockQuantity': instance.stockQuantity,
      'minStock': instance.minStock,
      'isDefault': instance.isDefault,
      'isActive': instance.isActive,
      'sortOrder': instance.sortOrder,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

MenuItemVariantInput _$MenuItemVariantInputFromJson(
  Map<String, dynamic> json,
) => MenuItemVariantInput(
  id: json['id'] as String?,
  name: json['name'] as String,
  sku: json['sku'] as String? ?? '',
  barcode: json['barcode'] as String? ?? '',
  salePrice: (json['salePrice'] as num).toDouble(),
  costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
  trackStock: json['trackStock'] as bool? ?? false,
  stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0,
  minStock: (json['minStock'] as num?)?.toDouble() ?? 0,
  isDefault: json['isDefault'] as bool? ?? false,
  isActive: json['isActive'] as bool? ?? true,
  sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MenuItemVariantInputToJson(
  MenuItemVariantInput instance,
) => <String, dynamic>{
  'id': ?instance.id,
  'name': instance.name,
  'sku': instance.sku,
  'barcode': instance.barcode,
  'salePrice': instance.salePrice,
  'costPrice': instance.costPrice,
  'trackStock': instance.trackStock,
  'stockQuantity': instance.stockQuantity,
  'minStock': instance.minStock,
  'isDefault': instance.isDefault,
  'isActive': instance.isActive,
  'sortOrder': instance.sortOrder,
};
