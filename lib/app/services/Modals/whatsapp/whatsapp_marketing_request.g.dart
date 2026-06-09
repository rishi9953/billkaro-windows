// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whatsapp_marketing_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WhatsappMarketingRequest _$WhatsappMarketingRequestFromJson(
  Map<String, dynamic> json,
) => WhatsappMarketingRequest(
  userId: json['userId'] as String,
  templateType: json['templateType'] as String,
  message: json['message'] as String,
  restaurantName: json['restaurantName'] as String?,
  discountValue: json['discountValue'] as String?,
  festivalName: json['festivalName'] as String?,
  phoneNumbers: (json['phoneNumbers'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
);

Map<String, dynamic> _$WhatsappMarketingRequestToJson(
  WhatsappMarketingRequest instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'templateType': instance.templateType,
  'message': instance.message,
  'restaurantName': instance.restaurantName,
  'discountValue': instance.discountValue,
  'festivalName': instance.festivalName,
  'phoneNumbers': instance.phoneNumbers,
};
