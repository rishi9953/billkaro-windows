// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orderResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderResponse _$OrderResponseFromJson(Map<String, dynamic> json) =>
    OrderResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$OrderResponseToJson(OrderResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': instance.data,
    };

OrderModel _$OrderModelFromJson(Map<String, dynamic> json) => OrderModel(
  id: json['id'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  billNumber: json['billNumber'] as String,
  userId: json['userId'] as String,
  tableNumber: json['tableNumber'] as String?,
  customerName: json['customerName'] as String?,
  phoneNumber: json['phoneNumber'] as String?,
  outletId: json['outletId'] as String,
  subtotal: (json['subtotal'] as num).toDouble(),
  totalTax: (json['totalTax'] as num).toDouble(),
  discount: (json['discount'] as num).toDouble(),
  serviceCharge: (json['serviceCharge'] as num).toDouble(),
  totalAmount: (json['totalAmount'] as num).toDouble(),
  paymentReceivedIn: json['paymentReceivedIn'] as String?,
  splitPayments: (json['splitPayments'] as List<dynamic>?)
      ?.map((e) => SplitPayment.fromJson(e as Map<String, dynamic>))
      .toList(),
  status: json['status'] as String,
  items: (json['items'] as List<dynamic>)
      .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  orderFrom: json['orderFrom'] as String,
);

Map<String, dynamic> _$OrderModelToJson(OrderModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'billNumber': instance.billNumber,
      'userId': instance.userId,
      'tableNumber': instance.tableNumber,
      'outletId': instance.outletId,
      'customerName': instance.customerName,
      'phoneNumber': instance.phoneNumber,
      'subtotal': instance.subtotal,
      'totalTax': instance.totalTax,
      'discount': instance.discount,
      'serviceCharge': instance.serviceCharge,
      'totalAmount': instance.totalAmount,
      'paymentReceivedIn': instance.paymentReceivedIn,
      'splitPayments': instance.splitPayments,
      'status': instance.status,
      'orderFrom': instance.orderFrom,
      'items': instance.items,
    };

OrderItem _$OrderItemFromJson(Map<String, dynamic> json) => OrderItem(
  itemId: json['itemId'] as String,
  itemName: json['itemName'] as String,
  category: json['category'] as String,
  quantity: (json['quantity'] as num).toInt(),
  salePrice: (json['salePrice'] as num).toDouble(),
  gst: (json['gst'] as num).toDouble(),
);

Map<String, dynamic> _$OrderItemToJson(OrderItem instance) => <String, dynamic>{
  'itemId': instance.itemId,
  'itemName': instance.itemName,
  'category': instance.category,
  'quantity': instance.quantity,
  'salePrice': instance.salePrice,
  'gst': instance.gst,
};
