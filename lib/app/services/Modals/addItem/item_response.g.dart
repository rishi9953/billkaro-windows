// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ItemResponse _$ItemResponseFromJson(Map<String, dynamic> json) => ItemResponse(
  status: json['status'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => ItemData.fromJson(e as Map<String, dynamic>))
      .toList(),
  pagination: json['pagination'] == null
      ? null
      : PaginationMeta.fromJson(json['pagination'] as Map<String, dynamic>),
);

Map<String, dynamic> _$ItemResponseToJson(ItemResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'data': instance.data,
      'pagination': instance.pagination,
    };

PaginationMeta _$PaginationMetaFromJson(Map<String, dynamic> json) =>
    PaginationMeta(
      currentPage: (json['currentPage'] as num?)?.toInt(),
      totalPages: (json['totalPages'] as num?)?.toInt(),
      totalItems: (json['totalItems'] as num?)?.toInt(),
      itemsPerPage: (json['itemsPerPage'] as num?)?.toInt(),
      hasNextPage: json['hasNextPage'] as bool?,
      hasPreviousPage: json['hasPreviousPage'] as bool?,
    );

Map<String, dynamic> _$PaginationMetaToJson(PaginationMeta instance) =>
    <String, dynamic>{
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
      'totalItems': instance.totalItems,
      'itemsPerPage': instance.itemsPerPage,
      'hasNextPage': instance.hasNextPage,
      'hasPreviousPage': instance.hasPreviousPage,
    };

ItemData _$ItemDataFromJson(Map<String, dynamic> json) => ItemData(
  id: json['id'] as String,
  userId: json['userId'] as String,
  itemName: json['itemName'] as String,
  salePrice: (json['salePrice'] as num).toDouble(),
  withTax: json['withTax'] as bool,
  gst: (json['gst'] as num).toInt(),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  category: json['category'] as String,
  outletId: json['outletId'] as String,
  orderFrom: json['orderFrom'] as String?,
  itemImage: json['itemImage'] as String? ?? '',
  barcode: json['barcode'] as String? ?? '',
  sku: json['sku'] as String? ?? '',
  soldBy: json['soldBy'] as String? ?? 'Each',
  costPrice: (json['costPrice'] as num?)?.toDouble() ?? 0,
  posColor: json['posColor'] as String? ?? '',
  trackStock: json['trackStock'] as bool? ?? false,
  stockQuantity: (json['stockQuantity'] as num?)?.toDouble() ?? 0,
  minStock: (json['minStock'] as num?)?.toDouble() ?? 0,
  showItem: json['showItem'] as bool? ?? true,
  isRecommended: json['isRecommended'] as bool? ?? false,
  prepTimeMinutes: (json['prepTimeMinutes'] as num?)?.toInt() ?? 15,
  isCombo: json['isCombo'] as bool? ?? false,
  comboComponents:
      (json['comboComponents'] as List<dynamic>?)
          ?.map((e) => ComboComponent.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$ItemDataToJson(ItemData instance) => <String, dynamic>{
  'id': instance.id,
  'userId': instance.userId,
  'outletId': instance.outletId,
  'itemName': instance.itemName,
  'salePrice': instance.salePrice,
  'withTax': instance.withTax,
  'gst': instance.gst,
  'category': instance.category,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'itemImage': instance.itemImage,
  'orderFrom': instance.orderFrom,
  'barcode': instance.barcode,
  'sku': instance.sku,
  'soldBy': instance.soldBy,
  'costPrice': instance.costPrice,
  'posColor': instance.posColor,
  'trackStock': instance.trackStock,
  'stockQuantity': instance.stockQuantity,
  'minStock': instance.minStock,
  'showItem': instance.showItem,
  'isRecommended': instance.isRecommended,
  'prepTimeMinutes': instance.prepTimeMinutes,
  'isCombo': instance.isCombo,
  'comboComponents': instance.comboComponents.map((e) => e.toJson()).toList(),
};
