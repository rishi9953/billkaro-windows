// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outlet_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OutletRequest _$OutletRequestFromJson(Map<String, dynamic> json) =>
    OutletRequest(
      businessName: json['businessName'] as String,
      businessType: json['businessType'] as String,
      outletAddress: json['outletAddress'] as String,
      outletAge: json['outletAge'] as String,
      seatingCapacity: json['seatingCapacity'] as String,
    );

Map<String, dynamic> _$OutletRequestToJson(OutletRequest instance) =>
    <String, dynamic>{
      'businessName': instance.businessName,
      'businessType': instance.businessType,
      'outletAddress': instance.outletAddress,
      'outletAge': instance.outletAge,
      'seatingCapacity': instance.seatingCapacity,
    };
