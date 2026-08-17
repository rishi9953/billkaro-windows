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
    String requiredString(String camelKey, [String? snakeKey]) {
      final value =
          json[camelKey] ?? (snakeKey != null ? json[snakeKey] : null);
      return value?.toString() ?? '';
    }

    String? optionalString(String camelKey, [String? snakeKey]) {
      final value =
          json[camelKey] ?? (snakeKey != null ? json[snakeKey] : null);
      if (value == null) return null;
      final text = value.toString();
      return text.isEmpty ? null : text;
    }

    double requiredDouble(String camelKey, [String? snakeKey]) {
      final value =
          json[camelKey] ?? (snakeKey != null ? json[snakeKey] : null);
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    final rawItems = json['items'];
    final items = rawItems is List
        ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(OrderItem.fromJson)
              .toList()
        : <OrderItem>[];

    final rawSplitPayments = json['splitPayments'] ?? json['split_payments'];
    final splitPayments = rawSplitPayments is List
        ? rawSplitPayments
              .whereType<Map<String, dynamic>>()
              .map(SplitPayment.fromJson)
              .toList()
        : null;

    return OrderModel(
      id: requiredString('id'),
      createdAt: requiredString('createdAt', 'created_at'),
      updatedAt: requiredString('updatedAt', 'updated_at'),
      billNumber: requiredString('billNumber', 'bill_number'),
      userId: requiredString('userId', 'user_id'),
      tableNumber: optionalString('tableNumber', 'table_number'),
      outletId: requiredString('outletId', 'outlet_id'),
      customerName: optionalString('customerName', 'customer_name'),
      phoneNumber: optionalString('phoneNumber', 'phone_number'),
      subtotal: requiredDouble('subtotal'),
      totalTax: requiredDouble('totalTax', 'total_tax'),
      discount: requiredDouble('discount'),
      serviceCharge: requiredDouble('serviceCharge', 'service_charge'),
      totalAmount: requiredDouble('totalAmount', 'total_amount'),
      paymentReceivedIn: optionalString(
        'paymentReceivedIn',
        'payment_received_in',
      ),
      splitPayments: splitPayments,
      status: requiredString('status'),
      orderFrom: requiredString('orderFrom', 'order_from'),
      items: items,
      specialInstructions: optionalString(
        'specialInstructions',
        'special_instructions',
      ),
    );
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
  final String? variantId;
  final String? variantName;
  final String? variantSku;

  OrderItem({
    required this.itemId,
    required this.itemName,
    required this.category,
    required this.quantity,
    required this.salePrice,
    required this.gst,
    this.kotSentQuantity = 0,
    this.itemRemark,
    this.variantId,
    this.variantName,
    this.variantSku,
  });

  String get displayName {
    final variant = variantName?.trim();
    if (variant == null || variant.isEmpty) return itemName;
    return '$itemName - $variant';
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    String requiredString(String camelKey, [String? snakeKey]) {
      final value =
          json[camelKey] ?? (snakeKey != null ? json[snakeKey] : null);
      return value?.toString() ?? '';
    }

    double requiredDouble(String camelKey, [String? snakeKey]) {
      final value =
          json[camelKey] ?? (snakeKey != null ? json[snakeKey] : null);
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? '') ?? 0.0;
    }

    int requiredInt(String camelKey, [String? snakeKey]) {
      final value =
          json[camelKey] ?? (snakeKey != null ? json[snakeKey] : null);
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    String? optionalString(String camelKey, [String? snakeKey]) {
      final value =
          json[camelKey] ?? (snakeKey != null ? json[snakeKey] : null);
      if (value == null) return null;
      final text = value.toString();
      return text.isEmpty ? null : text;
    }

    return OrderItem(
      itemId: requiredString('itemId', 'item_id'),
      itemName: requiredString('itemName', 'item_name'),
      category: requiredString('category'),
      quantity: requiredInt('quantity'),
      salePrice: requiredDouble('salePrice', 'sale_price'),
      gst: requiredDouble('gst'),
      kotSentQuantity: requiredInt('kotSentQuantity', 'kot_sent_quantity'),
      itemRemark: optionalString('itemRemark', 'item_remark'),
      variantId: optionalString('variantId', 'variant_id'),
      variantName: optionalString('variantName', 'variant_name'),
      variantSku: optionalString('variantSku', 'variant_sku'),
    );
  }

  Map<String, dynamic> toJson() => _$OrderItemToJson(this);
}
