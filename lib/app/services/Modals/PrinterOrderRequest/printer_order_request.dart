import 'package:json_annotation/json_annotation.dart';

part 'printer_order_request.g.dart';

@JsonSerializable()
class PrinterOrderRequest {
  final String userId;
  final String outletId;
  final String subscriptionId;
  final String outletName;
  final String outletAddress;
  final String email;
  final String phoneNumber;
  final String deliveryAddress;
  final String pincode;
  final String status;

  PrinterOrderRequest({
    required this.userId,
    required this.outletId,
    required this.subscriptionId,
    required this.outletName,
    required this.outletAddress,
    required this.email,
    required this.phoneNumber,
    required this.deliveryAddress,
    required this.pincode,
    required this.status,
  });

  factory PrinterOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$PrinterOrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PrinterOrderRequestToJson(this);
}
