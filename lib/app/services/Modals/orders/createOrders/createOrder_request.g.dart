// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'createOrder_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateorderRequest _$CreateorderRequestFromJson(Map<String, dynamic> json) =>
    CreateorderRequest(
      billNumber: json['billNumber'] as String?,
      userId: json['userId'] as String?,
      outletId: json['outletId'] as String?,
      tableNumber: json['tableNumber'] as String?,
      customerName: json['customerName'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble(),
      totalTax: (json['totalTax'] as num?)?.toDouble(),
      discount: (json['discount'] as num?)?.toDouble(),
      serviceCharge: (json['serviceCharge'] as num?)?.toDouble(),
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
      paymentReceivedIn: json['paymentReceivedIn'] as String?,
      splitPayments: (json['splitPayments'] as List<dynamic>?)
          ?.map((e) => SplitPayment.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String?,
      items: (json['items'] as List<dynamic>?)
          ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      orderFrom: json['orderFrom'] as String?,
    );

Map<String, dynamic> _$CreateorderRequestToJson(CreateorderRequest instance) =>
    <String, dynamic>{
      'billNumber': instance.billNumber,
      'userId': instance.userId,
      'outletId': instance.outletId,
      'tableNumber': instance.tableNumber,
      'customerName': instance.customerName,
      'phoneNumber': instance.phoneNumber,
      'subtotal': instance.subtotal,
      'totalTax': instance.totalTax,
      'discount': instance.discount,
      'serviceCharge': instance.serviceCharge,
      'totalAmount': instance.totalAmount,
      'paymentReceivedIn': instance.paymentReceivedIn,
      'splitPayments': instance.splitPayments?.map((e) => e.toJson()).toList(),
      'status': instance.status,
      'orderFrom': instance.orderFrom,
      'items': instance.items?.map((e) => e.toJson()).toList(),
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
