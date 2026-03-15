// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'printer_order_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrinterOrderRequest _$PrinterOrderRequestFromJson(Map<String, dynamic> json) =>
    PrinterOrderRequest(
      userId: json['userId'] as String,
      outletId: json['outletId'] as String,
      subscriptionId: json['subscriptionId'] as String,
      outletName: json['outletName'] as String,
      outletAddress: json['outletAddress'] as String,
      email: json['email'] as String,
      phoneNumber: json['phoneNumber'] as String,
      deliveryAddress: json['deliveryAddress'] as String,
      pincode: json['pincode'] as String,
      status: json['status'] as String,
    );

Map<String, dynamic> _$PrinterOrderRequestToJson(
  PrinterOrderRequest instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'outletId': instance.outletId,
  'subscriptionId': instance.subscriptionId,
  'outletName': instance.outletName,
  'outletAddress': instance.outletAddress,
  'email': instance.email,
  'phoneNumber': instance.phoneNumber,
  'deliveryAddress': instance.deliveryAddress,
  'pincode': instance.pincode,
  'status': instance.status,
};
