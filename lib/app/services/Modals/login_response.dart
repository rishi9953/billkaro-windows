import 'package:json_annotation/json_annotation.dart';
part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  @JsonKey(name: 'access_token')
  final String accessToken;
  final User user;

  LoginResponse({required this.accessToken, required this.user});

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}

@JsonSerializable()
class User {
  final String? id;
  final String? brandName;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? zipcode;
  final String? country;
  final String? firstName;
  final String? lastName;
  final String? title;
  final String? mobile;
  final bool? isTrial;
  final List<OutletData>? outletData;

  User({
    this.id,
    this.brandName,
    this.email,
    this.address,
    this.city,
    this.state,
    this.zipcode,
    this.country,
    this.firstName,
    this.lastName,
    this.title,
    this.mobile,
    this.isTrial,
    this.outletData,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable()
class OutletData {
  final String? id;
  final String? businessName;
  final String? businessType;
  final String? businessCategory;
  final String? outletAddress;
  final String? upiId;
  final String? taxSlab;
  final String? googleProfileLink;
  final String? swiggyLink;
  final String? zomatoLink;
  final String? gstinNumber;
  final String? fssaiNumber;
  final String? outletAge;
  final String? logo;
  final String? createdAt;
  final String? updatedAt;
  final String? phoneNumber;
  final String? seatingCapacity;
  final int? billNumber;
   List<OutletSubscription>? subscriptions;

  OutletData({
    this.id,
    this.businessName,
    this.businessType,
    this.businessCategory,
    this.outletAddress,
    this.upiId,
    this.taxSlab,
    this.googleProfileLink,
    this.swiggyLink,
    this.zomatoLink,
    this.gstinNumber,
    this.fssaiNumber,
    this.outletAge,
    this.logo,
    this.createdAt,
    this.updatedAt,
    this.phoneNumber,
    this.seatingCapacity,
    this.billNumber,
  });

  factory OutletData.fromJson(Map<String, dynamic> json) =>
      _$OutletDataFromJson(json);

  Map<String, dynamic> toJson() => _$OutletDataToJson(this);
}

@JsonSerializable()
class OutletSubscription {
  final String? id;
  final String? startDate;
  final String? endDate;
  final String? paymentId;
  final SubscriptionPlan? subscription;

  OutletSubscription({
    this.id,
    this.startDate,
    this.endDate,
    this.paymentId,
    this.subscription,
  });

  factory OutletSubscription.fromJson(Map<String, dynamic> json) =>
      _$OutletSubscriptionFromJson(json);

  Map<String, dynamic> toJson() => _$OutletSubscriptionToJson(this);
}

@JsonSerializable()
class SubscriptionPlan {
  final String? id;
  final double? price;
  final int? duration;

  SubscriptionPlan({this.id, this.price, this.duration});

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionPlanFromJson(json);

  Map<String, dynamic> toJson() => _$SubscriptionPlanToJson(this);
}
