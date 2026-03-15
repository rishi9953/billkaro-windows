// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'registration_modal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegistrationModel _$RegistrationModelFromJson(Map<String, dynamic> json) =>
    RegistrationModel(
      businessName: json['businessName'] as String,
      brandName: json['brandName'] as String,
      email: json['email'] as String,
      password: json['password'] as String,
      businessType: json['businessType'] as String,
      address: json['address'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      zipcode: json['zipcode'] as String,
      country: json['country'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      title: json['title'] as String,
      mobile: json['mobile'] as String,
    );

Map<String, dynamic> _$RegistrationModelToJson(RegistrationModel instance) =>
    <String, dynamic>{
      'businessName': instance.businessName,
      'brandName': instance.brandName,
      'email': instance.email,
      'password': instance.password,
      'businessType': instance.businessType,
      'address': instance.address,
      'city': instance.city,
      'state': instance.state,
      'zipcode': instance.zipcode,
      'country': instance.country,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'title': instance.title,
      'mobile': instance.mobile,
    };
