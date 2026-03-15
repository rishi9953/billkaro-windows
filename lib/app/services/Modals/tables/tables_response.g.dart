// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tables_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TablesResponse _$TablesResponseFromJson(Map<String, dynamic> json) =>
    TablesResponse(
      status: json['status'] as String,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => TableData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$TablesResponseToJson(TablesResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'message': instance.message,
      'data': instance.data,
    };

TableData _$TableDataFromJson(Map<String, dynamic> json) => TableData(
  id: json['id'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  outletId: json['outletId'] as String,
  tableNumber: json['tableNumber'] as String,
  status: json['status'] as String,
  currentBillNumber: json['currentBillNumber'] as String?,
);

Map<String, dynamic> _$TableDataToJson(TableData instance) => <String, dynamic>{
  'id': instance.id,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'outletId': instance.outletId,
  'tableNumber': instance.tableNumber,
  'status': instance.status,
  'currentBillNumber': instance.currentBillNumber,
};
