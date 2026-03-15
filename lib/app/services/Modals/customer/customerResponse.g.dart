// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'customerResponse.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CustomerResponse _$CustomerResponseFromJson(Map<String, dynamic> json) =>
    CustomerResponse(
      status: json['status'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => CustomerData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CustomerResponseToJson(CustomerResponse instance) =>
    <String, dynamic>{'status': instance.status, 'data': instance.data};

CustomerData _$CustomerDataFromJson(Map<String, dynamic> json) => CustomerData(
  id: json['id'] as String,
  createdAt: json['createdAt'] as String,
  updatedAt: json['updatedAt'] as String,
  userId: json['userId'] as String,
  outletId: json['outletId'] as String,
  customerName: json['customerName'] as String,
  phoneNumber: json['phoneNumber'] as String,
  loyalityDiscount: (json['loyalityDiscount'] as num).toInt(),
);

Map<String, dynamic> _$CustomerDataToJson(CustomerData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'userId': instance.userId,
      'outletId': instance.outletId,
      'customerName': instance.customerName,
      'phoneNumber': instance.phoneNumber,
      'loyalityDiscount': instance.loyalityDiscount,
    };
