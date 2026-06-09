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

@JsonSerializable()
class CustomerDetailsResponse {
  final String status;
  final CustomerDetailsData data;

  CustomerDetailsResponse({required this.status, required this.data});

  factory CustomerDetailsResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailsResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailsResponseToJson(this);
}

@JsonSerializable()
class CustomerDetailsData {
  final CustomerData customer;
  final CustomerStats stats;
  final List<CustomerLastOrder> orders;
  final CustomerLastOrder? lastOrder;
  final CustomerOrdersPagination pagination;

  CustomerDetailsData({
    required this.customer,
    required this.stats,
    required this.orders,
    required this.pagination,
    this.lastOrder,
  });

  factory CustomerDetailsData.fromJson(Map<String, dynamic> json) =>
      _$CustomerDetailsDataFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerDetailsDataToJson(this);
}

@JsonSerializable()
class CustomerOrdersPagination {
  final int page;
  final int limit;
  final int totalOrders;
  final int totalPages;

  CustomerOrdersPagination({
    required this.page,
    required this.limit,
    required this.totalOrders,
    required this.totalPages,
  });

  factory CustomerOrdersPagination.fromJson(Map<String, dynamic> json) =>
      _$CustomerOrdersPaginationFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerOrdersPaginationToJson(this);
}

@JsonSerializable()
class CustomerStats {
  final double avgOrder;
  final double totalDiscount;
  final int totalVisits;
  final double orderValue;

  CustomerStats({
    required this.avgOrder,
    required this.totalDiscount,
    required this.totalVisits,
    required this.orderValue,
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) =>
      _$CustomerStatsFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerStatsToJson(this);
}

@JsonSerializable()
class CustomerLastOrder {
  final String id;
  final String billNumber;
  final String orderDate;
  final double totalAmount;
  final String paymentType;
  final String status;
  final double discount;

  CustomerLastOrder({
    required this.id,
    required this.billNumber,
    required this.orderDate,
    required this.totalAmount,
    required this.paymentType,
    this.status = 'pending',
    this.discount = 0,
  });

  factory CustomerLastOrder.fromJson(Map<String, dynamic> json) =>
      _$CustomerLastOrderFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerLastOrderToJson(this);
}

@JsonSerializable()
class CustomerLookupResponse {
  final String status;
  final CustomerData? data;

  CustomerLookupResponse({required this.status, this.data});

  factory CustomerLookupResponse.fromJson(Map<String, dynamic> json) =>
      _$CustomerLookupResponseFromJson(json);

  Map<String, dynamic> toJson() => _$CustomerLookupResponseToJson(this);
}
