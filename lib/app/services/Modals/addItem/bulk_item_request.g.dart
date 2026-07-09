// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_item_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulkItemRequest _$BulkItemRequestFromJson(Map<String, dynamic> json) =>
    BulkItemRequest(
      userId: json['userId'] as String,
      outletId: json['outletId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((e) => BulkItemEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BulkItemRequestToJson(BulkItemRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'outletId': instance.outletId,
      'items': instance.items.map((e) => e.toJson()).toList(),
    };

BulkItemEntry _$BulkItemEntryFromJson(Map<String, dynamic> json) =>
    BulkItemEntry(
      itemName: json['itemName'] as String,
      salePrice: (json['salePrice'] as num).toDouble(),
      withTax: json['withTax'] as bool,
      orderFrom: json['orderFrom'] as String,
      category: json['category'] as String,
      gst: (json['gst'] as num).toDouble(),
      showItem: json['showItem'] as bool,
      itemImage: json['itemImage'] as String? ?? '',
    );

Map<String, dynamic> _$BulkItemEntryToJson(BulkItemEntry instance) =>
    <String, dynamic>{
      'itemName': instance.itemName,
      'salePrice': instance.salePrice,
      'withTax': instance.withTax,
      'orderFrom': instance.orderFrom,
      'category': instance.category,
      'gst': instance.gst,
      'showItem': instance.showItem,
      'itemImage': instance.itemImage,
    };
