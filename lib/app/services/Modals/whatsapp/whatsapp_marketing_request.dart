import 'package:json_annotation/json_annotation.dart';

part 'whatsapp_marketing_request.g.dart';

@JsonSerializable()
class WhatsappMarketingRequest {
  final String userId;
  final String templateType;
  final String message;
  final String? restaurantName;
  final String? discountValue;
  final String? festivalName;
  final List<String>? phoneNumbers;

  WhatsappMarketingRequest({
    required this.userId,
    required this.templateType,
    required this.message,
    this.restaurantName,
    this.discountValue,
    this.festivalName,
    this.phoneNumbers,
  });

  factory WhatsappMarketingRequest.fromJson(Map<String, dynamic> json) =>
      _$WhatsappMarketingRequestFromJson(json);

  Map<String, dynamic> toJson() => _$WhatsappMarketingRequestToJson(this);
}
