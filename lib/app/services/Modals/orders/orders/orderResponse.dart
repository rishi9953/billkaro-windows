import 'package:json_annotation/json_annotation.dart';
import 'package:billkaro/app/services/Modals/orders/split_payment.dart';

part 'orderResponse.g.dart';

@JsonSerializable()
class OrderResponse {
  final String status;
  final String message;
  final List<OrderModel> data;

  OrderResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) =>
      _$OrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$OrderResponseToJson(this);
}

@JsonSerializable()
class OrderModel {
  final String id;
  final String createdAt;
  final String updatedAt;
  final String billNumber;
  final String userId;
  final String? tableNumber;
  final String outletId;
  final String? customerName;
  final String? phoneNumber;
  final double subtotal;
  final double totalTax;
  final double discount;
  final double serviceCharge;
  final double totalAmount;
  final String? paymentReceivedIn;
  final List<SplitPayment>? splitPayments;
  final String status;
  @JsonKey(defaultValue: '')
  final String orderFrom;
  final List<OrderItem> items;
  final String? specialInstructions;

  OrderModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.billNumber,
    required this.userId,
    this.tableNumber,
    this.customerName,
    this.phoneNumber,
    required this.outletId,
    required this.subtotal,
    required this.totalTax,
    required this.discount,
    required this.serviceCharge,
    required this.totalAmount,
    this.paymentReceivedIn,
    this.splitPayments,
    required this.status,
    required this.items,
    required this.orderFrom,
    this.specialInstructions,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case from API
    final normalized = Map<String, dynamic>.from(json);
    if (normalized['paymentReceivedIn'] == null &&
        normalized['payment_received_in'] != null) {
      normalized['paymentReceivedIn'] = normalized['payment_received_in'];
    }
    if (normalized['orderFrom'] == null &&
        normalized['order_from'] != null) {
      normalized['orderFrom'] = normalized['order_from'];
    }
    return _$OrderModelFromJson(normalized);
  }

  Map<String, dynamic> toJson() => _$OrderModelToJson(this);
}

@JsonSerializable()
class OrderItem {
  final String itemId;
  final String itemName;
  final String category;
  final int quantity;
  final double salePrice;
  final double gst;
  @JsonKey(defaultValue: 0)
  final int kotSentQuantity;
  final String? itemRemark;

  OrderItem({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.salePrice,
    required this.gst,
    this.kotSentQuantity = 0,
    this.itemRemark,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) =>
      _$OrderItemFromJson(json);

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}
