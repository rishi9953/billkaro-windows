// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubscriptionResponse _$SubscriptionResponseFromJson(
  Map<String, dynamic> json,
) => SubscriptionResponse(
  status: json['status'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$SubscriptionResponseToJson(
  SubscriptionResponse instance,
) => <String, dynamic>{'status': instance.status, 'data': instance.data};

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    SubscriptionPlan(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      title: json['title'] as String,
      price: (json['price'] as num).toDouble(),
      discountedPrice: (json['discountedPrice'] as num).toDouble(),
      subtitle: json['subtitle'] as String,
      bulletPoints: (json['bulletPoints'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      showImage: json['showImage'] as bool,
      duration: (json['duration'] as num).toInt(),
      tax: (json['tax'] as num).toInt(),
      withPrinter: json['withPrinter'] as bool,
      platform: json['platform'] as String,
    );

Map<String, dynamic> _$SubscriptionPlanToJson(SubscriptionPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'title': instance.title,
      'price': instance.price,
      'discountedPrice': instance.discountedPrice,
      'subtitle': instance.subtitle,
      'bulletPoints': instance.bulletPoints,
      'showImage': instance.showImage,
      'duration': instance.duration,
      'tax': instance.tax,
      'withPrinter': instance.withPrinter,
      'platform': instance.platform,
    };
