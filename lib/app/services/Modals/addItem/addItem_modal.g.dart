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
      'showItem': instance.showItem,
    };
