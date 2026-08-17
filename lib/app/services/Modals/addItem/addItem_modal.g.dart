// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'addItem_modal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemRequest _$ItemRequestFromJson(Map<String, dynamic> json) => ItemRequest(
  itemName: json['itemName'] as String,
  salePrice: (json['salePrice'] as num).toDouble(),
  withTax: json['withTax'] as bool,
  gst: (json['gst'] as num).toDouble(),
  orderFrom: json['orderFrom'] as String,
  userId: json['userId'] as String,
  category: json['category'] as String,
  outletId: json['outletId'] as String,
  showItem: json['showItem'] as bool,
  itemImage: json['itemImage'] as String? ?? '',
  barcode: json['barcode'] as String? ?? '',
  sku: json['sku'] as String? ?? '',
  soldBy: json['soldBy'] as String? ?? 'Each',
  costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
  posColor: json['posColor'] as String? ?? '',
  trackStock: json['trackStock'] as bool? ?? false,
  stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0,
  minStock: (json['minStock'] as num?)?.toDouble() ?? 0,
  isRecommended: json['isRecommended'] as bool?,
  prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt() ?? 15,
  isCombo: json['isCombo'] as bool? ?? false,
  comboComponents:
      (json['comboComponents'] as List<dynamic>?)
          ?.map((e) => ComboComponent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  linkedRecipeItemId: json['linkedRecipeItemId'] as String? ?? '',
  hasVariants: json['hasVariants'] as bool?,
  variants:
      (json['variants'] as List<dynamic>?)
          ?.map((e) => MenuItemVariantInput.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ItemRequestToJson(ItemRequest instance) =>
    <String, dynamic>{
      'itemName': instance.itemName,
      'salePrice': instance.salePrice,
      'withTax': instance.withTax,
      'orderFrom': instance.orderFrom,
      'gst': instance.gst,
      'userId': instance.userId,
      'outletId': instance.outletId,
      'category': instance.category,
      'itemImage': instance.itemImage,
      'barcode': instance.barcode,
      'sku': instance.sku,
      'soldBy': instance.soldBy,
      'costPrice': instance.costPrice,
      'posColor': instance.posColor,
      'trackStock': instance.trackStock,
      'stockQuantity': instance.stockQuantity,
      'minStock': instance.minStock,
      'showItem': instance.showItem,
      'isRecommended': ?instance.isRecommended,
      'prepTimeMinutes': instance.prepTimeMinutes,
      'isCombo': instance.isCombo,
      'comboComponents': instance.comboComponents,
      'linkedRecipeItemId': instance.linkedRecipeItemId,
      'hasVariants': ?instance.hasVariants,
      'variants': instance.variants,
    };
