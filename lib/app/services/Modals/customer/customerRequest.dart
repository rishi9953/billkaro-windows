import 'package:json_annotation/json_annotation.dart';

part 'customerRequest.g.dart';

@JsonSerializable()
class CustomerRequest {
  final String userId;
  final String outletId;
  final String customerName;
  final String phoneNumber;
  final int loyalityDiscount;

  CustomerRequest({
    required this.userId,
    required this.outletId,
    required this.customerName,
    required this.phoneNumber,
    required this.loyalityDiscount,
  });

  factory CustomerRequest.fromJson(Map<String, dynamic> json) =>
      _$CustomerRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerRequestToJson(this);
}
