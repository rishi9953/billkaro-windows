import 'package:json_annotation/json_annotation.dart';

part 'customerResponse.g.dart';

@JsonSerializable()
class CustomerResponse {
  final String status;
  final List<CustomerData> data;

  CustomerResponse({required this.status, required this.data});

  factory CustomerResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerResponseToJson(this);
}

@JsonSerializable()
class CustomerData {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String userId;
  final String outletId;
  final String customerName;
  final String phoneNumber;
  final int loyalityDiscount;

  CustomerData({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.outletId,
    required this.customerName,
    required this.phoneNumber,
    required this.loyalityDiscount,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) =>
      _$CustomerDataFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDataToJson(this);
}
