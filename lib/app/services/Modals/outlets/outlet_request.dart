import 'package:json_annotation/json_annotation.dart';

part 'outlet_request.g.dart';

@JsonSerializable()
class OutletRequest {
  final String businessName;
  final String businessType;
  final String outletAddress;
  final String outletAge;
  final String seatingCapacity;

  OutletRequest({
    required this.businessName,
    required this.businessType,
    required this.outletAddress,
    required this.outletAge,
    required this.seatingCapacity,
  });

  factory OutletRequest.fromJson(Map<String, dynamic> json) => _$OutletRequestFromJson(json);
  Map<String, dynamic> toJson() => _$OutletRequestToJson(this);
}
