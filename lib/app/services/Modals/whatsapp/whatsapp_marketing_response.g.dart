// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'whatsapp_marketing_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WhatsappMarketingResponse _$WhatsappMarketingResponseFromJson(
  Map<String, dynamic> json,
) => WhatsappMarketingResponse(
  status: json['status'] as String,
  message: json['message'] as String?,
  data: json['data'] == null
      ? null
      : WhatsappMarketingResult.fromJson(
          json['data'] as Map<String, dynamic>,
        ),
);

Map<String, dynamic> _$WhatsappMarketingResponseToJson(
  WhatsappMarketingResponse instance,
) => <String, dynamic>{
  'status': instance.status,
  'message': instance.message,
  'data': instance.data,
};

WhatsappMarketingResult _$WhatsappMarketingResultFromJson(
  Map<String, dynamic> json,
) => WhatsappMarketingResult(
  campaignId: json['campaignId'] as String?,
  success: json['success'] as bool,
  total: (json['total'] as num).toInt(),
  successCount: (json['successCount'] as num).toInt(),
  failureCount: (json['failureCount'] as num).toInt(),
  results: (json['results'] as List<dynamic>)
      .map((e) => WhatsappSendResult.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$WhatsappMarketingResultToJson(
  WhatsappMarketingResult instance,
) => <String, dynamic>{
  'campaignId': instance.campaignId,
  'success': instance.success,
  'total': instance.total,
  'successCount': instance.successCount,
  'failureCount': instance.failureCount,
  'results': instance.results,
};

WhatsappSendResult _$WhatsappSendResultFromJson(Map<String, dynamic> json) =>
    WhatsappSendResult(
      success: json['success'] as bool,
      to: json['to'] as String,
      error: json['error'] as String?,
      messageSid: json['messageSid'] as String?,
    );

Map<String, dynamic> _$WhatsappSendResultToJson(WhatsappSendResult instance) =>
    <String, dynamic>{
      'success': instance.success,
      'to': instance.to,
      'error': instance.error,
      'messageSid': instance.messageSid,
    };
