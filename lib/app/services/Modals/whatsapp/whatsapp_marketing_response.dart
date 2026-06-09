import 'package:json_annotation/json_annotation.dart';

part 'whatsapp_marketing_response.g.dart';

@JsonSerializable()
class WhatsappMarketingResponse {
  final String status;
  final String? message;
  final WhatsappMarketingResult? data;

  WhatsappMarketingResponse({
    required this.status,
    this.message,
    this.data,
  });

  factory WhatsappMarketingResponse.fromJson(Map<String, dynamic> json) =>
      _$WhatsappMarketingResponseFromJson(json);

  Map<String, dynamic> toJson() => _$WhatsappMarketingResponseToJson(this);
}

@JsonSerializable()
class WhatsappMarketingResult {
  final String? campaignId;
  final bool success;
  final int total;
  final int successCount;
  final int failureCount;
  final List<WhatsappSendResult> results;

  WhatsappMarketingResult({
    this.campaignId,
    required this.success,
    required this.total,
    required this.successCount,
    required this.failureCount,
    required this.results,
  });

  factory WhatsappMarketingResult.fromJson(Map<String, dynamic> json) =>
      _$WhatsappMarketingResultFromJson(json);

  Map<String, dynamic> toJson() => _$WhatsappMarketingResultToJson(this);
}

@JsonSerializable()
class WhatsappSendResult {
  final bool success;
  final String to;
  final String? error;
  final String? messageSid;

  WhatsappSendResult({
    required this.success,
    required this.to,
    this.error,
    this.messageSid,
  });

  factory WhatsappSendResult.fromJson(Map<String, dynamic> json) =>
      _$WhatsappSendResultFromJson(json);

  Map<String, dynamic> toJson() => _$WhatsappSendResultToJson(this);
}
