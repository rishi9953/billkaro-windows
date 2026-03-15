import 'package:json_annotation/json_annotation.dart';
import 'package:billkaro/app/services/Modals/orders/split_payment.dart';

part 'createOrder_request.g.dart';

@JsonSerializable(explicitToJson: true)
class CreateorderRequest {
  final String? billNumber;
  final String? userId;
  final String? outletId;
  final String? tableNumber;
  final String? customerName;
  final String? phoneNumber;
  final double? subtotal;
  final double? totalTax;
  final double? discount;
  final double? serviceCharge;
  final double? totalAmount;
  final String? paymentReceivedIn;
  final List<SplitPayment>? splitPayments;
  final String? status;
  final String? orderFrom;
  final List<OrderItem>? items;

  CreateorderRequest({
    this.billNumber,
    this.userId,
    this.outletId,
    this.tableNumber,
    this.customerName,
    this.phoneNumber,
    this.subtotal,
    this.totalTax,
    this.discount,
    this.serviceCharge,
    this.totalAmount,
    this.paymentReceivedIn,
    this.splitPayments,
    this.status,
    this.items,
    this.orderFrom,
  });

  factory CreateorderRequest.fromJson(Map<String, dynamic> json) =>
      _$CreateorderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreateorderRequestToJson(this);
}

@JsonSerializable()
class OrderItem {
  final String itemId;
  final String itemName;
  final String category;
  final int quantity;
  final double salePrice;
  final double gst;

  OrderItem({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.salePrice,
    required this.gst,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}
