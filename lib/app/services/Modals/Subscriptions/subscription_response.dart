import 'package:json_annotation/json_annotation.dart';

part 'subscription_response.g.dart';

@JsonSerializable()
class SubscriptionResponse {
  final String status;
  final List<SubscriptionPlan> data;

  SubscriptionResponse({required this.status, required this.data});

  factory SubscriptionResponse.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionResponseFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionResponseToJson(this);
}

@JsonSerializable()
class SubscriptionPlan {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String title;
  final double price;
  final double discountedPrice;
  final String subtitle;
  final List<String> bulletPoints;
  final bool showImage;
  final int duration;
  final int tax;
  final bool withPrinter;

  SubscriptionPlan({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.title,
    required this.price,
    required this.discountedPrice,
    required this.subtitle,
    required this.bulletPoints,
    required this.showImage,
    required this.duration,
    required this.tax,
    required this.withPrinter,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);
}
