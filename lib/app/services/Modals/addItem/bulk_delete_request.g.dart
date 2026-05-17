// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bulk_delete_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BulkDeleteRequest _$BulkDeleteRequestFromJson(Map<String, dynamic> json) =>
    BulkDeleteRequest(
      outletId: json['outletId'] as String,
      itemIds: (json['itemIds'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
    );

Map<String, dynamic> _$BulkDeleteRequestToJson(BulkDeleteRequest instance) =>
    <String, dynamic>{
      'outletId': instance.outletId,
      'itemIds': instance.itemIds,
    };
