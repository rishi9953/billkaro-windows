// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activities_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActivityResponseModel _$ActivityResponseModelFromJson(
  Map<String, dynamic> json,
) => ActivityResponseModel(
  status:
      ActivityResponseModel._readOptionalStringTop(json, 'status') as String,
  message:
      ActivityResponseModel._readOptionalStringTop(json, 'message') as String,
  data: ActivityResponseModel._activityListFromJson(json['data']),
  pagination: ActivityResponseModel._paginationFromJson(json['pagination']),
);

Map<String, dynamic> _$ActivityResponseModelToJson(
  ActivityResponseModel instance,
) => <String, dynamic>{
  'status': instance.status,
  'message': instance.message,
  'data': instance.data,
  'pagination': instance.pagination,
};

ActivityModel _$ActivityModelFromJson(
  Map<String, dynamic> json,
) => ActivityModel(
  id: ActivityModel._readId(json, 'id') as String,
  createdAt: ActivityModel._readOptionalString(json, 'createdAt') as String,
  updatedAt: ActivityModel._readOptionalString(json, 'updatedAt') as String,
  type: ActivityModel._readOptionalString(json, 'type') as String,
  userId: ActivityModel._readOptionalString(json, 'userId') as String,
  createdByName:
      ActivityModel._readCreatedByName(json, 'createdByName') as String,
  outletId: ActivityModel._readOptionalString(json, 'outletId') as String,
  entityId: ActivityModel._readOptionalString(json, 'entityId') as String,
  entityName: ActivityModel._readOptionalString(json, 'entityName') as String,
  details: ActivityModel._detailsFromJson(json['details']),
  description: ActivityModel._readOptionalString(json, 'description') as String,
);

Map<String, dynamic> _$ActivityModelToJson(ActivityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'type': instance.type,
      'userId': instance.userId,
      'createdByName': instance.createdByName,
      'outletId': instance.outletId,
      'entityId': instance.entityId,
      'entityName': instance.entityName,
      'description': instance.description,
      'details': instance.details,
    };

ActivityDetails _$ActivityDetailsFromJson(Map<String, dynamic> json) =>
    ActivityDetails(
      gst: (json['gst'] as num?)?.toInt(),
      withTax: json['withTax'] as bool?,
      category: json['category'] as String?,
      salePrice: (json['salePrice'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ActivityDetailsToJson(ActivityDetails instance) =>
    <String, dynamic>{
      'gst': instance.gst,
      'withTax': instance.withTax,
      'category': instance.category,
      'salePrice': instance.salePrice,
    };

PaginationModel _$PaginationModelFromJson(Map<String, dynamic> json) =>
    PaginationModel(
      currentPage: (json['currentPage'] as num).toInt(),
      totalPages: (json['totalPages'] as num).toInt(),
      totalItems: (json['totalItems'] as num).toInt(),
      itemsPerPage: (json['itemsPerPage'] as num).toInt(),
    );

Map<String, dynamic> _$PaginationModelToJson(PaginationModel instance) =>
    <String, dynamic>{
      'currentPage': instance.currentPage,
      'totalPages': instance.totalPages,
      'totalItems': instance.totalItems,
      'itemsPerPage': instance.itemsPerPage,
    };
