// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customerRequest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerRequest _$CustomerRequestFromJson(Map<String, dynamic> json) =>
    CustomerRequest(
      userId: json['userId'] as String,
      outletId: json['outletId'] as String,
      customerName: json['customerName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      loyalityDiscount: (json['loyalityDiscount'] as num).toInt(),
    );

Map<String, dynamic> _$CustomerRequestToJson(CustomerRequest instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'outletId': instance.outletId,
      'customerName': instance.customerName,
      'phoneNumber': instance.phoneNumber,
      'loyalityDiscount': instance.loyalityDiscount,
    };
