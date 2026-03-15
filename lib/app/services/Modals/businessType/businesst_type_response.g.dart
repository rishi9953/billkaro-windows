// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'businesst_type_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BusinesstTypeResponse _$BusinesstTypeResponseFromJson(
  Map<String, dynamic> json,
) => BusinesstTypeResponse(
  status: json['status'] as String,
  data: (json['data'] as List<dynamic>)
      .map((e) => BusinessType.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$BusinesstTypeResponseToJson(
  BusinesstTypeResponse instance,
) => <String, dynamic>{'status': instance.status, 'data': instance.data};

BusinessType _$BusinessTypeFromJson(Map<String, dynamic> json) => BusinessType(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  name: json['name'] as String,
  value: json['value'] as String,
  active: json['active'] as bool,
);

Map<String, dynamic> _$BusinessTypeToJson(BusinessType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'name': instance.name,
      'value': instance.value,
      'active': instance.active,
    };
