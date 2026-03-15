// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoginResponse _$LoginResponseFromJson(Map<String, dynamic> json) =>
    LoginResponse(
      accessToken: json['access_token'] as String,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoginResponseToJson(LoginResponse instance) =>
    <String, dynamic>{
      'access_token': instance.accessToken,
      'user': instance.user,
    };

User _$UserFromJson(Map<String, dynamic> json) => User(
  id: json['id'] as String?,
  brandName: json['brandName'] as String?,
  email: json['email'] as String?,
  address: json['address'] as String?,
  city: json['city'] as String?,
  state: json['state'] as String?,
  zipcode: json['zipcode'] as String?,
  country: json['country'] as String?,
  firstName: json['firstName'] as String?,
  lastName: json['lastName'] as String?,
  title: json['title'] as String?,
  mobile: json['mobile'] as String?,
  isTrial: json['isTrial'] as bool?,
  outletData: (json['outletData'] as List<dynamic>?)
      ?.map((e) => OutletData.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'brandName': instance.brandName,
  'email': instance.email,
  'address': instance.address,
  'city': instance.city,
  'state': instance.state,
  'zipcode': instance.zipcode,
  'country': instance.country,
  'firstName': instance.firstName,
  'lastName': instance.lastName,
  'title': instance.title,
  'mobile': instance.mobile,
  'isTrial': instance.isTrial,
  'outletData': instance.outletData,
};

OutletData _$OutletDataFromJson(Map<String, dynamic> json) =>
    OutletData(
        id: json['id'] as String?,
        businessName: json['businessName'] as String?,
        businessType: json['businessType'] as String?,
        businessCategory: json['businessCategory'] as String?,
        outletAddress: json['outletAddress'] as String?,
        upiId: json['upiId'] as String?,
        taxSlab: json['taxSlab'] as String?,
        googleProfileLink: json['googleProfileLink'] as String?,
        swiggyLink: json['swiggyLink'] as String?,
        zomatoLink: json['zomatoLink'] as String?,
        gstinNumber: json['gstinNumber'] as String?,
        fssaiNumber: json['fssaiNumber'] as String?,
        outletAge: json['outletAge'] as String?,
        logo: json['logo'] as String?,
        createdAt: json['createdAt'] as String?,
        updatedAt: json['updatedAt'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        seatingCapacity: json['seatingCapacity'] as String?,
        billNumber: (json['billNumber'] as num?)?.toInt(),
      )
      ..subscriptions = (json['subscriptions'] as List<dynamic>?)
          ?.map((e) => OutletSubscription.fromJson(e as Map<String, dynamic>))
          .toList();

Map<String, dynamic> _$OutletDataToJson(OutletData instance) =>
    <String, dynamic>{
      'id': instance.id,
      'businessName': instance.businessName,
      'businessType': instance.businessType,
      'businessCategory': instance.businessCategory,
      'outletAddress': instance.outletAddress,
      'upiId': instance.upiId,
      'taxSlab': instance.taxSlab,
      'googleProfileLink': instance.googleProfileLink,
      'swiggyLink': instance.swiggyLink,
      'zomatoLink': instance.zomatoLink,
      'gstinNumber': instance.gstinNumber,
      'fssaiNumber': instance.fssaiNumber,
      'outletAge': instance.outletAge,
      'logo': instance.logo,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'phoneNumber': instance.phoneNumber,
      'seatingCapacity': instance.seatingCapacity,
      'billNumber': instance.billNumber,
      'subscriptions': instance.subscriptions,
    };

OutletSubscription _$OutletSubscriptionFromJson(Map<String, dynamic> json) =>
    OutletSubscription(
      id: json['id'] as String?,
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      paymentId: json['paymentId'] as String?,
      subscription: json['subscription'] == null
          ? null
          : SubscriptionPlan.fromJson(
              json['subscription'] as Map<String, dynamic>,
            ),
    );

Map<String, dynamic> _$OutletSubscriptionToJson(OutletSubscription instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'paymentId': instance.paymentId,
      'subscription': instance.subscription,
    };

SubscriptionPlan _$SubscriptionPlanFromJson(Map<String, dynamic> json) =>
    SubscriptionPlan(
      id: json['id'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      duration: (json['duration'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SubscriptionPlanToJson(SubscriptionPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'price': instance.price,
      'duration': instance.duration,
    };
